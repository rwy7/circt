// RUN: circt-opt -firrtl-assign-output-dirs %s

// ------

firrtl.circuit "AssignOutputDirs"
  attributes {
      // Directory Precedence Tree
      //        R
      //    A       B
      //  C   D   E   F
      annotations = [
        {class = "circt.DeclareOutputDirAnnotation", name = "C", parent = "A"},
        {class = "circt.DeclareOutputDirAnnotation", name = "D", parent = "A"},
        {class = "circt.DeclareOutputDirAnnotation", name = "E", parent = "B"},
        {class = "circt.DeclareOutputDirAnnotation", name = "F", parent = "B"}
      ]
  } {

  firrtl.module private @AssignOutputDirs() {}

  // R -> R
  firrtl.module private @ByR() {}

  // R & A -> R
  firrtl.module private @ByRA() {}

  // R & C -> R
  firrtl.module private @ByRC() {}

  // A -> A
  firrtl.module private @ByA() {}
  
  // A & B -> <null>
  firrtl.module private @ByAB() {}

  // C & D -> A
  firrtl.module private @ByCD() {}

  // A & C -> A
  firrtl.module private @ByAC() {}

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
  }

  firrtl.module @InC() attributes {output_file = #hw.output_file<"C/">} {
    firrtl.instance byCD @ByCD()
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