//===- FIRRTLInstanceInfo.h - Instance info analysis ------------*- C++ -*-===//
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

#ifndef CIRCT_DIALECT_FIRRTL_FIRRTLINSTANCEINFO_H
#define CIRCT_DIALECT_FIRRTL_FIRRTLINSTANCEINFO_H

#include "circt/Dialect/FIRRTL/FIRRTLOps.h"
#include "circt/Support/LLVM.h"
#include "mlir/Pass/AnalysisManager.h"

namespace circt {
namespace firrtl {

class InstanceInfo {

public:
  explicit InstanceInfo(Operation *op, mlir::AnalysisManager &am);

  /// Information about a circuit
  struct CircuitAttributes {
    /// The design-under-test if one is defined.
    igraph::ModuleOpInterface dut = nullptr;

    /// The design-under-test if one is defined or the top module.
    igraph::ModuleOpInterface effectiveDut = nullptr;
  };

  /// Information about a module.
  struct ModuleAttributes {
    constexpr ModuleAttributes()
        : anyInstancesUnderDut(false), allInstancesUnderDut(true),
          anyInstancesUnderEffectiveDut(false),
          allInstancesUnderEffectiveDut(true), anyInstancesUnderLayer(false),
          allInstancesUnderLayer(true), anyInstancesInDesign(false),
          allInstancesInDesign(true), anyInstancesInEffectiveDesign(false),
          allInstancesInEffectiveDesign(true) {}

    constexpr void mergeInParentAttrs(const ModuleAttributes &parent) {
      anyInstancesUnderDut |= parent.anyInstancesUnderDut;
      allInstancesUnderDut &= parent.allInstancesUnderDut;
      anyInstancesUnderEffectiveDut |= parent.anyInstancesUnderEffectiveDut;
      allInstancesUnderEffectiveDut &= parent.allInstancesUnderEffectiveDut;
      anyInstancesUnderLayer |= parent.anyInstancesUnderLayer;
      allInstancesUnderLayer &= parent.allInstancesUnderLayer;
      anyInstancesInDesign |= parent.anyInstancesInDesign;
      allInstancesInDesign &= parent.allInstancesInDesign;
      anyInstancesInEffectiveDesign |= parent.anyInstancesInEffectiveDesign;
      allInstancesInEffectiveDesign &= parent.allInstancesInEffectiveDesign;
    }

    /// Indicates if this module is instantiated under the design-under-test.
    bool anyInstancesUnderDut : 1;
    bool allInstancesUnderDut : 1;

    /// Indicates if this module is instantiated under the effective
    /// design-under-test.
    bool anyInstancesUnderEffectiveDut : 1;
    bool allInstancesUnderEffectiveDut : 1;

    /// Indicates if this module is instantiated under a layer.
    bool anyInstancesUnderLayer : 1;
    bool allInstancesUnderLayer : 1;

    /// Indicates if this module is instantiated in the design.  The "design" is
    /// defined as being under the design-under-test, excluding verification
    /// code (e.g., layers).
    bool anyInstancesInDesign : 1;
    bool allInstancesInDesign : 1;

    /// Indicates if this modules is instantiated in the effective design.  The
    /// "effective design" is defined as the design-under-test (DUT), excluding
    /// verification code (e.g., layers).  If a DUT is specified, then this is
    /// the same as `inDesign`.  However, if there is no DUT, then every module
    /// is deemed to be in the design except those which are explicitly
    /// verification code.
    bool anyInstancesInEffectiveDesign : 1;
    bool allInstancesInEffectiveDesign : 1;
  };

  //===--------------------------------------------------------------------===//
  // Circuit Attribute Queries
  //===--------------------------------------------------------------------===//

  /// Return true if this circuit has a design-under-test.
  bool hasDut();

  /// Return the design-under-test if one is defined for the circuit, otherwise
  /// return null.
  igraph::ModuleOpInterface getDut();

  /// Return the "effective" design-under-test.  This will be the
  /// design-under-test if one is defined.  Otherwise, this will be the root
  /// node of the instance graph.
  igraph::ModuleOpInterface getEffectiveDut();

  //===--------------------------------------------------------------------===//
  // Module Attribute Queries
  //===--------------------------------------------------------------------===//

  /// Return true if this module is the design-under-test.
  bool isDut(igraph::ModuleOpInterface op);

  /// Return true if this module is the design-under-test and the circuit has a
  /// design-under-test.  If the circuit has no design-under-test, then return
  /// true if this is the top module.
  bool isEffectiveDut(igraph::ModuleOpInterface op);

  /// Return true if at least one instance of this module is under (or
  /// transitively under) the design-under-test.  This is true if the module is
  /// the design-under-test.
  bool anyInstancesUnderDut(igraph::ModuleOpInterface op);

  /// Return true if all instances of this module are under (or transitively
  /// under) the design-under-test.  This is true if the module is the
  /// design-under-test.
  bool allInstancesUnderDut(igraph::ModuleOpInterface op);

  /// Return true if at least one instance is under (or transitively under) the
  /// effective design-under-test.  This is true if the module is the effective
  /// design-under-test.
  bool anyInstancesUnderEffectiveDut(igraph::ModuleOpInterface op);

  /// Return true if all instances are under (or transitively under) the
  /// effective design-under-test.  This is true if the module is the effective
  /// design-under-test.
  bool allInstancesUnderEffectiveDut(igraph::ModuleOpInterface op);

  /// Return true if at least one instance of this module is under (or
  /// transitively under) a layer.
  bool anyInstancesUnderLayer(igraph::ModuleOpInterface op);

  /// Return true if all instances of this module are under (or transitively
  /// under) layer blocks.
  bool allInstancesUnderLayer(igraph::ModuleOpInterface op);

  /// Return true if any instance of this module is within (or transitively
  /// within) the design.
  bool anyInstancesInDesign(igraph::ModuleOpInterface op);

  /// Return true if all instances of this module are within (or transitively
  /// withiin) the design.
  bool allInstancesInDesign(igraph::ModuleOpInterface op);

  /// Return true if any instance of this module is within (or transitively
  /// within) the effective design
  bool anyInstancesInEffectiveDesign(igraph::ModuleOpInterface op);

  /// Return true if all instances of this module are within (or transitively
  /// withiin) the effective design.
  bool allInstancesInEffectiveDesign(igraph::ModuleOpInterface op);

private:
  /// Stores circuit-level attributes.
  CircuitAttributes circuitAttributes = {/*dut=*/nullptr,
                                         /*effectiveDut=*/nullptr};

  /// Internal mapping of operations to module attributes.
  DenseMap<Operation *, ModuleAttributes> moduleAttributes;

  /// Return the module attributes associated with a module.
  const ModuleAttributes &getModuleAttributes(igraph::ModuleOpInterface op);
};

} // namespace firrtl
} // namespace circt

#endif // CIRCT_DIALECT_FIRRTL_FIRRTLINSTANCEINFO_H
