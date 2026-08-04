// Litmus: mp_TB_0_1_SCOPE_DEVICE_FENCE_SCOPE_BLOCK_BOTH_FENCE
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
    t0.start = w0 and
    w0.po = f0 and
    f0.po = w1 and
    t0 != t1 and
    t1.start = r0 and
    r0.po = f1 and
    f1.po = r1 and

    // Addresses 
    r1.address = w0.address and
    r0.address = w1.address and
    r0.address != r1.address and

    // Scopes 
    w0.scope = System and
    t0 in f0.scope.*subscope and
    t1 not in f0.scope.*subscope and
    w1.scope = System and
    r0.scope = System and
    t0 not in f1.scope.*subscope and
    t1 in f1.scope.*subscope and
    r1.scope = System and

    // Outcome 
    no r1.~rf and
    r0 in w1.rf  and

  ptx_mm

}
run generated_litmus_test for 15