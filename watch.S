; share/avr/silOS/watch.S
;
; silOS: Short Interrupt Latency OS
; Copyright (C) 2010 Potrepalov I.S.  potrepalov@list.ru
;
;   This library is free software; you can redistribute it and/or
;   modify it under the terms of the GNU Lesser General Public
;   License as published by the Free Software Foundation; either
;   version 2 of the License, or (at your option) any later version.
;
;   This library is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;   Lesser General Public License for more details.
;
;   You should have received a copy of the GNU Lesser General Public
;   License along with this library; if not, write to the Free Software
;   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;


#include <avr/io.h>
#include "genmacro/genmacro.inc"
#include "os.h"


#if NumEvents + NumSignals


	.section	".text.OS", "x"

.global Event_Watch
.type	Event_Watch, @function

.global Event_WatchWithTimeout
.type	Event_WatchWithTimeout, @function


Event_Watch:
; RegType_t Event_Watch( Event_t event )
; Ожидает указанное событие.
; При выходе разрешает прерывания и разблокирует диспетчер потоков.
;
; На входе:
;	регистр r24: номер события, которое нужно ожидать
;	регистр r1: ноль
; На выходе:
;	регистр r24: 1 -- дождались события
;	           240 -- события не дождались, поток активизирован
;	                  функцией Thread_Activate
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.
; Функция разрешает прерывания и разблокирует диспетчер потоков.

	clr	r22
#if BIG_SLEEP
	clr	r23
#endif /* BIG_SLEEP */

Event_WatchWithTimeout:
; RegType_t Event_WatchWithTimeout( Event_t event, SleepTipe ticks )
; Ожидает указанное событие в течении указаного времени.
; При выходе разрешает прерывания и разблокирует диспетчер потоков.
;
; На входе:
;	регистр r24: номер события, которое нужно ожидать
;	регистр r22: время, в течении которого нужно ожидать событие;
;	             если определён макрос BIG_SLEEP, то для передачи
;	             времени используется пара регистров r23:r22
;	регистр r1: ноль
; На выходе:
;	регистр r24: 0 -- события не дождались, поток активизирован по таймауту
;	             1 -- дождались события
;	           240 -- события не дождались, поток активизирован
;	                  функцией Thread_Activate
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.
; Функция разрешает прерывания и разблокирует диспетчер потоков.

#if START_EVENTS != 1
	subi	r24, Low(0 - (START_EVENTS-1))
#endif /* START_EVENTS */

Event_Watch_Internal:	.global Event_Watch_Internal

	ldsw	Z, OS_CurTSB
	ldi	r25, 240
	cli
	std	Z+SaveR24, r25
#if BIG_SLEEP
	std	Z+SleepCounter+1, r23
#endif /* BIG_SLEEP */
	std	Z+SleepCounter, r22
	std	Z+BlockingRes, r24
	rjmp	OS_Scheduler_SuspendThread

.size	Event_WatchWithTimeout, . - Event_WatchWithTimeout
.size	Event_Watch, . - Event_Watch


#endif /* NumEvents + NumSignals */


;
; wordset:avr-gcc-os
;
; End of file  watch.S
