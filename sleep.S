; share/avr/silOS/sleep.S
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


	.section	".text.OS", "x"

.global Sleep
.type	Sleep, @function

Sleep:
; RegType_t Sleep( SleepTime_t ticks )
; Приостанавливает работу текущего потока на указаное время.
;
; На входе:
;	регистр r24: время в тиках системного таймера (точнее,
;	             количество выполнений макроса OS_TICK),
;	             на которое нужно приостановить текущий поток;
;	             если определён макрос BIG_SLEEP, то для передачи
;	             времени используется пара регистров r25:r24
; На выходе:
;	регистр r24: 0 -- активизация потока выполнена по таймауту
;	           240 -- активизация потока выполнена функцией Thread_Activate
;	                  (или функция Sleep была вызвана с нулевым аргументом)
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.
; Функция разрешает прерывания и разблокирует диспетчер потоков.

#if !__BlockingRes
	; если в TSB нет поля BlockingRes, то младший разряд поля SleepCounter
	; используется для бессрочной блокировки потока
	add	r24, r24
#if BIG_SLEEP
	adc	r25, r25
#endif /* BIG_SLEEP */
#endif /* __BlockingRes */

	ldsw	Z, OS_CurTSB
	cli
#if BIG_SLEEP
	std	Z+SleepCounter+1, r25
#endif /* BIG_SLEEP */
	std	Z+SleepCounter, r24

	ldi	r24, 240	; значение, возвращаемое при активизации потока
				; функцией Thread_Activate
	std	Z+SaveR24, r24
;	std	Z+SaveR25, r1

	; уходим в OS_Scheduler без сохранения регистров
	rjmp	OS_Scheduler_SuspendThread

.size	Sleep, . - Sleep


;
; wordset:avr-gcc-os
;
; End of file  sleep.S
