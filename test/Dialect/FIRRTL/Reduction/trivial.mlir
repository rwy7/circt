// UNSUPPORTED: system-windows
//   See https://github.com/llvm/circt/issues/4129
// RUN: circt-reduce %s --test /bin/sh --test-arg -c --test-arg 'firtool "$0" 2>&1 | grep -q "error: sink \"x1.x\" not fully initialized"' --keep-best=0 | FileCheck %s

firrtl.circuit "Foo" {
  // CHECK-NOT: firrtl.module @FooFooFoo
  firrtl.module @FooFooFoo(in %x: !firrtl.uint<1>, out %y: !firrtl.uint<1>) {
    firrtl.connect %y, %x : !firrtl.uint<1>, !firrtl.uint<1>
  }
  // CHECK-NOT: firrtl.module @FooFooBar
  firrtl.module @FooFooBar(in %x: !firrtl.uint<1>, out %y: !firrtl.uint<1>) {
    firrtl.connect %y, %x : !firrtl.uint<1>, !firrtl.uint<1>
  }
  // CHECK-NOT: firrtl.module @FooFoo
  firrtl.module @FooFoo(in %x: !firrtl.uint<1>, out %y: !firrtl.uint<1>) {
    %x0 = firrtl.instance @FooFooFoo(in x: !firrtl.uint<1>, out y: !firrtl.uint<1>)
    %x0_x = firrtl.instance.sub %x0[x] : !firrtl.instance<@FooFooFoo(in x: !firrtl.uint<1>, out y: !firrtl.uint<1>)>
    %x0_y = firrtl.instance.sub %x0[y] : !firrtl.instance<@FooFooFoo(in x: !firrtl.uint<1>, out y: !firrtl.uint<1>)>
    %x1 = firrtl.instance @FooFooBar(in x: !firrtl.uint<1>, out y: !firrtl.uint<1>)
    %x1_x = firrtl.instance.sub %x1[x] : !firrtl.instance<@FooFooBar(in x: !firrtl.uint<1>, out y: !firrtl.uint<1>)>
    %x1_y = firrtl.instance.sub %x1[y] : !firrtl.instance<@FooFooBar(in x: !firrtl.uint<1>, out y: !firrtl.uint<1>)>
    firrtl.connect %x0_x, %x : !firrtl.uint<1>, !firrtl.uint<1>
    // Skip %x1_x to trigger a "sink not fully initialized" warning
    firrtl.connect %y, %x0_y : !firrtl.uint<1>, !firrtl.uint<1>
  }
  // CHECK-NOT: firrtl.module @FooBar
  firrtl.module @FooBar(in %x: !firrtl.uint<1>, out %y: !firrtl.uint<1>) {
    firrtl.connect %y, %x : !firrtl.uint<1>, !firrtl.uint<1>
  }
  // CHECK: firrtl.module @Foo
  firrtl.module @Foo(in %x: !firrtl.uint<1>, out %y: !firrtl.uint<1>) {
    %x0 = firrtl.instance @FooFoo(in x: !firrtl.uint<1>, out y: !firrtl.uint<1>)
    %x0_x = firrtl.instance.sub %x0[x] : !firrtl.instance<@FooFoo(in x: !firrtl.uint<1>, out y: !firrtl.uint<1>)>
    %x0_y = firrtl.instance.sub %x0[y] : !firrtl.instance<@FooFoo(in x: !firrtl.uint<1>, out y: !firrtl.uint<1>)>
    %x1 = firrtl.instance @FooBar(in x: !firrtl.uint<1>, out y: !firrtl.uint<1>)
    %x1_x = firrtl.instance.sub %x1[x] : !firrtl.instance<@FooBar(in x: !firrtl.uint<1>, out y: !firrtl.uint<1>)>
    firrtl.connect %x0_x, %x : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %x1_x, %x : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %y, %x0_y : !firrtl.uint<1>, !firrtl.uint<1>
  }
}
