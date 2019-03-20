/* share/avr/silOS/examples/cycle-timers.c */

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


THREAD( example_1sec, intptr_t v )
{
	Start_Cycle_Timer( 1, msToTicks(1000), (vfc_p)Semaphore_Up );

	do {
		Sempahore_Down( 1 + CYCLE_TIMER_EVENT_BASE );
		// выполняется каждую секунду
		....
		// если не успеет выполниться за секунду, то
		// следующий цикл начнётся без ожидания в Semaphore_Down
	} while ( 1 );
} // example_1sec


/* End of file  cycle-timers.c */