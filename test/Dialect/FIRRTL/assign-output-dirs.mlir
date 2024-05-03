// RUN: circt-opt -firrtl-assign-output-dirs %s

firrtl.circuit "AssignOutputDirs"
  attributes {
      // Directory Precedence Tree
      //        R
      //    A       B
      //  C   D
      annotations = [
        {class = "circt.DeclareOutputDirAnnotation", name = "B", parent = ""},
        {class = "circt.DeclareOutputDirAnnotation", name = "C", parent = "A"},
        {class = "circt.DeclareOutputDirAnnotation", name = "D", parent = "A"}
      ]
  } {

  firrtl.module private @AssignOutputDirs() {}

  // R -> R
  // CHECK: firrtl.module private @ByR() {
  firrtl.module private @ByR() {}

  // R & A -> R
  // CHECK: firrtl.module private @ByRA() {
  firrtl.module private @ByRA() {}

  // R & C -> R
  // CHECK: firrtl.module private @ByRC() {
  firrtl.module private @ByRC() {}

  // A -> A
  // CHECK: firrtl.module private @ByA() attributes {output_file = #hw.output_file<"A/">} {
  firrtl.module private @ByA() {}
  
  // A & B -> R
  // firrtl.module private @ByAB() {
  firrtl.module private @ByAB() {}

  // C & D -> A
  // CHECK: firrtl.module private @ByCD() attributes {output_file = #hw.output_file<"A/">} {
  firrtl.module private @ByCD() {}

  // A & C -> A
  // CHECK: firrtl.module private @ByAC() attributes {output_file = #hw.output_file<"A/">} {
  firrtl.module private @ByAC() {}

  // B & C -> R
  // CHECK: firrtl.module private @ByBC() attributes {
  firrtl.module private @ByBC() {}

  firrtl.module @InR() {
    firrtl.instance r  @ByR()
    firrtl.instance ra @ByRA()
    firrtl.instance rc @ByRC()
  }

  firrtl.module @InA() attributes {output_file = #hw.output_file<"A/foo">} {
    firrtl.instance ra @ByRA()
    firrtl.instance ab @ByAB()
    firrtl.instance a  @ByA()
    firrtl.instance ac @ByAC()
  }

  firrtl.module @InB() attributes {output_file = #hw.output_file<"B/foo">} {
    firrtl.instance ab @ByAB()
    firrtl.instance bc @ByBC()
  }

  firrtl.module @InC() attributes {output_file = #hw.output_file<"C/">} {
    firrtl.instance cd @ByCD()
    firrtl.instance bc @ByBC()
  }

  firrtl.module @InD() attributes {output_file = #hw.output_file<"D/">} {
    firrtl.instance byCD @ByCD()
  }
}

// when a module with an output directory is used, that 
// directory is respected

// when a module doesnt have an output directory, it's dragged

// when a module is used in both a child and parent, it is dragged

// when a module is used by two children, it is dragged to parent.

// circular parent/child relationship
// parent is null / root
// child name is empty???