//===- FIRRTLInstanceInfo.cpp - Instance info analysis ----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the InstanceInfo analysis.  This is an analysis that
// depends on the InstanceGraph analysis, but provides additional information
// about FIRRTL operations.  This is useful if you find yourself needing to
// selectively iterate over parts of the design.
//
//===----------------------------------------------------------------------===//

#include "circt/Analysis/FIRRTLInstanceInfo.h"
#include "circt/Dialect/FIRRTL/AnnotationDetails.h"
#include "circt/Dialect/FIRRTL/FIRRTLInstanceGraph.h"
#include "circt/Support/Debug.h"
#include "circt/Support/InstanceGraph.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/Support/Debug.h"

#ifndef NDEBUG
#include "llvm/ADT/DepthFirstIterator.h"
#endif

#define DEBUG_TYPE "firrtl-analysis-instanceinfo"

using namespace circt;
using namespace firrtl;

InstanceInfo::InstanceInfo(Operation *op, mlir::AnalysisManager &am) {
  auto &iGraph = am.getAnalysis<InstanceGraph>();

  // First: Find DUT. If we have a DUT, then the effective design is the DUT,
  // and everything beneath the DUT. Otherwise, the effective design is every
  // module that is not under the test bench.
  circuitAttributes.effectiveDut = iGraph.getTopLevelNode()->getModule();
  for (auto *node : iGraph) {
    auto moduleOp = node->getModule();
    AnnotationSet annotations(moduleOp);
    if (annotations.hasAnnotation(dutAnnoClass)) {
      circuitAttributes.dut = moduleOp;
      circuitAttributes.effectiveDut = moduleOp;
    }
  }

  // Visit modules in reverse post-order (visit parents before children) to
  // merge parent attributes and per-instance attributes into children.
  DenseSet<InstanceGraphNode *> visited;
  for (auto *root : iGraph) {
    for (auto *modIt : llvm::inverse_post_order_ext(root, visited)) {
      visited.insert(modIt);
      auto moduleOp = modIt->getModule();
      ModuleAttributes &attributes = moduleAttributes[moduleOp];

      AnnotationSet annotations(moduleOp);
      auto isGCCompanion = annotations.hasAnnotation(companionAnnoClass);

      for (auto *useIt : modIt->uses()) {
        auto parentOp = useIt->getParent()->getModule();
        auto parentAttrs = moduleAttributes.find(parentOp)->getSecond();

        attributes.mergeInParentAttrs(parentAttrs);

        bool underLayer = false;
        if (auto instanceOp = useIt->getInstance<InstanceOp>()) {
          if (instanceOp.getLowerToBind() || instanceOp.getDoNotPrint() ||
              instanceOp->getParentOfType<LayerBlockOp>() || isGCCompanion)
            underLayer = true;
        }
        attributes.anyInstancesUnderLayer |= underLayer;
        attributes.allInstancesInDesign &= !underLayer;
        attributes.allInstancesInEffectiveDesign &= !underLayer;
      }

      if (moduleOp == circuitAttributes.dut) {
        attributes.allInstancesUnderDut = true;
        attributes.anyInstancesUnderDut = true;
        attributes.allInstancesInDesign = true;
        attributes.allInstancesInDesign = true;
      }

      if (moduleOp == circuitAttributes.effectiveDut) {
        attributes.allInstancesUnderEffectiveDut = true;
        attributes.anyInstancesUnderEffectiveDut = true;
        attributes.allInstancesInEffectiveDesign = true;
        attributes.anyInstancesInEffectiveDesign = true;
      }
    }
  }

  // LLVM_DEBUG({
  //   mlir::OpPrintingFlags flags;
  //   flags.skipRegions();
  //   debugHeader("FIRRTL InstanceInfo Analysis")
  //       << "\n"
  //       << llvm::indent(2) << "circuit attributes:\n"
  //       << llvm::indent(4) << "hasDut: " << (hasDut() ? "true" : "false")
  //       << "\n"
  //       << llvm::indent(4) << "dut: ";
  //   if (auto dut = circuitAttributes.dut)
  //     dut->print(llvm::dbgs(), flags);
  //   else
  //     llvm::dbgs() << "null";
  //   llvm::dbgs() << "\n" << llvm::indent(4) << "effectiveDut: ";
  //   circuitAttributes.effectiveDut->print(llvm::dbgs(), flags);
  //   llvm::dbgs() << "\n" << llvm::indent(2) << "module attributes:\n";
  //   visited.clear();
  //   for (auto *root : iGraph) {
  //     for (auto *modIt : llvm::inverse_post_order_ext(root, visited)) {
  //       visited.insert(modIt);
  //       auto moduleOp = modIt->getModule();
  //       auto attributes = moduleAttributes[moduleOp];
  //       llvm::dbgs().indent(4)
  //           << "- module: " << moduleOp.getModuleName() << "\n"
  //           << llvm::indent(6)
  //           << "isDut: " << (isDut(moduleOp) ? "true" : "false") << "\n"
  //           << llvm::indent(6) << "isEffectiveDue: "
  //           << (isEffectiveDut(moduleOp) ? "true" : "false") << "\n"
  //           << llvm::indent(6) << "underDut: " << attributes.underDut << "\n"
  //           << llvm::indent(6) << "underLayer: " << attributes.underLayer
  //           << "\n"
  //           << llvm::indent(6) << "inDesign: " << attributes.inDesign << "\n"
  //           << llvm::indent(6)
  //           << "inEffectiveDesign: " << attributes.inEffectiveDesign << "\n";
  //     }
  //   }
  // });
}

