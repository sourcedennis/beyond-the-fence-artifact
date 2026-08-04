// Litmus: two_2w_TB_01_SCOPE_DEVICE_NO_FENCE_RELEASE
// Expected: ?
module litmus
open ptx as ptx
pred generated_litmus_test {
  # ptx/Thread = 2
  # ptx/Read = 2
  # ptx/Write = 4
  # ptx/Fence = 2

  some
    t0 : ptx/Thread,
    t1 : ptx/Thread,
    r0 : ptx/Read - ptx/Acquire,
    r1 : ptx/Read - ptx/Acquire,
    w0 : ptx/Write - ptx/Release,
    w1 : ptx/Release,
    w2 : ptx/Write - ptx/Release,
    w3 : ptx/Release,
    f0 : ptx/FenceSC,
    f1 : ptx/FenceSC |

    // Program Order
    t0.start = w0 and
    w0.po = w1 and
    w1.po = f0 and
    f0.po = r0 and
    t0 != t1 and
    t1.start = w2 and
    w2.po = w3 and
    w3.po = f1 and
    f1.po = r1 and

    // Addresses 
    r1.address = w0.address and
    r0.address = w1.address and
    r0.address = w2.address and
    r1.address = w3.address and
    r0.address != r1.address and

    // Scopes 
    w0.scope = System and
    w1.scope = System and
    f0.scope = System and
    r0.scope = System and
    w2.scope = System and
    w3.scope = System and
    f1.scope = System and
    r1.scope = System and

    // Outcome 
    r1 in w0.rf  and
    r0 in w2.rf  and

  ptx_mm

}
run generated_litmus_test for 15