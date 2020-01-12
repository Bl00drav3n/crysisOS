.globl GetGpioAddress
GetGpioAddress:
  ldr r0,=0x20200000
  mov pc,lr

.globl SetGpioFunction
SetGpioFunction:
  cmp r0,#53   // PIN0-PIN53
  cmpls r1,#7  // FNC0-FNC7
  movhi pc,lr  // return if out of range
  push {lr}
  mov r2,r0
  bl GetGpioAddress
  functionLoop$: // r0=GPFSELn address
    cmp r2,#9
    subhi r2,#10
    addhi r0,#4
    bhi functionLoop$
  add r2, r2,lsl #1 // r2=3*r2 (3bits per pin = 8 functions)
  lsl r1,r2         // r1=f (function select for specified pin)
  ldr r2,[r0]       // r2=FSELn
  bic r2,r1         // r2=FSELn & ~f
  orr r1,r2         // r1=(FSELn & ~f) | f
  str r1,[r0]       // update GPFSELn
  pop {pc}

.globl SetGpio
SetGpio:
  pinNum .req r0
  pinVal .req r1
  cmp pinNum,#53
  movhi pc,lr // return if out of range
  push {lr}
  mov r2,pinNum
  .unreq pinNum
  pinNum .req r2
  bl GetGpioAddress
  gpioAddr .req r0
  pinBank .req r3
  lsr pinBank,pinNum,#5 // pinBank = pinNum / 32
  lsl pinBank,#2        // pinBank = 4 * pinBank
  add gpioAddr,pinBank
  .unreq pinBank
  and pinNum,#0x1F      // bottom 5 bits
  setBit .req r3
  mov setBit,#1
  lsl setBit,pinNum     // set bit for PINn
  .unreq pinNum
  teq pinVal,#0
  .unreq pinVal
  streq setBit,[gpioAddr,#0x28] // GPCLRn
  strne setBit,[gpioAddr,#0x1C] // GPSETn
  .unreq setBit
  .unreq gpioAddr
  pop {pc}

.globl GpioWriteOutput8
GpioWriteOutput8:
  push {r4,r5,r6,lr}
  n .req r4
  addr .req r5
  cnt .req r6
  and n,r0,#0x000000FF
  ldr addr,=GpioPins
  mov cnt,#0
  loop1$:
    ldr r0,[addr,cnt]
    mov r1,#1
    bl SetGpioFunction
    ldr r0,[addr,cnt]
    and r1,n,#1
    bl SetGpio
    lsr n,#1
    add cnt,#4
    teq cnt,#32
    bne loop1$
  pop {r4,r5,r6,pc}

.section .data
.align 2
GpioPins:
  .int 17
  .int 18
  .int 27
  .int 22
  .int 23
  .int 24
  .int 25
  .int 4
