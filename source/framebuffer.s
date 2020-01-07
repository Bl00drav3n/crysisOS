.section .data
.align 4
.globl FrameBufferInfo
FrameBufferInfo:
  .int 0 // 0x00 physical width
  .int 0 // 0x04 physical height
  .int 0 // 0x08 virtual width
  .int 0 // 0x0C virtual height
  .int 0 // 0x10 pitch [filled by VC]
  .int 0 // 0x14 bit depth
  .int 0 // 0x18 x-offset
  .int 0 // 0x1C y-offset
  .int 0 // 0x20 pointer [filled by VC]
  .int 0 // 0x24 size [filled by VC]
FramebufferDesc:
  .int 0 // 0x00 Backbuffer id (0 or 1)
  .int 0 // 0x04 addr of buffer 0
  .int 0 // 0x08 addr of buffer 1

.section .text
.globl InitialiseFramebuffer
// result: r0 = address of fb memory
InitialiseFramebuffer:
  width .req r0
  height .req r1
  depth .req r2
  cmp width,#4096
  cmpls height,#4096
  cmpls depth,#32
  movhi r0,#0
  movhi pc,lr

  push {r4,lr}
  height2 .req r3
  mov height2,height,lsl #1 // need twice as much physical storage for double buffering
  fbInfoAddr .req r4
  ldr fbInfoAddr,=FrameBufferInfo
  str width,[fbInfoAddr,#0x00]
  str height2,[fbInfoAddr,#0x04]
  str width,[fbInfoAddr,#0x08]
  str height,[fbInfoAddr,#0x0C]
  str depth,[fbInfoAddr,#0x14]
  .unreq width
  .unreq height
  .unreq height2
  .unreq depth

  mov r0,fbInfoAddr
  add r0,#0x40000000  // map physical to correct VC bus address (assuming L2cache is enabled)
  mov r1,#1           // channel 1 = framebuffer
  bl MailboxWrite     // send framebuffer request
  mov r0,#1
  bl MailboxRead      // nonzero result means an error occured
  teq r0,#0
  movne r0,#0
  popne {r4,pc}

  bufId .req r0
  offset .req r1
  desc .req r2
  ldr desc,=FramebufferDesc
  mov bufId,#1
  str bufId,[desc]
  .unreq bufId
  pointer .req r0
  ldr pointer,[fbInfoAddr,#0x20]
  str pointer,[desc,#0x04]
  ldr offset,[fbInfoAddr,#0x10]
  ldr r3,[fbInfoAddr,#0x04]
  mul offset,r3
  ldr r3,[fbInfoAddr,#0x14]
  lsr r3,#3
  mul offset,r3
  add pointer,offset
  str pointer,[desc,#0x08]
  .unreq pointer
  .unreq offset
  .unreq desc

  mov r0,fbInfoAddr
  pop {r4,pc}
  .unreq fbInfoAddr

.globl GetBackbufferBase
GetBackbufferBase:
  ldr r1,=FramebufferDesc
  mov r2,#0x04
  ldr r0,[r1]
  teq r0,#0
  lsleq r2,#1
  add r2,r1
  ldr r0,[r2]
  mov pc,lr

.globl SwapBuffers
SwapBuffers:
  ldr r1,=FramebufferDesc
  ldr r0,[r1]
  eor r0,#1
  and r0,#1
  str r0,[r1]
  mov pc,lr
  // TODO: send virtual y offset to VC!
