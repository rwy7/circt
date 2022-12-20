//===- FIRRTLAttributes.td - FIRRTL Types Definition -------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Definitions of FIRRTL attributes.
//
//===----------------------------------------------------------------------===//

#ifndef CIRCT_DIALECT_FIRRTL_FIRRTLATTRIBUTES_TD
#define CIRCT_DIALECT_FIRRTL_FIRRTLATTRIBUTES_TD

include "FIRRTLDialect.td"
include "mlir/IR/BuiltinAttributeInterfaces.td"
include "mlir/IR/EnumAttr.td"

//===----------------------------------------------------------------------===//
// FIRRTL Annotations Definition
//===----------------------------------------------------------------------===//

def AnnotationArrayAttr
  : TypedArrayAttrBase<DictionaryAttr, "Annotation array attribute">;

def PortAnnotationsAttr : ArrayAttrBase<
    And<[
      // Guarantee this is an ArrayAttr first
      CPred<"$_self.isa<::mlir::ArrayAttr>()">,
      // Guarantee all elements are an array or a dictionary.
      CPred<"::llvm::all_of($_self.cast<::mlir::ArrayAttr>(), "
            "[&](::mlir::Attribute attr) { return attr.isa<"
            "::mlir::ArrayAttr,"
            "::mlir::DictionaryAttr>();})">]>,
    "Port annotations attribute"> {
  let constBuilderCall = "$_builder.getArrayAttr($0)";
}

//===----------------------------------------------------------------------===//
// Grand Central-related Annotations
//===----------------------------------------------------------------------===//

class AugmentedType<string name> : AttrDef<FIRRTLDialect, name> {
  let description = "Used in the GrandCentralPass.";
  let parameters = (
    ins "DictionaryAttr":$underlying
  );

  code defaultClassDeclaration = [{
    StringAttr getClass() { return getUnderlying().getAs<StringAttr>("class"); }
  }];

  code hasName = [{
    StringAttr getName() { return getUnderlying().getAs<StringAttr>("name"); }
  }];

  code hasDefName = [{
    StringAttr getDefName() { return getUnderlying().getAs<StringAttr>("defName"); }
  }];

  code hasID = [{
    IntegerAttr getID() { return getUnderlying().getAs<IntegerAttr>("id"); }
  }];

  code hasElements = [{
    ArrayAttr getElements() { return getUnderlying().getAs<ArrayAttr>("elements"); }
  }];

  code hasPrefix = [{
    StringAttr getPrefix() { return getUnderlying().getAs<StringAttr>("prefix"); }
  }];

}

def AugmentedBundleType : AugmentedType<"AugmentedBundleType"> {
  let summary = "GrandCentral AugmentedBundleType";
  let extraClassDeclaration =
    defaultClassDeclaration #
    hasID #
    hasElements #
    hasDefName #
    hasPrefix # [{
      bool isRoot() { return getID() != nullptr; }
    }];
}

def AugmentedVectorType : AugmentedType<"AugmentedVectorType"> {
  let summary = "GrandCentral AugmentedVectorType";
  let extraClassDeclaration = defaultClassDeclaration # hasElements;
}

def AugmentedGroundType : AugmentedType<"AugmentedGroundType"> {
  let summary = "GrandCentral AugmentedGroundType";
  let extraClassDeclaration = hasID # hasName;
}

def AugmentedStringType : AugmentedType<"AugmentedStringType"> {
  let summary = "GrandCentral AugmentedStringType";
  let extraClassDeclaration = hasName;
}
def AugmentedBooleanType : AugmentedType<"AugmentedBooleanType"> {
  let summary = "GrandCentral AugmentedBooleanType";
  let extraClassDeclaration = hasName;
}
def AugmentedIntegerType : AugmentedType<"AugmentedIntegerType"> {
  let summary = "GrandCentral AugmentedIntegerType";
  let extraClassDeclaration = hasName;
}
def AugmentedDoubleType : AugmentedType<"AugmentedDoubleType"> {
  let summary = "GrandCentral AugmentedDoubleType";
  let extraClassDeclaration = hasName;
}
def AugmentedLiteralType : AugmentedType<"AugmentedLiteralType"> {
  let summary = "GrandCentral AugmentedLiteralType";
  let extraClassDeclaration = hasName;
}
def AugmentedDeletedType : AugmentedType<"AugmentedDeletedType"> {
  let summary = "GrandCentral AugmentedDeletedType";
  let extraClassDeclaration = hasName;
}

//===----------------------------------------------------------------------===//
// Name Kinds
//===----------------------------------------------------------------------===//

/// An attribute describing a kind of a name which defines name preservation
/// semantics. We preserve names tagged with `InterestingName`.
def DroppableName: I32EnumAttrCase<"DroppableName", 0, "droppable_name">;
def InterestingName: I32EnumAttrCase<"InterestingName", 1, "interesting_name">;

def NameKindEnumImpl: I32EnumAttr<"NameKindEnum", "name kind",
              [DroppableName, InterestingName]> {
  let genSpecializedAttr = 0;
  let cppNamespace = "::circt::firrtl";
}

def NameKindAttr: EnumAttr<FIRRTLDialect, NameKindEnumImpl, "name_kind">;

//===----------------------------------------------------------------------===//
// Read Under Write Behaviour
//===----------------------------------------------------------------------===//

def RUW_Undefined: I32EnumAttrCase<"Undefined", 0>;
def RUW_Old: I32EnumAttrCase<"Old", 1>;
def RUW_New: I32EnumAttrCase<"New", 2>;

def RUWAttr: I32EnumAttr<"RUWAttr", "Read Under Write Enum",
                         [RUW_Undefined, RUW_Old, RUW_New]>;

//===----------------------------------------------------------------------===//
// Memory Port Direction
//===----------------------------------------------------------------------===//

def MemDir_Infer    : I32EnumAttrCase<"Infer", 0>;
def MemDir_Read     : I32EnumAttrCase<"Read", 1>;
def MemDir_Write    : I32EnumAttrCase<"Write", 2>;
def MemDir_ReadWrite: I32EnumAttrCase<"ReadWrite", 3>;

def MemDirAttr: I32EnumAttr<"MemDirAttr", "Memory Direction Enum",
                            [MemDir_Infer, MemDir_Read, MemDir_Write,
                              MemDir_ReadWrite]>;

//===----------------------------------------------------------------------===//
// Event Control
//===----------------------------------------------------------------------===//

/// AtPosEdge triggers on a rise from 0 to 1/X/Z, or X/Z to 1.
def AtPosEdge: I32EnumAttrCase<"AtPosEdge", 0, "posedge">;
/// AtNegEdge triggers on a drop from 1 to 0/X/Z, or X/Z to 0.
def AtNegEdge: I32EnumAttrCase<"AtNegEdge", 1, "negedge">;
/// AtEdge(v) is syntactic sugar for "AtPosEdge(v) or AtNegEdge(v)".
def AtEdge   : I32EnumAttrCase<"AtEdge", 2, "edge">;

def EventControlAttr : I32EnumAttr<"EventControl", "edge control trigger",
                                   [AtPosEdge, AtNegEdge, AtEdge]>  {}

#endif // CIRCT_DIALECT_FIRRTL_FIRRTLATTRIBUTES_TD
