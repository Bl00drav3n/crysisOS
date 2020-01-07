.section .text
.globl panic
panic:
  mov r0,#0
  push {r0}
loop1$:
  pattern .req r0
  seq .req r1
  ldr pattern,=ACTPatternSOS
  pop {seq}
  bl ACTSetState
  push {r0}
  .unreq pattern
  .unreq seq

  delay .req r0
  ldr delay,=200000
  bl Microsleep
  .unreq delay
  b loop1$
