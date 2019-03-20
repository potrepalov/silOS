; share/avr/silOS/down.S
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


#if NumSemaphores


	.section	".text.OS", "x"

.global Semaphore_Down
.type	Semaphore_Down, @function

.global Semaphore_DownWithTimeout
.type	Semaphore_DownWithTimeout, @function


.global Semaphore_Pend
.type	Semaphore_Pend, @function

.global Semaphore_PendWithTimeout
.type	Semaphore_PendWithTimeout, @function


.global Semaphore_Close
.type	Semaphore_Close, @function

.global Semaphore_CloseWithTimeout
.type	Semaphore_CloseWithTimeout, @function


Semaphore_Down:
Semaphore_Pend:
Semaphore_Close:
; RegType_t Semaphore_Down( Semaphore_t sem )
; Если счетчик семафора не 0 (семафор открыт), то уменьшает его на 1 (закрывает)
; и возвращается.
; Если счетчик семафора 0 (семафор закрыт), то ожидает его увеличения на 1
; (ожидает открытия семафора), затем уменьшает его на 1 (закрывает)
; и возвращается.
; Перед возвратом разрешает прерывания и разблокирует диспетчер потоков.
;
; На входе:
;	регистр r24: номер семафора
;	регистр r1: ноль
; На выходе:
;	регистр r24: 1 -- семафор был открыт
;	           240 -- семафор был закрыт, и поток был
;	                  активизирован функцией Thread_Activate
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.
; Функция разрешает прерывания и разблокирует диспетчер потоков.

	clr	r22
#if BIG_SLEEP
	clr	r23
#endif /* BIG_SLEEP */

Semaphore_DownWithTimeout:
Semaphore_PendWithTimeout:
Semaphore_CloseWithTimeout:
; RegType_t Semaphore_DownWithTimeout( Semaphore_t, SleepTime_t )
; Если счетчик семафора не 0 (семафор открыт), то уменьшает его на 1 (закрывает)
; и возвращает значение 1.
; Если счетчик семафора 0 (семафор закрыт), то ожидает в течении указанного
; времени его увеличения на 1 (в течении указанного времени ожидает открытия
; семафора), затем уменьшает его на 1 (закрывает) и возвращается;
; если в течении указанного времени семафор не откроется, то возвращает
; значение 0.
; Перед возвратом разрешает прерывания и разблокирует диспетчер потоков.
;
; На входе:
;	регистр r24: номер семафора
;	регистр r22: время, в течении которого можно ожидать открытия семафора;
;	             если определён макрос BIG_SLEEP, то для передачи
;	             времени используется пара регистров r23:r22
;	регистр r1: ноль
; На выходе:
;	регистр R24: 0 -- семафор был закрыт, поток активизирован по таймауту
;	             1 -- семафор был открыт
;	           240 -- семафор был закрыт, и поток был
;	                  активизирован функцией Thread_Activate
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.
; Функция разрешает прерывания и разблокирует диспетчер потоков.

	letw	X, OS_Semaphores-1
	add	XL, r24
	adc	XH, r1
	ldsw	Z, OS_CurTSB
#if START_SEMAPHORES != 1
	subi	r24, Low(0-(START_SEMAPHORES-1))
#endif /* START_SEMAPHORES */
	cli
	ld	r25, X
	subi	r25, 1
	brcc	1f
	; семафор "закрыт"

	; блокируем текущий поток в ожидании семафора
	std	Z+BlockingRes, r24
#if BIG_SLEEP
	std	Z+SleepCounter+1, r23
#endif /* BIG_SLEEP */
	std	Z+SleepCounter, r22
	ldi	r25, 240	; значение, возвращаемое при активизации
				; потока функцией Thread_Activate
	std	Z+SaveR24, r25
	rjmp	OS_Scheduler_SuspendThread

1:	; семафор был "открыт"
	sei
	st	X, r25
	ldi	r24, 1
	rjmp	Scheduler_Deblock

.size	Semaphore_Down, . - Semaphore_Down
.size	Semaphore_DownWithTimeout, . - Semaphore_DownWithTimeout

.size	Semaphore_Pend, . - Semaphore_Pend
.size	Semaphore_PendWithTimeout, . - Semaphore_PendWithTimeout

.size	Semaphore_Close, . - Semaphore_Close
.size	Semaphore_CloseWithTimeout, . - Semaphore_CloseWithTimeout


#endif /* NumSemaphores */


;
; wordset:avr-gcc-os
;
; End of file  down.S
