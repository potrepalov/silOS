/* share/avr/silOS/os-internal.h */

/*
 silOS: Short Interrupt Latency OS
 Copyright (C) 2010 Potrepalov I.S.  potrepalov@list.ru

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/


#if !defined( OS_H_INCLUDED )
#error "Include  os/os.h  file instead of this file"
#endif


#if __AVR_ARCH__ >= 100 /* __ATXMEGA__ */
#define __ATXMEGA__	1
#else
#define __ATXMEGA__	0
#endif


#define OS_H_TOSTR( s )	OS_H__TOSTR(s)
#define OS_H__TOSTR( s )	#s



#if __AVR_HAVE_JMP_CALL__
#define _OS_THREAD__JMP	"jmp	"
#else
#define _OS_THREAD__JMP	"rjmp	"
#endif



#if defined( iSREG ) && !__ATXMEGA__
#define iSREG_Stack_Space	0
#else
#define iSREG_Stack_Space	1
#endif

#define OS_SREG_Stack_Space	1	/* size of SREG reg for OS_ISR */

#if __AVR_3_BYTE_PC__
#define RA_Stack_Space		3	/* size of return address */
#else /* !__AVR_3_BYTE_PC__ */
#define RA_Stack_Space		2	/* size of return address */
#endif /* __AVR_3_BYTE_PC__ */

#define OS_wReg_Stack_Space	1


#define ISR_Stack_Top		(ISR_Stack_End - RA_Stack_Space		\
			 - OS_wReg_Stack_Space - iSREG_Stack_Space)


// OS_ISR при переключении стека на стек прерываний всегда восстанавливает
// регистр SREG из стека (из стека прерываний или из стека потока)
#define OS_ISR_Stack_Top	(ISR_Stack_End - RA_Stack_Space		\
			 - OS_wReg_Stack_Space - OS_SREG_Stack_Space)


#if __AVR_HAVE_SPH__
#define ISR_Stack_Fence	(ISR_Stack_End + 0x100)
#else /* !__AVR_HAVE_SPH__ */
#define ISR_Stack_Fence	(ISR_Stack_End)
#endif /* __AVR_HAVE_SPH__ */

#define OS_ISR_Stack_SREG_Pos	OS_ISR_Stack_Top


#if !defined( NumCMutexes )
#define NumCMutexes	0
#endif

#if !defined( TotalMutexes )
#define TotalMutexes	NumCMutexes
#endif

#if !defined( NumEvents )
#define NumEvents	0
#endif

#if !defined( NumSignals )
#define NumSignals	0
#endif

#if !defined( NumSemaphores )
#define NumSemaphores	0
#endif



#if TotalMutexes + NumSignals + NumEvents + NumSemaphores
#define __BlockingRes	1
#else
#define __BlockingRes	0
#endif


#if NO_KILL_IN_ISR
#define KILL_IN_ISR	0
#else
#define KILL_IN_ISR	1
#define PREPARE_IN_ISR	1
#endif

#if NO_PREPARE_IN_ISR
#if !defined( PREPARE_IN_ISR )
#define PREPARE_IN_ISR	0
#endif
#else
#define PREPARE_IN_ISR	1
#define RELEASE_IN_ISR	1
#endif


#undef STOP_IN_ISR
#if KILL_IN_ISR || PREPARE_IN_ISR
#define STOP_IN_ISR	1
#else
#define STOP_IN_ISR	0
#endif


#if NO_RELEASE_IN_ISR
#if !defined( RELEASE_IN_ISR )
#define RELEASE_IN_ISR	0
#endif
#else
#define RELEASE_IN_ISR	1
#endif



#define START_MUTEXES	1
#define START_EVENTS	(START_MUTEXES+TotalMutexes)
#define START_SIGNALS	(START_EVENTS+NumEvents)
#define START_SEMAPHORES	(START_SIGNALS+NumSignals)



#if !defined( __ASSEMBLER__ )


#if BIG_SLEEP

