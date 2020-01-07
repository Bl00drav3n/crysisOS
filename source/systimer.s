.globl GetSystemTimerAddress
GetSystemTimerAddress:
  ldr r0,=0x20003000
  mov pc,lr

.global GetSystemTime
GetSystemTime:
  push {lr}
  bl GetSystemTimerAddress
  ldrd r0, r1, [r0,#4]
  pop {pc}

.globl Microsleep
Microsleep:
  micros .req r0
  push {lr}
  mov r3,micros
  .unreq micros
  micros .req r3
  bl GetSystemTime
  start .req r2
  mov start, r0
  waitLoop$:
    bl GetSystemTime
    elapsed .req r1
    sub elapsed,r0,start
    cmp elapsed,micros
    .unreq elapsed
    bls waitLoop$
  .unreq start
  .unreq micros
  pop {pc}

