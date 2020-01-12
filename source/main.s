.include "framebuffer.inc"

.section .init
.globl _start
_start:
  b main

.section .data
.align 2
Display:
  .int 1920 // width
  .int 1080 // height
  .int 32   // depth
  //.int FBFLAG_DOUBLE // flags
  .int 0 // flags

.align 2
Color:
Red:
  .int 0
Green:
  .int 0
Blue:
  .int 0

.section .text
main:
  mov sp,#0x8000
  ldr r3,=Display
  ldmia r3,{r0,r1,r2,r3}
  bl InitialiseFramebuffer
  teq r0,#0
  beq _panicGeneral
  bl SetGraphicsAddress

  mov r0,#0
  ldr r1,=LEDSequence
  str r0,[r1]

  rnd .req r4
  col .req r5
  lastx .req r6
  lasty .req r7
  mov rnd,#0
  mov col,#0
  mov lastx,#0
  mov lasty,#0

render$:
  bl SwapBuffers

/*
  ldr r0,=ACTPatternFlash8
  ldr r2,=LEDSequence
  ldr r1,[r2]
  push {r2}
  bl ACTSetState
  pop {r2}
  str r0,[r2]
  ldr r0,=16000
  bl Microsleep
*/

  x .req r8
  y .req r9
  mov r0,rnd
  bl Random
  mov x,r0
  bl Random
  mov y,r0
  mov rnd,y

/*
  ldr r1,=Color
  ldr r0,[r1,#8]
  add r0,#0x20
  cmp r0,#0x100
  movhi r0,#0
  strhi r0,[r1,#8]
  ldrhi r0,[r1,#4]
  addhi r0,#0x20
  cmphi r0,#0x100
  movhi r0,#0
  strhi r0,[r1,#4]
  ldrhi r0,[r1]
  addhi r0,#0x20
  cmphi r0,#0x100
  movhi r0,#0
  strhi r0,[r1]

  ldr r0,=Red
  ldr r0,[r0]
  ldr r1,=Green
  ldr r1,[r1]
  ldr r2,=Blue
  ldr r2,[r2]
  orr r0,r1,r0,lsl #8
  orr r0,r2,r0,lsl #8
  and r0,#0x00FFFFFF
*/

  lsr x,#22
  lsr y,#22
  add x,#448
  add y,#28

  mov r0,col
  bl SetBrushColor
  add col,#20
  and col,#0x00FFFFFF
  mov r0,lastx
  mov r1,lasty
  mov r2,x
  mov r3,y
  bl DrawRect

  mov r0,#0x00FFFFFF
  bl SetBrushColor
  mov r0,lastx
  mov r1,lasty
  mov r2,x
  mov r3,y
  bl DrawLine

  mov lastx,x
  mov lasty,y

  b render$
  .unreq rnd
  .unreq x
  .unreq y

.section .data
.align 2
LEDSequence:
  .int 0
