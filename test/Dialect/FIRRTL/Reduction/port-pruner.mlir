// UNSUPPORTED: system-windows
//   See https://github.com/llvm/circt/issues/4129
// RUN: circt-reduce %s --test /usr/bin/env --test-arg grep --test-arg -q --test-arg "firrtl.module private @Bar" --keep-best=0 --include firrtl-remove-unused-ports | FileCheck %s

firrtl.circuit "Foo" {
  // CHECK-LABEL: firrtl.module @Foo
  firrtl.module @Foo(in %x: !firrtl.uint<1>, out %y: !firrtl.uint<3>) {
    // CHECK: %bar = firrtl.instance @Bar(in b: !firrtl.uint<1>, out d: !firrtl.uint<1>)
    %bar = firrtl.instance @Bar(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>, out d: !firrtl.uint<1>, out e: !firrtl.uint<1>)
    %bar_a = firrtl.instance.sub %bar[a] : !firrtl.instance<@Bar(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>, out d: !firrtl.uint<1>, out e: !firrtl.uint<1>)>
    firrtl.connect %bar_a, %x : !firrtl.uint<1>, !firrtl.uint<1>
    %bar_b = firrtl.instance.sub %bar[b] : !firrtl.instance<@Bar(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>, out d: !firrtl.uint<1>, out e: !firrtl.uint<1>)>
    firrtl.connect %bar_b, %x : !firrtl.uint<1>, !firrtl.uint<1>
    %bar_c = firrtl.instance.sub %bar[c] : !firrtl.instance<@Bar(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>, out d: !firrtl.uint<1>, out e: !firrtl.uint<1>)>
    %bar_d = firrtl.instance.sub %bar[d] : !firrtl.instance<@Bar(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>, out d: !firrtl.uint<1>, out e: !firrtl.uint<1>)>
    %0 = firrtl.add %bar_c, %bar_d : (!firrtl.uint<1>, !firrtl.uint<1>) -> !firrtl.uint<2>
    %bar_e = firrtl.instance.sub %bar[e] : !firrtl.instance<@Bar(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>, out d: !firrtl.uint<1>, out e: !firrtl.uint<1>)>
    %1 = firrtl.add %0, %bar_e : (!firrtl.uint<2>, !firrtl.uint<1>) -> !firrtl.uint<3>
    firrtl.connect %y, %1 : !firrtl.uint<3>, !firrtl.uint<3>
  }

  // We're only ever using ports %b and %d -- the rest should be stripped.
  // CHECK-LABEL: firrtl.module private @Bar
  // CHECK-NOT: in %a
  // CHECK-SAME: in %b
  // CHECK-NOT: out %c
  // CHECK-SAME: out %d
  // CHECK-NOT: out %e
  firrtl.module private @Bar(
    in %a: !firrtl.uint<1>,
    in %b: !firrtl.uint<1>,
    out %c: !firrtl.uint<1>,
    out %d: !firrtl.uint<1>,
    out %e: !firrtl.uint<1>
  ) {
    %invalid_ui1 = firrtl.invalidvalue : !firrtl.uint<1>
    %0 = firrtl.not %b : (!firrtl.uint<1>) -> !firrtl.uint<1>
    firrtl.connect %c, %invalid_ui1 : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %d, %0 : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %e, %invalid_ui1 : !firrtl.uint<1>, !firrtl.uint<1>
  }
}
