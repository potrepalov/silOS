/* share/avr/silOS/examples/cycle-timers.h */

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


#define NumCTimers	1
#define CYCLE_TIMER_EVENT_BASE	0

// в функции таймеров .func( ) в качестве параметра передаётся
// номер таймера плюс константа CYCLE_TIMER_EVENT_BASE

// в качетсве функции таймера может сразу использоваться любая
// из функций Signal_Set, Signal_Reset, Event_Occur, Mutex_Release,
// Semaphore_Up, Thread_Activate, Thread_Kill, Thread_Suspend


#if !defined( __ASSEMBLER__ )


typedef void (*vfc_p) ( unsigned char );

typedef cycle_timer_tag {
	unsigned short cnt;
	unsigned short start;
	vfc_p func;
} cycle_timer_t;

extern cycle_timer_t cycle_timers[];


static void Start_Cycle_Timer( unsigned char timer, unsigned short start,
				vfc_p func )
{
	unsigned char sreg = SREG;
	cli();
	cycle_timers[timer-1].cnt = start;
	cycle_timers[timer-1].start = start;
	cycle_timers[timer-1].func = func;
	SREG = sreg;
}


static void Stop_Cycle_Timer( unsigned char timer )
{
	unsigned char sreg = SREG;
	cli();
	cycle_timers[timer-1].cnt = 0;
	SREG = sreg;
}


#endif /* __ASSEMBLER__ */


/* End of file  cycle-timers.h */
