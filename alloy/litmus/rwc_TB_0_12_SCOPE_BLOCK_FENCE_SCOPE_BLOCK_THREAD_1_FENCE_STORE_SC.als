// Litmus: rwc_TB_0_12_SCOPE_BLOCK_FENCE_SCOPE_BLOCK_THREAD_1_FENCE_STORE_SC
// Expected: ?
module litmus
open ptx as ptx
pred generated_litmus_test {
  # ptx/Thread = 3
  # ptx/Read = 3
  # ptx/Write = 2
  # ptx/Fence = 1

  some
    t0 : ptx/Thread,
    t1 : ptx/Thread,
    t2 : ptx/Thread,
    r0 : ptx/Read - ptx/Acquire,
    r1 : ptx/Read - ptx/Acquire,
    r2 : ptx/Read - ptx/Acquire,
    w0 : ptx/Write - ptx/Release,
    w1 : ptx/Write - ptx/Release,
    f0 : ptx/FenceAcqRel |

    // Program Order
    t0.start = w0 and
    t0 != t1 and
    t1.start = r0 and
    r0.po = f0 and
    f0.po = r1 and
    t1 != t2 and
    t2.start = w1 and
    w1.po = r2 and

    // Addresses 
    r0.address = r2.address and
    r0.address = w0.address and
    r1.address = w1.address and
    r0.address != r1.address and

    // Scopes 
    t0 in w0.scope.*subscope and
    t1 not in w0.scope.*subscope and
    t2 not in w0.scope.*subscope and
    t0 not in r0.scope.*subscope and
    t1 in r0.scope.*subscope and
    t2 in r0.scope.*subscope and
    t0 not in f0.scope.*subscope and
    t1 in f0.scope.*subscope and
    t2 in f0.scope.*subscope and
    t0 not in r1.scope.*subscope and
    t1 in r1.scope.*subscope and
    t2 in r1.scope.*subscope and
    t0 not in w1.scope.*subscope and
    t1 in w1.scope.*subscope and
    t2 in w1.scope.*subscope and
    t0 not in r2.scope.*subscope and
    t1 in r2.scope.*subscope and
    t2 in r2.scope.*subscope and

    // Outcome 
    no r2.~rf and
    no r1.~rf and
    r0 in w0.rf  and

  ptx_mm

}
run generated_litmus_test for 15