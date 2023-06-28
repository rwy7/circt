// RUN: circt-opt -firrtl-extract-classes %s | FileCheck %s

firrtl.circuit "Top" {
  // CHECK-LABEL: firrtl.module @Top
  firrtl.module @Top() {
    // CHECK-NOT: firrtl.instance all
    %all = firrtl.instance @AllProperties(
      in in0: !firrtl.string,
      out out0: !firrtl.string)

    // CHECK: %some = firrtl.instance @SomeProperties(in in1: !firrtl.uint<1>, out out3: !firrtl.uint<1>)
    %some = firrtl.instance @SomeProperties(
      in in0: !firrtl.string,
      in in1: !firrtl.uint<1>,
      out out0: !firrtl.string,
      out out1: !firrtl.string,
      out out2: !firrtl.string,
      out out3: !firrtl.uint<1>)

    // CHECK: %no = firrtl.instance @NoProperties
    %no = firrtl.instance @NoProperties(
      in in0: !firrtl.uint<1>,
      out out0: !firrtl.uint<1>)

    // CHECK-NOT: %some_in0 = firrtl.instance.sub %some[in0]
    %some_in0 = firrtl.instance.sub %some[in0] : !firrtl.instance<
      @SomeProperties(
        in in0: !firrtl.string,
        in in1: !firrtl.uint<1>,
        out out0: !firrtl.string,
        out out1: !firrtl.string,
        out out2: !firrtl.string,
        out out3: !firrtl.uint<1>)>

  // CHECK-NOT: %all_out0 = firrtl.instance.sub %all[out0]
  %all_out0 = firrtl.instance.sub %all[out0] : !firrtl.instance<
    @AllProperties(
        in in0: !firrtl.string,
        out out0: !firrtl.string)>

    // CHECK-NOT: firrtl.propassign
    firrtl.propassign %some_in0, %all_out0 : !firrtl.string
  }

  // CHECK-NOT: @AllProperties
  firrtl.module @AllProperties(
      in %in0: !firrtl.string,
      out %out0: !firrtl.string) {
    firrtl.propassign %out0, %in0 : !firrtl.string
  }

  // CHECK-LABEL: firrtl.module @SomeProperties
  // CHECK-SAME: (in %in1: !firrtl.uint<1>, out %out3: !firrtl.uint<1>)
  // CHECK-NOT: firrtl.propassign
  firrtl.module @SomeProperties(
      in %in0: !firrtl.string,
      in %in1: !firrtl.uint<1>,
      out %out0: !firrtl.string,
      out %out1: !firrtl.string,
      out %out2: !firrtl.string,
      out %out3: !firrtl.uint<1>) {
    %0 = firrtl.string "hello"
    firrtl.propassign %out0, %0 : !firrtl.string
    firrtl.propassign %out1, %0 : !firrtl.string
    firrtl.propassign %out2, %in0 : !firrtl.string
    firrtl.connect %out3, %in1 : !firrtl.uint<1>, !firrtl.uint<1>
  }

  // CHECK-LABEL: firrtl.module @NoProperties
  // CHECK-SAME: (in %in0: !firrtl.uint<1>, out %out0: !firrtl.uint<1>)
  // CHECK: firrtl.connect
  firrtl.module @NoProperties(
      in %in0: !firrtl.uint<1>,
      out %out0: !firrtl.uint<1>) {
    firrtl.connect %out0, %in0 : !firrtl.uint<1>, !firrtl.uint<1>
  }

  // CHECK-LABEL: firrtl.module @NestedProperties
  firrtl.module @NestedProperties(
      in %in0: !firrtl.string,
      in %in1: !firrtl.uint<1>,
      out %out0: !firrtl.string,
      out %out1: !firrtl.string,
      out %out2: !firrtl.string,
      out %out3: !firrtl.string,
      out %out4: !firrtl.uint<1>) {
    // CHECK-NOT: %all0 = firrtl.instance @AllProperties
    %all0 = firrtl.instance @AllProperties(
      in in0: !firrtl.string,
      out out0: !firrtl.string)

    // CHECK-NOT: %all1 = firrtl.instance @AllProperties
    %all1 = firrtl.instance @AllProperties(
      in in0: !firrtl.string,
      out out0: !firrtl.string)

    // CHECK-NOT: %all2 = firrtl.instance @allProperties
    %all2 = firrtl.instance @AllProperties(
      in in0: !firrtl.string,
      out out0: !firrtl.string)

    // CHECK: %some0 = firrtl.instance @SomeProperties
    %some0 = firrtl.instance @SomeProperties(
      in in0: !firrtl.string,
      in in1: !firrtl.uint<1>,
      out out0: !firrtl.string,
      out out1: !firrtl.string,
      out out2: !firrtl.string,
      out out3: !firrtl.uint<1>)

    // CHECK: %no0 = firrtl.instance @NoProperties
    %no0 = firrtl.instance @NoProperties(
      in in0: !firrtl.uint<1>,
      out out0: !firrtl.uint<1>)

    // CHECK-NOT %all0_in0 = firrtl.instance.sub %all0[in0]
    %all0_in0 = firrtl.instance.sub %all0[in0] :
      !firrtl.instance<@AllProperties(
        in in0: !firrtl.string,
        out out0: !firrtl.string)>

    // CHECK-NOT %all0_out0 = firrtl.instance.sub %all0[out0]
    %all0_out0 = firrtl.instance.sub %all0[out0] :
      !firrtl.instance<@AllProperties(
        in in0: !firrtl.string,
        out out0: !firrtl.string)>

    // CHECK-NOT %all1_in0 = firrtl.instance.sub %all1[in0]
    %all1_in0 = firrtl.instance.sub %all1[in0] :
      !firrtl.instance<@AllProperties(
        in in0: !firrtl.string,
        out out0: !firrtl.string)>

    // CHECK-NOT %all1_out0 = firrtl.instance.sub %all1[out0]
    %all1_out0 = firrtl.instance.sub %all1[out0] :
      !firrtl.instance<@AllProperties(
        in in0: !firrtl.string,
        out out0: !firrtl.string)>

    // CHECK-NOT %all2_in0 = firrtl.instance.sub %all2[in0]
    %all2_in0 = firrtl.instance.sub %all2[in0] :
      !firrtl.instance<@AllProperties(
        in in0: !firrtl.string,
        out out0: !firrtl.string)>

    // CHECK-NOT %all2_out0 = firrtl.instance.sub %all2[out0]
    %all2_out0 = firrtl.instance.sub %all2[out0] :
      !firrtl.instance<@AllProperties(
        in in0: !firrtl.string,
        out out0: !firrtl.string)>
  
    // CHECK-NOT %some0_in0 = firrtl.instance.sub %some0[in0]
    %some0_in0 = firrtl.instance.sub %some0[in0] :
      !firrtl.instance<@SomeProperties(
        in in0: !firrtl.string,
        in in1: !firrtl.uint<1>,
        out out0: !firrtl.string,
        out out1: !firrtl.string,
        out out2: !firrtl.string,
        out out3: !firrtl.uint<1>)>

    // CHECK-NOT %some0_in1 = firrtl.instance.sub %some0[in1]
    %some0_in1 = firrtl.instance.sub %some0[in1] :
      !firrtl.instance<@SomeProperties(
        in in0: !firrtl.string,
        in in1: !firrtl.uint<1>,
        out out0: !firrtl.string,
        out out1: !firrtl.string,
        out out2: !firrtl.string,
        out out3: !firrtl.uint<1>)>

    // CHECK-NOT %some0_out0 = firrtl.instance.sub %some0[out0]
    %some0_out0 = firrtl.instance.sub %some0[out0] :
      !firrtl.instance<@SomeProperties(
        in in0: !firrtl.string,
        in in1: !firrtl.uint<1>,
        out out0: !firrtl.string,
        out out1: !firrtl.string,
        out out2: !firrtl.string,
        out out3: !firrtl.uint<1>)>
  
    // CHECK-NOT %some0_out3 = firrtl.instance.sub %some0[out3]
    %some0_out3 = firrtl.instance.sub %some0[out3] :
      !firrtl.instance<@SomeProperties(
        in in0: !firrtl.string,
        in in1: !firrtl.uint<1>,
        out out0: !firrtl.string,
        out out1: !firrtl.string,
        out out2: !firrtl.string,
        out out3: !firrtl.uint<1>)>

    // CHECK-NOT %no0_in0 = firrtl.instance.sub %no0[in0]
    %no0_in0 = firrtl.instance.sub %no0[in0] :
      !firrtl.instance<@NoProperties(
        in in0: !firrtl.uint<1>,
        out out0: !firrtl.uint<1>)>

    // CHECK-NOT %no0_out0 = firrtl.instance.sub %no0[out0]
    %no0_out0 = firrtl.instance.sub %no0[out0] :
      !firrtl.instance<@NoProperties(
        in in0: !firrtl.uint<1>,
        out out0: !firrtl.uint<1>)>

    // CHECK-NOT: firrtl.string
    // CHECK-NOT: firrtl.propassign
    // CHECK-COUNT-3: firrtl.connect
    %0 = firrtl.string "hello"
    firrtl.propassign %all0_in0, %0 : !firrtl.string
    firrtl.propassign %all1_in0, %0 : !firrtl.string
    firrtl.propassign %all2_in0, %all1_out0 : !firrtl.string
    firrtl.propassign %some0_in0, %in0 : !firrtl.string
    firrtl.connect %some0_in1, %in1 : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %no0_in0, %some0_out3 : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.propassign %out0, %all0_out0 : !firrtl.string
    firrtl.propassign %out1, %all0_out0 : !firrtl.string
    firrtl.propassign %out2, %all2_out0 : !firrtl.string
    firrtl.propassign %out3, %some0_out0 : !firrtl.string
    firrtl.connect %out4, %no0_out0 : !firrtl.uint<1>, !firrtl.uint<1>
  }
}

