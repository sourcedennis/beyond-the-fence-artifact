// Litmus: lb_TB_01_SCOPE_DEVICE_FENCE_SCOPE_DEVICE_BOTH_FENCE
// Expected: ?
module litmus
open ptx as ptx
pred generated_litmus_test {
  # ptx/Thread = 2
  # ptx/Read = 2
  # ptx/Write = 2
  # ptx/Fence = 2

  some
    t0 : ptx/Thread,
    t1 : ptx/Thread,
    r0 : ptx/Read - ptx/Acquire,
    r1 : ptx/Read - ptx/Acquire,
    w0 : ptx/Write - ptx/Release,
    w1 : ptx/Write - ptx/Release,
    f0 : ptx/FenceAcqRel,
    f1 : ptx/FenceAcqRel |

    // Program Order
    t0.start = r0 and
    r0.po = f0 and
    f0.po = w0 and
    t0 != t1 and
    t1.start = r1 and
    r1.po = f1 and
    f1.po = w1 and

    // Addresses 
    r1.address = w0.address and
    r0.address = w1.address and
    r0.address != r1.address and

    // Scopes 
    r0.scope = System and
    f0.scope = System and
    w0.scope = System and
    r1.scope = System and
    f1.scope = System and
    w1.scope = System and

    // Outcome 
    r1 in w0.rf  and
    r0 in w1.rf  and

  ptx_mm

}
run generated_litmus_test for 15