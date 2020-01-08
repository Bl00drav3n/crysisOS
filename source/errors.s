.section .text
.globl _panic
_panic:
  pattern .req r4
  delay .req r5
  seq .req r6
  mov pattern,r0
  mov delay,r1
  ldr seq,=PanicSeq
loop1$:
  mov r0,pattern
  ldr r1,[seq]
  bl ACTSetState
  str r0,[seq]

  mov r0,delay
  bl Microsleep
  .unreq delay
  .unreq pattern
  .unreq seq

  b loop1$

.globl _panicGeneral
_panicGeneral:
  ldr r0,=ACTPatternSOS
  ldr r1,=100000
  b _panic

.globl _panicGraphics
_panicGraphics:
  ldr r0,=ACTPatternFlash8
  ldr r1,=50000
  b _panic

.globl _panicVbufMsg
_panicVbufMsg:
  ldr r0,=ACTPatternFlash3x
  ldr r1,=50000
  b _panic

.section .data
PanicSeq:
  .int 0
