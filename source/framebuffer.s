.section .data
.align 4
FramebufferDesc:
  .int 0 // 0x00 Backbuffer id (0 or 1)

.align 4
.globl FramebufferInfo
FramebufferInfo:
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
  .int 0 // padding (?)
  .int 0
  .int 0
  .int 0

.align 4
MBVbufMsg:
  .int 0    // 0x00 buffer size
  .int 0    // 0x04 request/response code
MBVbufMsgTag:
  .int 0    // 0x00 tag
  .int 0    // 0x04 value buffer size
  .int 0    // 0x08 request/response code
  .int 0    // 0x0C offset x or width
  .int 0    // 0x10 offset y or height
  .int 0    // 0x14 end tag

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
  ldr fbInfoAddr,=FramebufferInfo
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
  desc .req r1
  ldr desc,=FramebufferDesc
  mov bufId,#1
  str bufId,[desc]
  .unreq bufId
  .unreq desc

  mov r0,fbInfoAddr
  .unreq fbInfoAddr

  pop {r4,pc}

.globl GetBackbufferBase
GetBackbufferBase:
  // if backbuffer = 0, render to buffer0, display buffer1 and vice versa if backbuffer = 1
  pointer .req r0
  fbInfoAddr .req r1
  fbDescAddr .req r2
  ldr fbInfoAddr,=FramebufferInfo
  ldr pointer,[fbInfoAddr,#0x20]
  ldr fbDescAddr,=FramebufferDesc
  ldr r2,[fbDescAddr]
  .unreq fbDescAddr
  teq r2,#0
  moveq pc,lr

  pitch .req r2
  vheight .req r3
  ldr vheight,[fbInfoAddr,#0x0C]
  ldr pitch,[fbInfoAddr,#0x10]
  .unreq fbInfoAddr
  mul r2,vheight,pitch
  .unreq pitch
  .unreq vheight
  add pointer,r2
  .unreq pointer
  mov pc,lr

/*
  params:
    r0: framebuffer info base address
  returns:
    r0: virtual framebuffer height
*/
GetFramebufferHeight:
  fbInfoAddr .req r0
  ldr r0,[fbInfoAddr,#0x0C]
  mov pc,lr

/*
  params:
    r0: tag
    r1: width/x
    r2: height/y
  returns:
    r0: nonzero on error
*/
.globl MBSendVbufMsg
MBSendVbufMsg:
  push {r0-r2,r4,lr}
  /*
    TODO: check tags!

    0x00040004 get virtual width/height
    0x00044004 test virtual width/height
    0x00048004 set virtual width/height
    0x00040009 get virtual offset
    0x00044009 test virtual offset
    0x00048009 set virtual offset

    00000000 00000100 00000000 00000100
    00000000 00000100 00000100 00000100
    00000000 00000100 00001000 00000100
    00000000 00000100 00000000 00001001
    00000000 00000100 00000100 00001001
    00000000 00000100 00001000 00001001
  */

  msgPtr .req r4
  ldr msgPtr,=MBVbufMsg
  mov r0,#0x20          // msg size: 32 bytes
  mov r1,#0x00          // msg type: request
  stmia msgPtr!,{r0,r1} // update message
  pop {r1-r3}
  mov r0,r1
  mov r1,#0x08
  stmia msgPtr!,{r0-r3} // update tag request
  mov r0,#0
  str r0,[msgPtr]       // end tag
  .unreq msgPtr

  ldr r0,=MBVbufMsg
  add r0,#0x40000000 // map to bus address assuming L2 cache is on
  mov r1,#8          // channel 8: property tags ARM -> VC
  bl MailboxWrite
  mov r0,#8
  bl MailboxRead
  ldr r0,=MBVbufMsg
  ldr r0,[r0,#0x04]
  sub r0,#0x80000000

  pop {r4,pc}

/*
  params:
    r0: backbuffer id
  returns:
    r0: frontbuffer virtual y offset in pixels
*/
GetFrontbufferVirtualOffset:
  push {lr}
  teq r0,#0
  movne r0,#0 // if backbuffer id = 1 => frontbuffer id = 0 and offset = 0x0000
  popne {pc}
  ldr r0,=FramebufferInfo
  bl GetFramebufferHeight
  pop {pc}

.globl SwapBuffers
SwapBuffers:
  push {lr}
  backbuffer .req r0
  fbDescAddr .req r1
  ldr fbDescAddr,=FramebufferDesc
  ldr backbuffer,[fbDescAddr]
  mov r2,#1
  sub backbuffer,r2,backbuffer
  str backbuffer,[fbDescAddr]
  .unreq backbuffer
  .unreq fbDescAddr
  // TODO: TEST
  pop {pc}
  
  bl GetFrontbufferVirtualOffset
  tag .req r0
  xoffset .req r1
  yoffset .req r2
  mov yoffset,r0
  ldr tag,=0x00048009 // set virtual offset
  //ldr r0,=0x00040009 // get virtual offset
  //ldr r0,=0x00044009 // test virtual offset
  mov xoffset,#0
  bl MBSendVbufMsg
  teq r0,#0
  bne _panicVbufMsg
  .unreq xoffset
  .unreq yoffset
  .unreq tag

  pop {pc}