// CHECK-LABEL: om.class @AllProperties
// CHECK-SAME: (%[[P0:.+]]: !firrtl.string)
// CHECK: om.class.field @out0, %[[P0]] : !firrtl.string

// CHECK-LABEL: om.class @SomeProperties
// CHECK-SAME: (%[[P0:.+]]: !firrtl.string)
// CHECK: %[[S0:.+]] = firrtl.string "hello"
// CHECK: om.class.field @out0, %[[S0]] : !firrtl.string
// CHECK: om.class.field @out1, %[[S0]] : !firrtl.string
// CHECK: om.class.field @out2, %[[P0]] : !firrtl.string

// CHECK-LABEL: om.class @NestedProperties
// CHECK-SAME: (%[[P0:.+]]: !firrtl.string)
// CHECK: %[[S0:.+]] = firrtl.string "hello"
// CHECK: %[[O0:.+]] = om.object @AllProperties(%[[S0]])
// CHECK: %[[F0:.+]] = om.object.field %[[O0]], [@out0]
// CHECK: om.class.field @out0, %[[F0]]
// CHECK: om.class.field @out1, %[[F0]]
// CHECK: %[[O1:.+]] = om.object @AllProperties(%[[S0]])
// CHECK: %[[F1:.+]] = om.object.field %[[O1]], [@out0]
// CHECK: %[[O2:.+]] = om.object @AllProperties(%[[F1]])
// CHECK: %[[F2:.+]] = om.object.field %[[O2]], [@out0]
// CHECK: om.class.field @out2, %[[F2]]
// CHECK: %[[O3:.+]] = om.object @SomeProperties(%[[P0]])
// CHECK: %[[F3:.+]] = om.object.field %[[O3]], [@out0]
// CHECK: om.class.field @out3, %[[F3]]
