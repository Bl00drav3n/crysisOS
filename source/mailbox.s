/*
  https://github.com/raspberrypi/firmware/wiki/Mailboxes
  https://github.com/raspberrypi/firmware/wiki/Accessing-mailboxes
  https://github.com/raspberrypi/linux/blob/rpi-4.19.y/drivers/mailbox/mailbox.c
  https://github.com/raspberrypi/linux/blob/rpi-4.19.y/drivers/mailbox/bcm2835-mailbox.c

  MB 0: communication  VC -> ARM
  MB 1: communication ARM -> VC
  The ARM should never write MB 0 or read MB 1!

  Mailbox  Read/Write  Peek  Sender  Status  Config
        0       0x00   0x10    0x14    0x18    0x1c
        1       0x20   0x30    0x34    0x38    0x3c

  Mailbox 0 defines the following channels:
  0: Power management
  1: Framebuffer
  2: Virtual UART
  3: VCHIQ
  4: LEDs
  5: Buttons
  6: Touch screen
  7:
  8: Property tags (ARM -> VC)
  9: Property tags (VC -> ARM)

  Addresses sent as messages must be bus addresses as seen by the VC (except for property tags)!
  l2cache  VC-MMU mapping
  enabled  0x40000000
  disabled 0xC0000000

  Property tags require physical addresses.

  NOTE: If caching is enabled, data chache invalidation/flushing may be required around
        mailbox accesses!

  The following instructions are taken from 
  http://infocenter.arm.com/help/topic/com.arm.doc.ddi0360f/I1014942.html. 
  Any unneeded register can be used in the following example instead of r3.

  mov r3, #0				# The read register Should Be Zero before the call
  mcr p15, 0, r3, C7, C6, 0		# Invalidate Entire Data Cache
  mcr p15, 0, r3, c7, c10, 0		# Clean Entire Data Cache
  mcr p15, 0, r3, c7, c14, 0		# Clean and Invalidate Entire Data Cache
  mcr p15, 0, r3, c7, c10, 4		# Data Synchronization Barrier
  mcr p15, 0, r3, c7, c10, 5		# Data Memory Barrier
  The following procedure is used sometimes around physical device accesses.

  MemoryBarrier:
    mcr p15, 0, r3, c7, c5, 0	# Invalidate instruction cache
    mcr p15, 0, r3, c7, c5, 6	# Invalidate BTB
    mcr p15, 0, r3, c7, c10, 4	# Drain write buffer
    mcr p15, 0, r3, c7, c5, 4	# Prefetch flush
    mov pc, lr					# Return
*/

.globl GetMailboxBase
GetMailboxBase:
  ldr r0,=0x2000B880
  mov pc,lr

.globl MailboxWrite
MailboxWrite:
  tst r0,#0x0F
  movne pc,lr
  cmp r1,#0x0F
  movhi pc,lr
  channel .req r1
  value .req r2
  mov value,r0
  push {lr}
  bl GetMailboxBase
  mailbox .req r0
  wait1$:
    status .req r3
    ldr status,[mailbox,#0x18]  // load status register
    tst status,#0x80000000      // wait until mailbox not full
    .unreq status
    bne wait1$
  orr value,channel
  .unreq channel
  str value,[mailbox,#0x20] // write to mailbox 1
  .unreq value
  .unreq mailbox
  pop {pc}

.globl MailboxRead
MailboxRead:
  cmp r0,#0x0F
  movhi pc,lr
  channel .req r1
  mov channel,r0
  push {lr}
  bl GetMailboxBase
  mailbox .req r0
  rightmail$:
    wait2$:
      status .req r2
      ldr status,[mailbox,#0x18] // load status
      tst status,#0x40000000     // poll msg
      .unreq status
      bne wait2$
    mail .req r2
    ldr mail,[mailbox,#0x00]     // read from mailbox 0
    inchan .req r3
    and inchan,mail,#0x0F
    teq inchan,channel           // check if desired channel
    .unreq inchan
    bne rightmail$
    .unreq mailbox
    .unreq channel
  and r0,mail,#0xFFFFFFF0        // mask out channel bits from msg
  .unreq mail
  pop {pc}
