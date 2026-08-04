// Litmus: wrw_2w_TB_012_SCOPE_DEVICE_FENCE_SCOPE_BLOCK_THREAD_1_FENCE
// Expected: ?
module litmus
open ptx as ptx
pred generated_litmus_test {
  # ptx/Thread = 3
  # ptx/Read = 3
  # ptx/Write = 4
  # ptx/Fence = 3

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
    w3 : ptx/Release,
    f0 : ptx/FenceAcqRel,
    f1 : ptx/FenceSC,
    f2 : ptx/FenceSC |

    // Program Order
    t0.start = w0 and
    t0 != t1 and
    t1.start = r0 and
    r0.po = f0 and
    f0.po = w1 and
    w1.po = f1 and
    f1.po = r1 and
    t1 != t2 and
    t2.start = w2 and
    w2.po = w3 and
    w3.po = f2 and
    f2.po = r2 and

    // Addresses 
    r0.address = r2.address and
    r0.address = w0.address and
    r1.address = w1.address and
    r1.address = w2.address and
    r0.address = w3.address and
    r0.address != r1.address and

    // Scopes 
    w0.scope = System and
    r0.scope = System and
    f0.scope = System and
    w1.scope = System and
    f1.scope = System and
    r1.scope = System and
    w2.scope = System and
    w3.scope = System and
    f2.scope = System and
    r2.scope = System and

    // Outcome 
    r2 in w0.rf  and
    r1 in w2.rf  and
    r0 in w0.rf  and

  ptx_mm

}
run generated_litmus_test for 15