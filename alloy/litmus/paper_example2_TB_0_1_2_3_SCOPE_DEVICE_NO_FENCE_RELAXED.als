// Litmus: paper_example2_TB_0_1_2_3_SCOPE_DEVICE_NO_FENCE_RELAXED
// Expected: ?
module litmus
open ptx as ptx
pred generated_litmus_test {
  # ptx/Thread = 4
  # ptx/Read = 4
  # ptx/Write = 4
  # ptx/Fence = 0

  some
    t0 : ptx/Thread,
    t1 : ptx/Thread,
    t2 : ptx/Thread,
    t3 : ptx/Thread,
    r0 : ptx/Read - ptx/Acquire,
    r1 : ptx/Read - ptx/Acquire,
    r2 : ptx/Read - ptx/Acquire,
    r3 : ptx/Read - ptx/Acquire,
    w0 : ptx/Write - ptx/Release,
    w1 : ptx/Write - ptx/Release,
    w2 : ptx/Write - ptx/Release,
    w3 : ptx/Write - ptx/Release |

    // Program Order
    t0.start = w0 and
    w0.po = w1 and
    t0 != t1 and
    t1.start = r0 and
    r0.po = r1 and
    t1 != t2 and
    t2.start = w2 and
    w2.po = w3 and
    t2 != t3 and
    t3.start = r2 and
    r2.po = r3 and

    // Addresses 
    r3.address = w0.address and
    r0.address = w1.address and
    r1.address = w2.address and
    r2.address = w3.address and
    r2.address != r3.address and
    r1.address != r3.address and
    r1.address != r2.address and
    r0.address != r3.address and
    r0.address != r2.address and
    r0.address != r1.address and

    // Scopes 
    w0.scope = System and
    w1.scope = System and
    r0.scope = System and
    r1.scope = System and
    w2.scope = System and
    w3.scope = System and
    r2.scope = System and
    r3.scope = System and

    // Outcome 
    no r3.~rf and
    r2 in w3.rf  and
    no r1.~rf and
    r0 in w1.rf  and

  ptx_mm

}
run generated_litmus_test for 15