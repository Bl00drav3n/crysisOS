.section .data
.align 2
brushColor:
  .int 0xFFFFFFFF
.align 2
graphicsAddress:
  .int 0

.include "framebuffer.inc"

.section .text
.globl SetBrushColor
SetBrushColor:
  ldr r1,=brushColor
  str r0,[r1]
  mov pc,lr

.globl SetGraphicsAddress
SetGraphicsAddress:
  ldr r1,=graphicsAddress
  str r0,[r1]
  mov pc,lr

.globl DrawPixel
DrawPixel:
  push {r4,lr}
  px .req r0
  py .req r1

  addr .req r2
  ldr addr,=graphicsAddress
  ldr addr,[addr]

  width .req r3
  ldr width,[addr,#FramebufferInfo.w]
  sub width,#1
  cmp px,width
  pophi {r4,pc}
  .unreq width

  height .req r3
  ldr height,[addr,#FramebufferInfo.h]
  sub height,#1
  cmp py,height
  pophi {r4,pc}
  .unreq height

  ldr r4,[addr,#FramebufferInfo.pitch]
  lsl px,#2
  mla r4,py,r4,px
  .unreq px
  .unreq py
  .unreq addr

  addr .req r0
  bl GetBackbufferBase
  teq addr,#0
  beq _panicGraphics

  brush .req r3
  add addr,r4
  ldr brush,=brushColor
  ldr brush,[brush]
  str brush,[addr]
  .unreq brush
  .unreq addr

  pop {r4,pc}

.globl DrawLine
DrawLine:
  push {r4,r5,r6,r7,r8,r9,r10,r11,r12,lr}
  x0 .req r9
  x1 .req r10
  y0 .req r11
  y1 .req r12

  mov x0,r0
  mov x1,r2
  mov y0,r1
  mov y1,r3

  dx .req r4
  dyn .req r5
  sx .req r6
  sy .req r7
  err .req r8

  cmp x0,x1
  subgt dx,x0,x1
  movgt sx,#-1
  suble dx,x1,x0
  movle sx,#1

  cmp y0,y1
  subgt dyn,y1,y0
  movgt sy,#-1
  suble dyn,y0,y1
  movle sy,#1

  add err,dx,dyn
  add x1,sx
  add y1,sy

pixelLoop$:
  teq x0,x1
  teqne y0,y1
  popeq {r4,r5,r6,r7,r8,r9,r10,r11,r12,pc}

  mov r0,x0
  mov r1,y0
  bl DrawPixel

  cmp dyn,err,lsl #1
  addle err,dyn
  addle x0,sx

  cmp dx,err,lsl #1
  addge err,dx
  addge y0,sy

  b pixelLoop$
  .unreq x0
  .unreq x1
  .unreq y0
  .unreq y1
  .unreq dx
  .unreq dyn
  .unreq sx
  .unreq sy
  .unreq err

/*
  params:
    r0: x0
    r1: y0
    r2: x1
    r3: y1
  returns:
    r0: x0
    r1: y0
    r2: x1
    r3: y1
*/
.globl ClipRect
ClipRect:
  push {r4,r5,lr}
  x0 .req r0
  y0 .req r1
  x1 .req r2
  y1 .req r3

  tmp .req r4
  cmp x0,x1
  movhi tmp,x0
  movhi x0,x1
  movhi x1,tmp

  cmp y0,y1
  movhi tmp,y0
  movhi y0,y1
  movhi y1,tmp
  .unreq tmp

  addr .req r4
  width .req r5
  ldr addr,=graphicsAddress
  ldr width,[addr,#FramebufferInfo.w]
  sub width,#1
  cmp x0,width
  movhi x0,width
  cmp x1,width
  movhi x1,width
  .unreq width
  height .req r5
  ldr height,[addr,#FramebufferInfo.h]
  sub height,#1
  cmp y0,height
  movhi y0,height
  cmp y1,height
  movhi y1,height
  .unreq height
  .unreq addr
  .unreq x0
  .unreq y0
  .unreq x1
  .unreq y1

  pop {r4,r5,pc}

.globl DrawRect
DrawRect:
  push {r4,r5,r6,r7,lr}

  x0 .req r0
  y0 .req r1
  x1 .req r2
  y1 .req r3
  bl ClipRect

  x .req r4
  y .req r5
  w .req r6
  h .req r7
  mov x,x0
  mov y,y0
  subs w,x1,x
  pople {r4,r5,r6,r7,pc}
  subs h,y1,y
  pople {r4,r5,r6,r7,pc}
  .unreq x0
  .unreq y0
  .unreq x1
  .unreq y1
 
  bl GetBackbufferBase
  addr .req r2
  mov addr,r0
  pitch .req r3
  ldr r0,=graphicsAddress
  ldr r0,[r0]
  ldr pitch,[r0,#FramebufferInfo.pitch]
  size .req r0
  mov size,#4
  mla addr,x,size,addr  // offset by x position
  mla addr,y,pitch,addr // offset by y position
  .unreq x
  .unreq y
  .unreq size

  color .req r1
  ldr r0,=brushColor
  ldr color,[r0]

rectLoop$:
  mov r0,addr
  i .req r5
  mov i,w
  pixelRow$:
    str color,[r0]
    add r0,#4
    subs i,#1
    bne pixelRow$
  subs h,#1
  addne addr,pitch
  bne rectLoop$
  .unreq color
  .unreq addr
  .unreq pitch
  .unreq w
  .unreq h

  pop {r4,r5,r6,r7,pc}
