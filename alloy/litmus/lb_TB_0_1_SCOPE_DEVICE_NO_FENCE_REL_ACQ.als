// Litmus: lb_TB_0_1_SCOPE_DEVICE_NO_FENCE_REL_ACQ
// Expected: ?
module litmus
open ptx as ptx
pred generated_litmus_test {
  # ptx/Thread = 2
  # ptx/Read = 2
  # ptx/Write = 2
  # ptx/Fence = 0

  some
    t0 : ptx/Thread,
    t1 : ptx/Thread,
    r0 : ptx/Read - ptx/Acquire,
    r1 : ptx/Acquire,
    w0 : ptx/Release,
    w1 : ptx/Write - ptx/Release |

    // Program Order
    t0.start = r0 and
    r0.po = w0 and
    t0 != t1 and
    t1.start = r1 and
    r1.po = w1 and

    // Addresses 
    r1.address = w0.address and
    r0.address = w1.address and
    r0.address != r1.address and

    // Scopes 
    r0.scope = System and
    w0.scope = System and
    r1.scope = System and
    w1.scope = System and

    // Outcome 
    r1 in w0.rf  and
    r0 in w1.rf  and

  ptx_mm

}
run generated_litmus_test for 15