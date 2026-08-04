// Litmus: paper_example3_TB_012_3_SCOPE_BLOCK_FENCE_SC_SCOPE_BLOCK
// Expected: ?
module litmus
open ptx as ptx
pred generated_litmus_test {
  # ptx/Thread = 4
  # ptx/Read = 4
  # ptx/Write = 4
  # ptx/Fence = 2

  some
    t0 : ptx/Thread,
    t1 : ptx/Thread,
    t2 : ptx/Thread,
    t3 : ptx/Thread,
    r0 : ptx/Acquire,
    r1 : ptx/Read - ptx/Acquire,
    r2 : ptx/Acquire,
    r3 : ptx/Acquire,
    w0 : ptx/Release,
    w1 : ptx/Release,
    w2 : ptx/Release,
    w3 : ptx/Release,
    f0 : ptx/FenceSC,
    f1 : ptx/FenceSC |

    // Program Order
    t0.start = w0 and
    t0 != t1 and
    t1.start = r0 and
    r0.po = f0 and
    f0.po = w1 and
    w1.po = r1 and
    t1 != t2 and
    t2.start = w2 and
    w2.po = w3 and
    t2 != t3 and
    t3.start = r2 and
    r2.po = f1 and
    f1.po = r3 and

    // Addresses 
    r0.address = r3.address and
    r0.address = w0.address and
    r1.address = w1.address and
    r1.address = w2.address and
    r2.address = w3.address and
    r1.address != r2.address and
    r0.address != r2.address and
    r0.address != r1.address and

    // Scopes 
    w0.scope = System and
    t0 in r0.scope.*subscope and
    t1 in r0.scope.*subscope and
    t2 in r0.scope.*subscope and
    t3 not in r0.scope.*subscope and
    t0 in f0.scope.*subscope and
    t1 in f0.scope.*subscope and
    t2 in f0.scope.*subscope and
    t3 not in f0.scope.*subscope and
    t0 in w1.scope.*subscope and
    t1 in w1.scope.*subscope and
    t2 in w1.scope.*subscope and
    t3 not in w1.scope.*subscope and
    t0 in r1.scope.*subscope and
    t1 in r1.scope.*subscope and
    t2 in r1.scope.*subscope and
    t3 not in r1.scope.*subscope and
    w2.scope = System and
    w3.scope = System and
    r2.scope = System and
    f1.scope = System and
    r3.scope = System and

    // Outcome 
    no r3.~rf and
    r2 in w3.rf  and
    r1 in w2.rf  and
    r0 in w0.rf  and

  ptx_mm

}
run generated_litmus_test for 15