#if __BlockingRes
#define SleepTime_t_MAX	UINT16_MAX
#else /* !__BlockingRes */
#define SleepTime_t_MAX	(UINT16_MAX/2)
#endif /* __BlockingRes */

#else /* !BIG_SLEEP */

#if __BlockingRes
#define SleepTime_t_MAX	RegType_t_MAX
#else /* !__BlockingRes */
#define SleepTime_t_MAX	(RegType_t_MAX/2)
#endif /* __BlockingRes */

#endif /* BIG_SLEEP */



typedef struct tagTSB_t {
	SleepTime_t	SleepCounter;
#if __BlockingRes
	RegType_t	BlockingRes;
#endif

	RegType_t	SaveSPL;
#ifdef __AVR_HAVE_SPH__
	RegType_t	SaveSPH;
#endif /* __AVR_HAVE_SPH__ */

#if defined( RAMPD ) && !defined( NoSaveRAMPD )
	RegType_t	SaveRAMPD;
#endif /* RAMPD */

#if defined( RAMPX ) && !defined( NoSaveRAMPX )
	RegType_t	SaveRAMPX;
#endif /* RAMPX */

#if defined( RAMPY ) && !defined( NoSaveRAMPY )
	RegType_t	SaveRAMPY;
#endif /* RAMPY */

#if defined( RAMPZ ) && !defined( NoSaveRAMPZ )
	RegType_t	SaveRAMPZ;
#endif /* RAMPY */

#if defined( EIND ) && !defined( NoSaveEIND )
	RegType_t	SaveEIND;
#endif /* EIND */

	/* регистры с r24 до r31, а также r0 и r1 сохраняются всегда */
	RegType_t	SaveR0;
	RegType_t	SaveR1;
	RegType_t	SaveR24; /* в этих регистрах находится возвращаемое */
	RegType_t	SaveR25; /* из функций значение */

	RegType_t	SaveR26, SaveR27, SaveR28, SaveR29, SaveR30, SaveR31;

	/* сохранение остальных регистров настраивается макросами */
#if !defined( NoSaveR2 )
	RegType_t	SaveR2;
#endif /* NoSaveR2 */

#if !defined( NoSaveR3 )
	RegType_t	SaveR3;
#endif /* NoSaveR3 */

#if !defined( NoSaveR4 )
	RegType_t	SaveR4;
#endif /* NoSaveR4 */

#if !defined( NoSaveR5 )
	RegType_t	SaveR5;
#endif /* NoSaveR5 */

#if !defined( NoSaveR6 )
	RegType_t	SaveR6;
#endif /* NoSaveR6 */

#if !defined( NoSaveR7 )
	RegType_t	SaveR7;
#endif /* NoSaveR7 */

#if !defined( NoSaveR8 )
	RegType_t	SaveR8;
#endif /* NoSaveR8 */

#if !defined( NoSaveR9 )
	RegType_t	SaveR9;
#endif /* NoSaveR9 */

#if !defined( NoSaveR10 )
	RegType_t	SaveR10;
#endif /* NoSaveR10 */

#if !defined( NoSaveR11 )
	RegType_t	SaveR11;
#endif /* NoSaveR11 */

#if !defined( NoSaveR12 )
	RegType_t	SaveR12;
#endif /* NoSaveR12 */

#if !defined( NoSaveR13 )
	RegType_t	SaveR13;
#endif /* NoSaveR13 */

#if !defined( NoSaveR14 )
	RegType_t	SaveR14;
#endif /* NoSaveR14 */

#if !defined( NoSaveR15 )
	RegType_t	SaveR15;
#endif /* NoSaveR15 */

#if !defined( NoSaveR16 )
	RegType_t	SaveR16;
#endif /* NoSaveR16 */

#if !defined( NoSaveR17 )
	RegType_t	SaveR17;
#endif /* NoSaveR17 */

#if !defined( NoSaveR18 )
	RegType_t	SaveR18;
#endif /* NoSaveR18 */

#if !defined( NoSaveR19 )
	RegType_t	SaveR19;
#endif /* NoSaveR19 */

#if !defined( NoSaveR20 )
	RegType_t	SaveR20;
#endif /* NoSaveR20 */

#if !defined( NoSaveR21 )
	RegType_t	SaveR21;
#endif /* NoSaveR21 */

#if !defined( NoSaveR22 )
	RegType_t	SaveR22;
#endif /* NoSaveR22 */

#if !defined( NoSaveR23 )
	RegType_t	SaveR23;
#endif /* NoSaveR23 */

#if 0
#if defined( RAMPZ ) && !defined( NoSavePAMPZ )
	RegType_t SaveRAMPZ;
#endif /* RAMPZ */
#endif

} TSB_t;  /* typedef struct tagTSB_t { ... } TSB_t; */


