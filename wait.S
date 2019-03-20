; share/avr/silOS/wait.S
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


#if NumSignals


	.section	".text.OS.signal", "x"

.global	Signal_WaitWithTimeout
.type	Signal_WaitWithTimeout, @function

.global	Signal_Wait
.type	Signal_Wait, @function

Signal_Wait:
; RegType_t Signal_Wait( Signal_t sig )
; Если сигнал не установлен, то ожидает его установки.
; При выходе разрешает прерывания и разблокирует диспетчер потоков.
;
; На входе:
;	регистр r24: номер сигнала
;	регистр r1: ноль
; На выходе:
;	регистр r24: 1 -- сигнал установлен
;	           240 -- сигнал не установлен,
;	                  поток активизирован функцией Thread_Activate
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.
; Функция разрешает прерывания и разблокирует диспетчер потоков.

	clr	r22
#if BIG_SLEEP
	clr	r23
#endif /* BIG_SLEEP */

Signal_WaitWithTimeout:
; RegType_t Signal_WaitWithTimeout( Signal_t sig, SleepTime_t ticks )
; Если сигнал не установлен, то ожидает его установки в течении
; указаного времени.
; При выходе разрешает прерывания и разблокирует диспетчер потоков.
;
; На входе:
;	регистр r24: номер сигнала
;	регистр r22: время, в течении которого нужно ожидать установки
;	             сигнала; если определён макрос BIG_SLEEP, то для
;	             передачи времени используется пара регистров r23:r22
;	регистр r1: ноль
; На выходе:
;	регистр r24: 0 -- сигнал не установлен, поток активизирован по таймауту
;	             1 -- сигнал установлен
;	           240 -- сигнал не установлен,
;	                  поток активизирован функцией Thread_Activate
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.
; Функция разрешает прерывания и разблокирует диспетчер потоков.

	mov	r25, r24
#if START_SIGNALS != 1
	subi	r25, Low(0 - (START_SIGNALS-1))
#endif /* START_SIGNALS */
	rcall   _silOS_GetSignalMask
	; Z -- адрес байта с битом сигнала
	; r24 -- маска сигнала
	cli
	ld	ZL, Z
	and	r24, ZL
	brne	1f
	; сигнала нет
	mov	r24, r25
	rjmp	Event_Watch_Internal

1:	ldi	r24, 1		; есть сигнал
	rjmp	Scheduler_Deblock

.size	Signal_Wait, . - Signal_Wait
.size	Signal_WaitWithTimeout, . - Signal_WaitWithTimeout


#endif /* NumSignals */


;
; wordset:avr-gcc-os
;
; End of file  wait.S
