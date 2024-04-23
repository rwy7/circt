//===- AssignOutputDirs.cpp - Assign Output Directories ---------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "PassDetails.h"
#include "circt/Dialect/FIRRTL/AnnotationDetails.h"
#include "circt/Dialect/FIRRTL/FIRRTLAnnotations.h"
#include "circt/Dialect/FIRRTL/FIRRTLInstanceGraph.h"
#include "circt/Dialect/FIRRTL/Passes.h"
#include "circt/Dialect/HW/HWAttributes.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/Support/Path.h"

#define DEBUG_TYPE "firrtl-assign-output-dirs"

using namespace circt;
using namespace firrtl;

//===----------------------------------------------------------------------===//
// Directory Utilities
//===----------------------------------------------------------------------===//

static SmallString<128> canonicalize(const Twine &directory) {
  SmallString<128> native;
  llvm::sys::path::native(directory, native);
  auto separator = llvm::sys::path::get_separator();
  if (!native.ends_with(separator))
    native += separator;
  return native;
}

static StringAttr canonicalize(const StringAttr directory) {
  if (!directory)
    return nullptr;
  return StringAttr::get(directory.getContext(),
                         canonicalize(Twine(directory.getValue())));
}

//===----------------------------------------------------------------------===//
// Output Directory Priority Table
//===----------------------------------------------------------------------===//

namespace {
struct OutputDirInfo {
  OutputDirInfo(unsigned depth, StringAttr parent)
      : depth(depth), parent(parent) {}
  unsigned depth = 1;
  StringAttr parent = nullptr;
};

/// A table that helps decide which directory a floating module must be placed.
/// Given two candidate output directories, the table can answer the question,
/// which directory should a resource go.
///
/// Output directories are organized into a tree, which represents the relative
/// "specificity" of a directory. If a resource could be placed in more than one
/// directory, then it is output in the least-common-ancestor of the
/// candidate output directories, which represents the "most specific" place
/// a resource could go, which is still general enough to cover all uses.
class OutputDirTable {
public:
  explicit OutputDirTable(CircuitOp);

  /// Given two directory names, returns the least-common-ancestor directory.
  /// If the LCA is the toplevel output directory (which is considered the most
  /// general), return null.
  StringAttr join(StringAttr, StringAttr);

private:
  OutputDirInfo get(StringAttr);

  DenseMap<StringAttr, OutputDirInfo> info;
};
} // namespace

OutputDirTable::OutputDirTable(CircuitOp circuit) {
  // Stage 1: Build a table mapping child directories to their parents.
  auto *context = circuit.getContext();

  // The priority table is pre-seeded with well-known output directories.
  auto sifiveViews = StringAttr::get(context, "sifive_views/");
  auto testBench = StringAttr::get(context, "testbench/");
  DenseMap<StringAttr, StringAttr> parentTable;
  parentTable[testBench] = sifiveViews;

  // Pull additional precedence information from the circuit's annotations.
  AnnotationSet annos(circuit);
  for (auto anno : annos) {
    if (anno.isClass(declareOutputDirAnnoClass)) {
      auto name = canonicalize(anno.getMember<StringAttr>("name"));
      auto parent = canonicalize(anno.getMember<StringAttr>("parent"));
      if (name)
        parentTable[name] = parent;
    }
  }

  // Stage 2: Process the parentTable into a precedence graph.
  info.insert({nullptr, {0, nullptr}});
  SmallVector<std::pair<StringAttr, StringAttr>> stack;
  for (auto [current, parent] : parentTable) {
    auto it = info.find(current);
    if (it != info.end())
      continue;
    while (true) {
      auto it = info.find(parent);
      if (it == info.end()) {
        stack.push_back({current, parent});
        current = parent;
        parent = parentTable.lookup(current);
        continue;
      }
      info.insert({current, {it->second.depth + 1, parent}});
      if (stack.empty())
        break;
      std::tie(current, parent) = stack.back();
      stack.pop_back();
    }
  }
}

OutputDirInfo OutputDirTable::get(StringAttr dir) {
  return info.insert({dir, {1, nullptr}}).first->second;
}

StringAttr OutputDirTable::join(StringAttr a, StringAttr b) {
  if (!a || !b)
    return nullptr;
  if (a == b)
    return a;
  auto ainfo = get(a);
  auto binfo = get(b);
  while (ainfo.depth < binfo.depth) {
    a = ainfo.parent;
    ainfo = get(a);
  }
  while (binfo.depth < ainfo.depth) {
    b = binfo.parent;
    binfo = get(b);
  }
  while (a != b) {
    a = ainfo.parent;
    b = binfo.parent;
    ainfo = get(a);
    binfo = get(b);
  }
  assert(a == b);
  return a;
}

//===----------------------------------------------------------------------===//
// Pass Infrastructure
//===----------------------------------------------------------------------===//

namespace {
class AssignOutputDirsPass : public AssignOutputDirsBase<AssignOutputDirsPass> {
  void runOnOperation() override;
};
} // namespace

static StringAttr getOutputDir(Operation *op) {
  auto outputFile = op->getAttrOfType<hw::OutputFileAttr>("output_file");
  if (!outputFile)
    return nullptr;
  return outputFile.getDirectoryAttr();
}

void AssignOutputDirsPass::runOnOperation() {
  auto falseAttr = BoolAttr::get(&getContext(), false);
  auto circuit = getOperation();
  OutputDirTable outDirTable(circuit);
  DenseSet<InstanceGraphNode *> visited;
  for (auto *root : getAnalysis<InstanceGraph>()) {
    for (auto *node : llvm::inverse_post_order_ext(root, visited)) {
      auto module = dyn_cast<FModuleOp>(node->getModule());
      if (!module || module->getAttrOfType<hw::OutputFileAttr>("output_file") ||
          module.isPublic())
        continue;
      StringAttr outputDir;
      auto i = node->usesBegin();
      auto e = node->usesEnd();
      for (; i != e; ++i) {
        if (auto parent = dyn_cast<FModuleOp>((*i)->getParent()->getModule())) {
          outputDir = getOutputDir(parent);
          ++i;
          break;
        }
      }
      for (; i != e; ++i) {
        if (auto parent =
                dyn_cast<FModuleOp>((*i)->getParent()->getModule<FModuleOp>()))
          outputDir = outDirTable.join(outputDir, getOutputDir(parent));
      }
      if (outputDir)
        module->setAttr("output_file", hw::OutputFileAttr::get(
                                           outputDir, falseAttr, falseAttr));
    }
  }
  markAllAnalysesPreserved();
}

std::unique_ptr<mlir::Pass> circt::firrtl::createAssignOutputDirsPass() {
  return std::make_unique<AssignOutputDirsPass>();
}