typedef struct tagOSvars_t {
	const TSB_t     	* CurTSB;	/* адрес TSB текущего потока */
	const TSBindex_t	CurTSBindex;	/* номер текущего потока */

#if STOP_IN_ISR
	TSBindex_t		ThreadFlag;
#endif /* STOP_IN_ISR */

#if !defined( OS_Reg )
	volatile RegType_t	Flags;
#endif /* OS_Reg */

#if !defined( iSPL )
#if __AVR_HAVE_SPH__
	RegType_t		SPsave[2];
#else /* !__AVR_HAVE_SPH__ */
	RegType_t		SPsave[1];
#endif /* __AVR_HAVE_SPH__ */
#endif /* iSPL */

} OSvars_t;	/* typedef struct tagOSvars_t { ... } OSvars_t; */


extern volatile const TSB_t OS_TSBs[];
extern const OSvars_t OS_Vars;

#if TotalMutexes
extern volatile const TSBindex_t OS_Mutexes[];
#endif

#if NumSignals
extern volatile const unsigned char OS_Signals[];
#endif

#if NumSemaphores
extern volatile const SemaphoreCounter_t OS_Semaphores[];
#endif

#if NumTimers
extern volatile OS_Timer_t OS_Timers[];
#endif






#else /* defined( __ASSEMBLER__ ) */






/* Смещения в структуре TSB */
#define SleepCounter	0

#if BIG_SLEEP
#define __SleepSize	1
#else /* BIG_SLEEP */
#define __SleepSize	0
#endif /* BIG_SLEEP */

#if __BlockingRes
#define BlockingRes	(1 + __SleepSize)
#define SaveSPL		(2 + __SleepSize)
#else /* __BlockingRes */
#define SaveSPL		(1 + __SleepSize)
#endif /* __BlockingRes */

#if __AVR_HAVE_SPH__
#define SaveSPH		(1 + SaveSPL)
#define __Save_SPH	(1 + SaveSPH)
#else /* !__AVR_HAVE_SPH__ */
#define __Save_SPH	(1 + SaveSPL)
#endif /* __AVR_HAVE_SPH__ */

#if defined( RAMPD ) && !defined( NoSaveRAMPD )
#define SaveRAMPD	(__Save_SPH)
#define __Save_RAMPD	(1 + __Save_SPH)
#else /* RAMPD */
#define __Save_RAMPD	(__Save_SPH)
#endif /* RAMPD */

#if defined( RAMPX ) && !defined( NoSaveRAMPX )
#define SaveRAMPX	(__Save_RAMPD)
#define __Save_RAMPX	(1 + __Save_RAMPD)
#else /* RAMPX */
#define __Save_RAMPX	(__Save_RAMPD)
#endif /* RAMPX */

#if defined( RAMPY ) && !defined( NoSaveRAMPY )
#define SaveRAMPY	(__Save_RAMPX)
#define __Save_RAMPY	(1 + __Save_RAMPX)
#else /* RAMPY */
#define __Save_RAMPY	(__Save_RAMPX)
#endif /* RAMPY */

