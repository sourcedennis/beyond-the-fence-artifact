// Litmus: isa2_TB_01_2_SCOPE_BLOCK_FENCE_SCOPE_DEVICE_THREAD_2_FENCE_ACQ
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
    r0 : ptx/Acquire,
    r1 : ptx/Read - ptx/Acquire,
    r2 : ptx/Read - ptx/Acquire,
    w0 : ptx/Write - ptx/Release,
    w1 : ptx/Release,
    w2 : ptx/Write - ptx/Release,
    f0 : ptx/FenceAcqRel |

    // Program Order
    t0.start = w0 and
    w0.po = w1 and
    t0 != t1 and
    t1.start = r0 and
    r0.po = w2 and
    t1 != t2 and
    t2.start = r1 and
    r1.po = f0 and
    f0.po = r2 and

    // Addresses 
    r2.address = w0.address and
    r0.address = w1.address and
    r1.address = w2.address and
    r1.address != r2.address and
    r0.address != r2.address and
    r0.address != r1.address and

    // Scopes 
    t0 in w0.scope.*subscope and
    t1 in w0.scope.*subscope and
    t2 not in w0.scope.*subscope and
    t0 in w1.scope.*subscope and
    t1 in w1.scope.*subscope and
    t2 not in w1.scope.*subscope and
    t0 in r0.scope.*subscope and
    t1 in r0.scope.*subscope and
    t2 not in r0.scope.*subscope and
    t0 in w2.scope.*subscope and
    t1 in w2.scope.*subscope and
    t2 not in w2.scope.*subscope and
    t0 not in r1.scope.*subscope and
    t1 not in r1.scope.*subscope and
    t2 in r1.scope.*subscope and
    f0.scope = System and
    t0 not in r2.scope.*subscope and
    t1 not in r2.scope.*subscope and
    t2 in r2.scope.*subscope and

    // Outcome 
    no r2.~rf and
    r1 in w2.rf  and
    r0 in w1.rf  and

  ptx_mm

}
run generated_litmus_test for 15