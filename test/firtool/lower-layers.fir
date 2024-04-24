; RUN: firtool -verilog %s | FileCheck %s

; This is an end-to-end example of a test-bench (Foo) enabling verification,
; probing into a device-under-test (Bar), and reading from hardware which is
; only present if the verification layer is enabled.

FIRRTL version 4.0.0

circuit Foo: %[[
  {"class": "firrtl.transforms.DontTouchAnnotation", "target": "~Foo|Bar>c"},
  {"class": "firrtl.transforms.DontTouchAnnotation", "target": "~Foo|Foo>d"},
  {"class": "firrtl.transforms.DontTouchAnnotation", "target": "~Foo|VerificationHelper>w"}
]]
  ; The bindfile for Verification should be placed in its specified output
  ; directory, "testbench", as well as any layerblock modules.
  layer Verification, bind, "testbench":

  ; Since the VerificationHelper is only used under the verification layer, it
  ; should be pulled into the testbench output directory.
  module VerificationHelper:
    input i : UInt<1>
    output o : UInt<1>
    wire w : UInt<1>
    connect w, i
    connect o, w

  ; CHECK: module Bar();
  ; CHECK: endmodule
  module Bar:
    input a: UInt<1>
    output b: Probe<UInt<1>, Verification>

    ; The extracted Bar_Verification module should be placed into the
    ; testbench output direction.
    layerblock Verification:
      node c = UInt<1>(0)
      define b = probe(c)
      inst helper of VerificationHelper
      connect helper.i, c

  ; CHECK: module Foo();
  ; CHECK:   wire d = Foo.bar.verification.c_probe;
  ; CHECK:   Bar bar ();
  ; CHECK: endmodule
  public module Foo enablelayer Verification:
    inst bar of Bar
    node d = read(bar.b)
    connect bar.a, d

  ; CHECK: FILE "testbench/layers_Foo_Verification.sv"
  ; CHECK: `ifndef layers_Foo_Verification
  ; CHECK: `define layers_Foo_Verification
  ; CHECK: bind Bar Bar_Verification verification ();
  ; CHECK: `endif // layers_Foo_Verification

  ; CHECK: FILE "testbench/VerificationHelper.sv"
  ; CHECK: module VerificationHelper(
  ; CHECK:   input i
  ; CHECK: );
  ; CHECK:   wire w = i;
  ; CHECK: endmodule

  ; CHECK: FILE "testbench/Bar_Verification.sv"
  ; CHECK: module Bar_Verification();
  ; CHECK:   wire c = 1'h0;
  ; CHECK:   wire c_probe = c;
  ; CHECK: endmodule
