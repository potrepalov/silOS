; share/avr/silOS/suspend.S
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

.global Suspend
.type	Suspend, @function

.global Suspend_r
.type	Suspend_r, @function

.global Suspend_w
.type	Suspend_w, @function


Suspend:
; void Suspend( void )
; Приостанавливает работу текущего потока.
;
; На входе:
;	регистр r1: ноль
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.

Suspend_r:
; RegType_t Suspend_r( RegType_t )
; Приостанавливает работу текущего потока.
;
; На входе:
;	регистр r24: любое значение
;	регистр r1: ноль
; На выходе:
;	регистр r24: то же самое значение, если только оно не поменялось
;	             во время остановки потока (полезно для реализации
;	             собственных средств синхронизации потоков)
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.

Suspend_w:
; intptr_t Suspend_w( intptr_t )
; Приостанавливает работу текущего потока.
;
; На входе:
;	регистры r25:r24: любое значение
; На выходе:
;	регистры r25:r24: то же самое значение, если только оно не поменялось
;	                  во время остановки потока (полезно для реализации
;	                  собственных средств синхронизации потоков)
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.

	ldsw	Z, OS_CurTSB
	std	Z+SaveR24, r24
	std	Z+SaveR25, r25
	cli

#if __BlockingRes
	ldi	r24, 0xFF
	std	Z+BlockingRes, r24
#else /* !__BlockingRes */
	ldi	r24, 1
	std	Z+SleepCounter, r24
#endif /* __BlockingRes */

	; текущий поток блокирован, нужно переключаться на активный поток
	rjmp	OS_Scheduler_SuspendThread

.size	Suspend, . - Suspend


;
; wordset:avr-gcc-os
;
; End of file  suspend.S
