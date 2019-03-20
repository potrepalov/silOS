/* share/avr/silOS/vars.S */
/* Copyright Potrepalov I.S.  potrepalov@list.ru */

/* файл с перменными для ассемблерного проекта */
/* операционная система полагает, что секция .bss обнулена */


#include "os.h"


	.section ".noinit"

#if !NO_OS_INIT		; =============================================


	; инициализация переменных выполняется функцией OS_Init
	.section ".noinit"

OS_TSBs:	.global	OS_TSBs
	.space	NumThreads * SizeOfTSB
OS_Vars:	.global	OS_Vars
	.space	OS_Vars_Size


#else /* NO_OS_INIT */	; =============================================


	; инициализация переменных выполняется при старте программы
	.data

OS_TSBs:	.global	OS_TSBs

#if NumThreads > 1
	.rept	NumThreads - 1
#if defined( __BlockingRes )
#if BIG_SLEEP
	.word	0	; SleepCounter
	.byte	0xFF	; BlockingRes
	.space	SizeOfTSB - 3, 0
#else /* BIG_SLEEP */
	.byte	0	; SleepCounter
	.byte	0xFF	; BlockingRes
	.space	SizeOfTSB - 2, 0
#endif /* BIG_SLEEP */
#else /* __BlockingRes */
#if BIG_SLEEP
	.word	1	; SleepCounter
	.space	SizeOfTSB - 2, 0
#else /* BIG_SLEEP */
	.byte	1	; SleepCounter
	.space	SizeOfTSB - 1, 0
#endif /* BIG_SLEEP */
#endif /* __BlockingRes */
	.endr
#endif /* NumThreads > 1 */

LastTSB:
	; OS_TSBs[NumThreads-1]
	.word	0, 0	; SleepCounter, BlockingRes
	.space	SizeOfTSB - 4, 0

OS_Vars:	.global	OS_Vars
	.word	LastTSB		; .CurTSB
	.byte	NumThreads	; .CurTSBindex

#if !NO_STOP_IN_ISR
	.byte	0		; .ThreadFlag
#endif /* NO_STOP_IN_ISR */

#if !defined( OS_Reg )
	.byte	1		; .Flags
#endif /* OS_Reg */

#if !defined( iSPL )
#if __AVR_HAVE_SPH__
	.byte	0		; .SPsave[1]
#endif /* !__AVR_HAVE_SPH__ */
	.byte	0		; .SPsave[0]
#endif /* defined( iSPL ) */


#endif /* NO_OS_INIT */	; =============================================



	.section ".bss"

#if TotalMutexes
OS_Mutexes:	.global	OS_Mutexes
	.space	NumCMutexes+TotalMutexes, 0
#endif

#if NumSignals
OS_Signals:	.global	OS_Signals
	.space	(NumSignals+7)/8, 0
#endif

#if NumSemaphores
OS_Semaphores:	.global	OS_Semaphores
	.space	NumSemaphores, 0
#endif

#if NumTimers
OS_Timers:	.global	OS_Timers
	.space	NumTimers*2, 0
#endif


/* wordset:avr-gcc-os */

/* End of file  vars.S */
