// NOTE: Functions only use register r0! 

.globl MemoryBarrier
MemoryBarrier:
  mov r0,#0
	mcr p15,0,r0,c7,c10,#5
  mov pc,lr

.globl DataSynchronizationBarrier
DataSynchronizationBarrier:
  mov r0,#0
  mcr p15,#0,r0,c7,c10,#4
  mov pc,lr

.globl FlushPrefetchBuffer
FlushPrefetchBuffer:
  mov r0,#0
  mcr p15,#0,r0,c7,c5,#4
  mov pc,lr

.globl FlushEntireBranchTargetCache
FlushEntireBranchTargetCache:
  mov r0,#0
  mcr p15,#0,r0,c7,c5,#6
  mov pc,lr

.globl InvalidateEntireDataCache
InvalidateEntireDataCache:
  mov r0,#0
  mcr p15,#0,r0,c7, c6,#0
  mov pc,lr

.globl CleanEntireDataCache
CleanEntireDataCache:
  mov r0,#0
  mcr p15,#0,r0,c7,c10,#0
  mov pc,lr

.globl CleanAndInvalidateEntireDataCache
CleanAndInvalidateEntireDataCache:
  mov r0,#0
  mcr p15,#0,r0,c7,c14,#0
  mov pc,lr

.globl ReadWriteBarrier
ReadWriteBarrier:
  mov r0,#0
  mcr p15,#0,r0,c7,c14,#0	// Clean and Invalidate Entire Data Cache
  mcr p15,#0,r0,c7,c10,#4	// Data Synchronization Barrier
  mcr p15,#0,r0,c7,c10,#5	// Data Memory Barrier
  mov pc,lr
