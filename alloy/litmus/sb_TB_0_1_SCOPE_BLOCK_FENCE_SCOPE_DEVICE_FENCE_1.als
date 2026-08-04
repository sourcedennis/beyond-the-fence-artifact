// Litmus: sb_TB_0_1_SCOPE_BLOCK_FENCE_SCOPE_DEVICE_FENCE_1
// Expected: ?
module litmus
open ptx as ptx
pred generated_litmus_test {
  # ptx/Thread = 2
  # ptx/Read = 2
  # ptx/Write = 2
  # ptx/Fence = 1

  some
    t0 : ptx/Thread,
    t1 : ptx/Thread,
    r0 : ptx/Read - ptx/Acquire,
    r1 : ptx/Read - ptx/Acquire,
    w0 : ptx/Write - ptx/Release,
    w1 : ptx/Write - ptx/Release,
    f0 : ptx/FenceSC |

    // Program Order
    t0.start = w0 and
    w0.po = r0 and
    t0 != t1 and
    t1.start = w1 and
    w1.po = f0 and
    f0.po = r1 and

    // Addresses 
    r1.address = w0.address and
    r0.address = w1.address and
    r0.address != r1.address and

    // Scopes 
    t0 in w0.scope.*subscope and
    t1 not in w0.scope.*subscope and
    t0 in r0.scope.*subscope and
    t1 not in r0.scope.*subscope and
    t0 not in w1.scope.*subscope and
    t1 in w1.scope.*subscope and
    f0.scope = System and
    t0 not in r1.scope.*subscope and
    t1 in r1.scope.*subscope and

    // Outcome 
    no r1.~rf and
    no r0.~rf and

  ptx_mm

}
run generated_litmus_test for 15