#if defined( RAMPZ ) && !defined( NoSaveRAMPZ )
#define SaveRAMPZ	(__Save_RAMPY)
#define __Save_RAMPZ	(1 + __Save_RAMPY)
#else /* RAMPY */
#define __Save_RAMPZ	(__Save_RAMPY)
#endif /* RAMPY */

#if defined( EIND ) && !defined( NoSaveEIND )
#define SaveEIND	(__Save_RAMPZ)
#define SaveR0		(1 + SaveEIND)
#else /* EIND */
#define SaveR0		(__Save_RAMPZ)
#endif /* EIND */


#define SaveR1	(1 + SaveR0)
#define SaveR24	(2 + SaveR0)
#define SaveR25	(3 + SaveR0)
#define SaveR26	(4 + SaveR0)
#define SaveR27	(5 + SaveR0)
#define SaveR28	(6 + SaveR0)
#define SaveR29	(7 + SaveR0)
#define SaveR30	(8 + SaveR0)
#define SaveR31 (9 + SaveR0)


#if !defined( NoSaveR2 )
#undef SaveR2
#define SaveR2 (SaveR31+1)
#define __SaveR2	1
#else
#define __SaveR2	0
#endif /* NoSaveR2 */

#if !defined( NoSaveR3 )
#undef SaveR3
#define SaveR3 (SaveR31+1+__SaveR2)
#define __SaveR3	1
#else
#define __SaveR3	0
#endif /* NoSaveR3 */

#if !defined( NoSaveR4 )
#undef SaveR4
#define SaveR4 (SaveR31+1+__SaveR2+__SaveR3)
#define __SaveR4	1
#else
#define __SaveR4	0
#endif /* NoSaveR4 */

#if !defined( NoSaveR5 )
#undef SaveR5
#define SaveR5 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4)
#define __SaveR5	1
#else
#define __SaveR5	0
#endif /* NoSaveR5 */

#if !defined( NoSaveR6 )
#undef SaveR6
#define SaveR6 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5)
#define __SaveR6	1
#else
#define __SaveR6	0
#endif /* NoSaveR6 */

#if !defined( NoSaveR7 )
#undef SaveR7
#define SaveR7 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6)
#define __SaveR7	1
#else
#define __SaveR7	0
#endif /* NoSaveR7 */

#if !defined( NoSaveR8 )
#undef SaveR8
#define SaveR8 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7)
#define __SaveR8	1
#else
#define __SaveR8	0
#endif /* NoSaveR8 */

#if !defined( NoSaveR9 )
#undef SaveR9
#define SaveR9 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8)
#define __SaveR9	1
#else
#define __SaveR9	0
#endif /* NoSaveR9 */

#if !defined( NoSaveR10 )
#undef SaveR10
#define SaveR10 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9)
#define __SaveR10	1
#else
#define __SaveR10	0
#endif /* NoSaveR10 */

#if !defined( NoSaveR11 )
#undef SaveR11
#define SaveR11 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10)
#define __SaveR11	1
#else
#define __SaveR11	0
#endif /* NoSaveR11 */

#if !defined( NoSaveR12 )
#undef SaveR12
#define SaveR12 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11)
#define __SaveR12	1
#else
#define __SaveR12	0
#endif /* NoSaveR12 */

#if !defined( NoSaveR13 )
#undef SaveR13
#define SaveR13 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12)
#define __SaveR13	1
#else
#define __SaveR13	0
#endif /* NoSaveR13 */

#if !defined( NoSaveR14 )
#undef SaveR14
#define SaveR14 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12 \
	+__SaveR13)
#define __SaveR14	1
#else
#define __SaveR14	0
#endif /* NoSaveR14 */

#if !defined( NoSaveR15 )
#undef SaveR15
#define SaveR15 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12 \
	+__SaveR13+__SaveR14)
#define __SaveR15	1
#else
#define __SaveR15	0
#endif /* NoSaveR15 */

#if !defined( NoSaveR16 )
#undef SaveR16
#define SaveR16 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12 \
	+__SaveR13+__SaveR14+__SaveR15)
