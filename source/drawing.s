.section .data
.align 2
brushColor:
  .int 0xFFFFFFFF
.align 2
graphicsAddress:
  .int 0

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
  ldr width,[addr,#0x08]
  sub width,#1
  cmp px,width
  pophi {r4,pc}
  .unreq width

  height .req r3
  ldr height,[addr,#0x0C]
  sub height,#1
  cmp py,height
  pophi {r4,pc}
  .unreq height

  ldr r4,[addr,#0x10]
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
