.section .text
.globl ACTSetState
// result: r0 = sequence number
ACTSetState:
  push {lr}
  mov r2, r0
  mov r3, r1
  ptrn .req r2
  seq .req r3

  ldr ptrn,[ptrn]

  pinNum .req r0
  pinVal .req r1
  mov pinNum,#47
  mov pinVal,#1
  lsl pinVal,seq
  and pinVal,ptrn
  push {seq}
  bl SetGpio
  pop {seq}
  .unreq pinNum
  .unreq pinVal

  result .req r0
  add seq,#1
  cmp seq,#31
  movls result,seq
  movhi result,#0

  pop {pc}

.globl LoopForever
LoopForever:
  mov r0,#0
  push {r0}
loop$:
  pattern .req r0
  ldr pattern,=ACTPatternFlash0
  pop {r1}
  bl ACTSetState
  push {r0}
  .unreq pattern

  ldr r0,=50000
  bl Microsleep
  b loop$ 

.section .data
.globl ACTPatternFlash0
.globl ACTPatternFlash1
.globl ACTPatternFlash2
.globl ACTPatternFlash4
.globl ACTPatternFlash8
.globl ACTPatternSOS
.align 2
ACTPatternFlash0:
.int 0b11111111111111110000000000000000
ACTPatternFlash1:
.int 0b11111111000000001111111100000000
ACTPatternFlash2:
.int 0b11110000111100001111000011110000
ACTPatternFlash4:
.int 0b11001100110011001100110011001100
ACTPatternFlash8:
.int 0b10101010101010101010101010101010
ACTPatternSOS:
.int 0b10101001110001110001110001010100