#define __SaveR16	1
#else
#define __SaveR16	0
#endif /* NoSaveR16 */

#if !defined( NoSaveR17 )
#undef SaveR17
#define SaveR17 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12 \
	+__SaveR13+__SaveR14+__SaveR15+__SaveR16)
#define __SaveR17	1
#else
#define __SaveR17	0
#endif /* NoSaveR17 */

#if !defined( NoSaveR18 )
#undef SaveR18
#define SaveR18 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12 \
	+__SaveR13+__SaveR14+__SaveR15+__SaveR16+__SaveR17)
#define __SaveR18	1
#else
#define __SaveR18	0
#endif /* NoSaveR18 */

#if !defined( NoSaveR19 )
#undef SaveR19
#define SaveR19 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12 \
	+__SaveR13+__SaveR14+__SaveR15+__SaveR16+__SaveR17+__SaveR18)
#define __SaveR19	1
#else
#define __SaveR19	0
#endif /* NoSaveR19 */

#if !defined( NoSaveR20 )
#undef SaveR20
#define SaveR20 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12 \
	+__SaveR13+__SaveR14+__SaveR15+__SaveR16+__SaveR17+__SaveR18 \
	+__SaveR19)
#define __SaveR20	1
#else
#define __SaveR20	0
#endif /* NoSaveR20 */

#if !defined( NoSaveR21 )
#undef SaveR21
#define SaveR21 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12 \
	+__SaveR13+__SaveR14+__SaveR15+__SaveR16+__SaveR17+__SaveR18 \
	+__SaveR19+__SaveR20)
#define __SaveR21	1
#else
#define __SaveR21	0
#endif /* NoSaveR21 */

#if !defined( NoSaveR22 )
#undef SaveR22
#define SaveR22 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12 \
	+__SaveR13+__SaveR14+__SaveR15+__SaveR16+__SaveR17+__SaveR18 \
	+__SaveR19+__SaveR20+__SaveR21)
#define __SaveR22	1
#else
#define __SaveR22	0
#endif /* NoSaveR22 */

#if !defined( NoSaveR23 )
#undef SaveR23
#define SaveR23 (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12 \
	+__SaveR13+__SaveR14+__SaveR15+__SaveR16+__SaveR17+__SaveR18 \
	+__SaveR19+__SaveR20+__SaveR21+__SaveR22)
#define __SaveR23	1
#else
#define __SaveR23	0
#endif /* NoSaveR23 */


#define SizeOfTSB (SaveR31+1+__SaveR2+__SaveR3+__SaveR4+__SaveR5+__SaveR6 \
	+__SaveR7 +__SaveR8 +__SaveR9 +__SaveR10+__SaveR11+__SaveR12 \
	+__SaveR13+__SaveR14+__SaveR15+__SaveR16+__SaveR17+__SaveR18 \
	+__SaveR19+__SaveR20+__SaveR21+__SaveR22+__SaveR23)





	.struct	0
OS_CurTSB_off:		.struct	OS_CurTSB_off + 2
OS_CurTSBindex_off:	.struct	OS_CurTSBindex_off + 1

#if STOP_IN_ISR
OS_ThreadInProcess_off:	.struct OS_ThreadInProcess_off + 1
#endif

#if !defined( OS_Reg )
OS_Flags_off:		.struct OS_Flags_off + 1
#endif

#if !defined( iSPL )
#if __AVR_HAVE_SPH__
ISR_SPsave_off:		.struct	ISR_SPsave_off + 2
#else /* !__AVR_HAVE_SPH__ */
ISR_SPsave_off:		.struct	ISR_SPsave_off + 1
#endif /* __AVR_HAVE_SPH__ */
#endif /* !defined( iSPL ) */

OS_Vars_Size:		.struct	OS_Vars_Size + 0



#define OS_CurTSB	(OS_Vars+OS_CurTSB_off)
#define OS_CurTSBindex	(OS_Vars+OS_CurTSBindex_off)

