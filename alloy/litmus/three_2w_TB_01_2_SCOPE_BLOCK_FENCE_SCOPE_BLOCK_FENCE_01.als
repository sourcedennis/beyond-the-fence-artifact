// Litmus: three_2w_TB_01_2_SCOPE_BLOCK_FENCE_SCOPE_BLOCK_FENCE_01
// Expected: ?
module litmus
open ptx as ptx
pred generated_litmus_test {
  # ptx/Thread = 3
  # ptx/Read = 3
  # ptx/Write = 6
  # ptx/Fence = 5

  some
    t0 : ptx/Thread,
    t1 : ptx/Thread,
    t2 : ptx/Thread,
    r0 : ptx/Read - ptx/Acquire,
    r1 : ptx/Read - ptx/Acquire,
    r2 : ptx/Read - ptx/Acquire,
    w0 : ptx/Write - ptx/Release,
    w1 : ptx/Write - ptx/Release,
    w2 : ptx/Write - ptx/Release,
    w3 : ptx/Write - ptx/Release,
    w4 : ptx/Write - ptx/Release,
    w5 : ptx/Release,
    f0 : ptx/FenceAcqRel,
    f1 : ptx/FenceSC,
    f2 : ptx/FenceAcqRel,
    f3 : ptx/FenceSC,
    f4 : ptx/FenceSC |

    // Program Order
    t0.start = w0 and
    w0.po = f0 and
    f0.po = w1 and
    w1.po = f1 and
    f1.po = r0 and
    t0 != t1 and
    t1.start = w2 and
    w2.po = f2 and
    f2.po = w3 and
    w3.po = f3 and
    f3.po = r1 and
    t1 != t2 and
    t2.start = w4 and
    w4.po = w5 and
    w5.po = f4 and
    f4.po = r2 and

    // Addresses 
    r2.address = w0.address and
    r0.address = w1.address and
    r0.address = w2.address and
    r1.address = w3.address and
    r1.address = w4.address and
    r2.address = w5.address and
    r1.address != r2.address and
    r0.address != r2.address and
    r0.address != r1.address and

    // Scopes 
    t0 in w0.scope.*subscope and
    t1 in w0.scope.*subscope and
    t2 not in w0.scope.*subscope and
    t0 in f0.scope.*subscope and
    t1 in f0.scope.*subscope and
    t2 not in f0.scope.*subscope and
    t0 in w1.scope.*subscope and
    t1 in w1.scope.*subscope and
    t2 not in w1.scope.*subscope and
    f1.scope = System and
    r0.scope = System and
    t0 in w2.scope.*subscope and
    t1 in w2.scope.*subscope and
    t2 not in w2.scope.*subscope and
    t0 in f2.scope.*subscope and
    t1 in f2.scope.*subscope and
    t2 not in f2.scope.*subscope and
    t0 in w3.scope.*subscope and
    t1 in w3.scope.*subscope and
    t2 not in w3.scope.*subscope and
    f3.scope = System and
    r1.scope = System and
    t0 not in w4.scope.*subscope and
    t1 not in w4.scope.*subscope and
    t2 in w4.scope.*subscope and
    t0 not in w5.scope.*subscope and
    t1 not in w5.scope.*subscope and
    t2 in w5.scope.*subscope and
    f4.scope = System and
    r2.scope = System and

    // Outcome 
    r2 in w0.rf  and
    r1 in w4.rf  and
    r0 in w2.rf  and

  ptx_mm

}
run generated_litmus_test for 15