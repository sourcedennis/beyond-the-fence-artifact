// Litmus: isa2_TB_01_2_SCOPE_DEVICE_FENCE_SCOPE_BLOCK_THREAD_0_FENCE_REL
// Expected: ?
module litmus
open ptx as ptx
pred generated_litmus_test {
  # ptx/Thread = 3
  # ptx/Read = 3
  # ptx/Write = 3
  # ptx/Fence = 1

  some
    t0 : ptx/Thread,
    t1 : ptx/Thread,
    t2 : ptx/Thread,
    r0 : ptx/Read - ptx/Acquire,
    r1 : ptx/Acquire,
    r2 : ptx/Read - ptx/Acquire,
    w0 : ptx/Write - ptx/Release,
    w1 : ptx/Write - ptx/Release,
    w2 : ptx/Release,
    f0 : ptx/FenceAcqRel |

    // Program Order
    t0.start = w0 and
    w0.po = f0 and
    f0.po = w1 and
    t0 != t1 and
    t1.start = r0 and
    r0.po = w2 and
    t1 != t2 and
    t2.start = r1 and
    r1.po = r2 and

    // Addresses 
    r2.address = w0.address and
    r0.address = w1.address and
    r1.address = w2.address and
    r1.address != r2.address and
    r0.address != r2.address and
    r0.address != r1.address and

    // Scopes 
    w0.scope = System and
    t0 in f0.scope.*subscope and
    t1 in f0.scope.*subscope and
    t2 not in f0.scope.*subscope and
    w1.scope = System and
    r0.scope = System and
    w2.scope = System and
    r1.scope = System and
    r2.scope = System and

    // Outcome 
    no r2.~rf and
    r1 in w2.rf  and
    r0 in w1.rf  and

  ptx_mm

}
run generated_litmus_test for 15