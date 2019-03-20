/* share/avr/silOS/vars.c */

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


#include "os.h"

//         const unsigned char     OS_ISR_Stack[ISR_StackSize]	NOINIT;


#if !NO_OS_INIT


volatile const TSB_t             OS_TSBs[NumThreads]		NOINIT;
         const OSvars_t          OS_Vars  			NOINIT;


#else /* NO_OS_INIT */


volatile const TSB_t             OS_TSBs[NumThreads] =
	{
#if NumThreads > 1
#if __BlockingRes
	  [0 ... NumThreads-2].BlockingRes = 0xFF
#else /* __BlockingRes */
	  [0 ... NumThreads-2].SleepCounter = 1
#endif /* __BlockingRes */
#endif /* NumThreads > 1 */
	};

         const OSvars_t          OS_Vars =
	{ .CurTSB = (const TSB_t*)&OS_TSBs[NumThreads-1],
	  .CurTSBindex = NumThreads,
#if !defined( OS_Reg )
	  .Flags = 1
#endif /* OS_Reg */
	};


#endif /* NO_OS_INIT */


#if TotalMutexes
volatile const TSBindex_t          OS_Mutexes[NumCMutexes+TotalMutexes];
#endif

#if NumSignals
volatile const unsigned char       OS_Signals[(NumSignals+7)/8];
#endif

#if NumSemaphores
volatile const SemaphoreCounter_t  OS_Semaphores[NumSemaphores];
#endif

#if NumTimers
volatile OS_Timer_t OS_Timers[NumTimers];
#endif


/* wordset:avr-gcc-os */

/* End of file  vars.c */