#if STOP_IN_ISR
#define	OS_ThreadInProcess	(OS_Vars+OS_ThreadInProcess_off)
#endif /* STOP_IN_ISR */

#if !defined( OS_Reg )
#define OS_Flags	(OS_Vars+OS_Flags_off)
#endif /* OS_Reg */

#if !defined( iSPL )
#define ISR_SPsave	(OS_Vars+ISR_SPsave_off)
#endif /* iSPL */




#endif /* defined( __ASSEMBLER__ ) */






#if SizeOfTSB % 128 == 0
#define LONG_TSBS	(NumThreads > 2)
#elif SizeOfTSB % 64 == 0
#define LONG_TSBS	(NumThreads > 4)
#elif SizeOfTSB % 32 == 0
#define LONG_TSBS	(NumThreads > 8)
#elif SizeOfTSB % 16 == 0
#define LONG_TSBS	(NumThreads > 16)
#elif SizeOfTSB % 8 == 0
#define LONG_TSBS	(NumThreads > 32)
#elif SizeOfTSB % 4 == 0
#define LONG_TSBS	(NumThreads > 64)
#elif SizeOfTSB % 2 == 0
#define LONG_TSBS	(NumThreads > 128)
#else
#define LONG_TSBS	0
#endif





#if TotalMutexes + NumSignals + NumEvents + NumSemaphores >= 255
#error Too many resources (Mutexes, Signals, Events, Semaphores)
#endif

#if NumThreads > 1
#ifndef StackSize2
#error No StackSize2
#endif
#else
#undef StackSize2
#define StackSize2	0
#endif

#if NumThreads > 2
#ifndef StackSize3
#error No StackSize3
#endif
#else
#undef StackSize3
#define StackSize3	0
#endif

#if NumThreads > 3
#ifndef StackSize4
#error No StackSize4
#endif
#else
#undef StackSize4
#define StackSize4	0
#endif

#if NumThreads > 4
#ifndef StackSize5
#error No StackSize5
#endif
#else
#undef StackSize5
#define StackSize5	0
#endif

#if NumThreads > 5
#ifndef StackSize6
#error No StackSize6
#endif
#else
#undef StackSize6
#define StackSize6	0
#endif

#if NumThreads > 6
#ifndef StackSize7
#error No StackSize7
#endif
#else
#undef StackSize7
#define StackSize7	0
#endif

#if NumThreads > 7
#ifndef StackSize8
#error No StackSize8
#endif
#else
#undef StackSize8
#define StackSize8	0
#endif

#if NumThreads > 8
#ifndef StackSize9
#error No StackSize9
#endif
#else
#undef StackSize9
#define StackSize9	0
#endif

#if NumThreads > 9
#ifndef StackSize10
#error No StackSize10
#endif
#else
#undef StackSize10
#define StackSize10	0
#endif

#if NumThreads > 10
#ifndef StackSize11
#error No StackSize11
#endif
#else
#undef StackSize11
#define StackSize11	0
#endif

#if NumThreads > 11
#ifndef StackSize12
#error No StackSize12
#endif
#else
#undef StackSize12
#define StackSize12	0
#endif

#if NumThreads > 12
#ifndef StackSize13
#error No StackSize13
#endif
#else
#undef StackSize13
#define StackSize13	0
#endif

#if NumThreads > 13
#ifndef StackSize14
#error No StackSize14
#endif
#else
#undef StackSize14
#define StackSize14	0
#endif

#if NumThreads > 14
#ifndef StackSize15
#error No StackSize15
#endif
#else
#undef StackSize15
#define StackSize15	0
#endif

#if NumThreads > 15
#ifndef StackSize16
#error No StackSize16
#endif
#else
#undef StackSize16
#define StackSize16	0
#endif

#if NumThreads > 16
#error Too many threads.  See os-internal.h
#endif


#if defined( __ASSEMBLER__ )
#include "os-internal.inc"
#endif /* __ASSEMBLER */


/* wordset:avr-gcc-os */

/* End of file  os-internal.h */
