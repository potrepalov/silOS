/* share/avr/silOS/os.h */

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


#ifndef OS_H_INCLUDED
#define OS_H_INCLUDED


#define OS_VERSION_LO	0
#define OS_VERSION_HI	2
#define OS_VERSION	(OS_VERSION_HI*100 + OS_VERSION_LO)


#include <avr/io.h>
#include "config.h"


#if defined( __ASSEMBLER__ )


#include "os-internal.h"
#include "os.inc"

#define msToTicks(ms)		( (TicksPerSecond*ms) / 1000 )
#define TicksToMS(ticks)	( ((1000*(ticks))+(TicksPerSecond)/2)	\
					/ (TicksPerSecond) )


#else /* !__ASSEMBLER__ */


#define msToTicks(ms)		( ((unsigned long)TicksPerSecond*ms) / 1000 )
#define TicksToMS(ticks)	( ((1000UL*(ticks))+(TicksPerSecond)/2)	\
					/ (TicksPerSecond) )


#include <stdint.h>


#if !defined( RegType_t )
#define RegType_t	uint8_t
#define RegType_t_MAX	UINT8_MAX
#endif /* RegType_t */

typedef RegType_t  TSBindex_t;
typedef RegType_t  Mutex_t;
typedef RegType_t  Event_t;
typedef RegType_t  Signal_t;
typedef RegType_t  Semaphore_t;

typedef RegType_t  SemaphoreCounter_t;


#if BIG_SLEEP
typedef uint16_t   SleepTime_t;
#else /* !BIG_SLEEP */
typedef RegType_t  SleepTime_t;
#endif /* BIG_SLEEP */



#include "os-internal.h"



void	OS_Init( void );

void      Scheduler_Lock( void );
void      Scheduler_Unlock( void );
RegType_t Scheduler_IsLocked( void );



#if KILL_IN_ISR || PREPARE_IN_ISR


typedef void (*THREAD_PTR)( intptr_t, ... );
#define DECLARE_THREAD( name, var )  void name ( var, ...) NAKED


#define THREAD( name, var )						\
	void name ( var, ... ) NAKED;	 				\
	static void _silOS_Thread_ ## name( var ) NORETURN USED OS_TASK; \
	/* грязный хак для установки регистра r1 в ноль */		\
	/* и экономии 2 байтов ОЗУ в каждом потоке */			\
	void name ( var, ... )						\
	{ asm volatile( "clr r1\n"					\
		"pop	r24\n"						\
		"pop	r25\n"						\
		 _OS_THREAD__JMP  OS_H_TOSTR( _silOS_Thread_ ## name )	\
		: /* no outputs */ : /* no inputs */ );			\
	}								\
	static void _silOS_Thread_ ## name ( var )


#else /* !KILL_IN_ISR && !PREPARE_IN_ISR */


typedef void (*THREAD_PTR)( intptr_t );
#define DECLARE_THREAD( name, var )	void name ( var ) NORETURN OS_TASK
#define THREAD( name, var )		void name ( var ) NORETURN OS_TASK; \
					void name ( var )


#endif /* KILL_IN_ISR || PREPARE_IN_ISR */



TSBindex_t  Thread_Prepare( TSBindex_t, THREAD_PTR, intptr_t );
TSBindex_t  Thread_Activate( TSBindex_t );
TSBindex_t  Thread_Kill( TSBindex_t );
//TSBindex_t Thread_Suspend( TSBindex_t );
//RegType_t  Thread_State( TSBindex_t );

void       Suspend( void );
RegType_t  Suspend_r( RegType_t );
intptr_t   Suspend_w( intptr_t );
RegType_t  Sleep( SleepTime_t );
void       Stop( void ) NORETURN;


TSBindex_t  Mutex_Owner( Mutex_t );
RegType_t   Mutex_Release( Mutex_t );
RegType_t   Mutex_Get( Mutex_t );
RegType_t   Mutex_TryGet( Mutex_t );
RegType_t   Mutex_GetWithTimeout( Mutex_t, SleepTime_t );


SemaphoreCounter_t  Semaphore_State( Semaphore_t );
SemaphoreCounter_t  Semaphore_Up( Semaphore_t );
RegType_t  Semaphore_Down( Semaphore_t );
RegType_t  Semaphore_TryDown( Semaphore_t );
RegType_t  Semaphore_DownWithTimeout( Semaphore_t, SleepTime_t );

#define Semaphore_Post		Semaphore_Up
#define Semaphore_Pend		Semaphore_Down
#define Semaphore_TryPend	Semaphore_TryDown
#define Semaphore_PendWithTimeout	Semaphore_DownWithTimeout

#define Semaphore_Open		Semaphore_Up
#define Semaphore_Close		Semaphore_Down
#define Semaphore_TryClose	Semaphore_TryDown
#define Semaphore_CloseWithTimeout	Semaphore_DownWithTimeout


#define INIT_SEMAPHORE(sem,val)						\
	void _silOS_init_sem_ ## sem ( void ) OS_INIT_SEC NAKED USED; 	\
	void _silOS_init_sem_ ## sem ( void )				\
	{ ((SemaphoreCounter_t*)OS_Semaphores)[(sem)-1] = (val); }

#define SET_SEMAPHORE(sem,val)						\
	do { ((SemaphoreCounter_t*)OS_Semaphores)[(sem)-1] = (val); }	\
	while (0)

#define Semaphore_State(sem) (0, OS_Semaphores[(sem)-1])


RegType_t  Signal_IsSet( Signal_t );
void       Signal_Reset( Signal_t );
RegType_t  Signal_Set( Signal_t );
RegType_t  Signal_Set_One( Signal_t );
RegType_t  Signal_Wait( Signal_t );
RegType_t  Signal_WaitWithTimeout( Signal_t, SleepTime_t );


#define INIT_SIGNAL(sig,val)	OS_INIT_SECTION NAKED USED		\
	void _silOS_init_sig_ ## sig ( void ) 				\
	{								\
	  if ( val ) {							\
		unsigned char s = (sig)-1;				\
		((unsigned char*)OS_Signals)[s/8] |= 1 << (s&7);	\
	  }								\
	}

#define RESET_SIGNAL(sig) do {						\
		unsigned char ss = SREG;				\
		unsigned char s = (sig)-1;				\
		cli();							\
		((unsigned char*)OS_Signals)[s/8] &= ~(1 << (s&7));	\
		SREG = ss;						\
	} while (0)


RegType_t  Event_Occur( Event_t );
RegType_t  Event_Occur_One( Event_t );
RegType_t  Event_Watch( Event_t );
RegType_t  Event_WatchWithTimeout( Event_t, SleepTime_t );


#define OS_CurTSB		OS_Vars.CurTSB
#define OS_CurTSBindex		OS_Vars.CurTSBindex
#define OS_CurThread		OS_CurTSBindex
#define OS_CurThreadIndex	OS_CurTSBindex


#if NumTimers

#define OS_Timer_Set( timer, val )		\
	do {					\
		unsigned char s = SREG;		\
		cli();				\
		OS_Timers[(timer)-1] = val;	\
		SREG = s;			\
	} while (0)

#define OS_Timer_Get( timer )			\
	({	unsigned char s = SREG;		\
		OS_Timer_t v;			\
		cli();				\
		v = OS_Timers[(timer)-1];	\
		SREG = s;			\
		v;				\
	})

#define OS_Timer_Reset( timer )	OS_Timer_Set( (timer), 0 )

#endif /* NumTimers */


#endif /* __ASSEMBLER__ */


#endif /* OS_H_INCLUDED */


/* wordset:avr-gcc-os */

/* End of file  os.h */