const InstanceInfo::ModuleAttributes &
InstanceInfo::getModuleAttributes(igraph::ModuleOpInterface op) {
  return moduleAttributes.find(op)->getSecond();
}

bool InstanceInfo::hasDut() { return circuitAttributes.dut; }

bool InstanceInfo::isDut(igraph::ModuleOpInterface op) {
  return op == circuitAttributes.dut;
}

bool InstanceInfo::isEffectiveDut(igraph::ModuleOpInterface op) {
  return op == circuitAttributes.effectiveDut;
}

igraph::ModuleOpInterface InstanceInfo::getDut() {
  return circuitAttributes.dut;
}

igraph::ModuleOpInterface InstanceInfo::getEffectiveDut() {
  return circuitAttributes.effectiveDut;
}

bool InstanceInfo::anyInstancesUnderDut(igraph::ModuleOpInterface op) {
  return getModuleAttributes(op).anyInstancesUnderDut;
}

bool InstanceInfo::allInstancesUnderDut(igraph::ModuleOpInterface op) {
  return getModuleAttributes(op).allInstancesUnderDut;
}

bool InstanceInfo::anyInstancesUnderEffectiveDut(igraph::ModuleOpInterface op) {
  return getModuleAttributes(op).anyInstancesUnderEffectiveDut;
}

bool InstanceInfo::allInstancesUnderEffectiveDut(igraph::ModuleOpInterface op) {
  return getModuleAttributes(op).allInstancesUnderEffectiveDut;
}

bool InstanceInfo::anyInstancesUnderLayer(igraph::ModuleOpInterface op) {
  return getModuleAttributes(op).anyInstancesUnderLayer;
}

bool InstanceInfo::allInstancesUnderLayer(igraph::ModuleOpInterface op) {
  return getModuleAttributes(op).allInstancesUnderLayer;
}

bool InstanceInfo::anyInstancesInDesign(igraph::ModuleOpInterface op) {
  return getModuleAttributes(op).anyInstancesInDesign;
}

bool InstanceInfo::allInstancesInDesign(igraph::ModuleOpInterface op) {
  return getModuleAttributes(op).allInstancesInDesign;
}

bool InstanceInfo::anyInstancesInEffectiveDesign(igraph::ModuleOpInterface op) {
  return getModuleAttributes(op).anyInstancesInEffectiveDesign;
}

bool InstanceInfo::allInstancesInEffectiveDesign(igraph::ModuleOpInterface op) {
  return getModuleAttributes(op).allInstancesInEffectiveDesign;
}
