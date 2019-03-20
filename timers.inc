; share/avr/silOS/timers.inc
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

;
; Макрос прикладных таймеров
; Уменьшает счетчики таймеров до нуля
;


#if !defined( TIMERS_INC_INCLUDED )
#define TIMERS_INC_INCLUDED


#include "os.h"


.macro	OS_TIMERS iev, work_reg, start_timer = 1, end_timer = NumTimers
; Уменьшает значения таймеров до 0
;
; Использование рабочего регистра происходит при запрещённых прерываниях
;
; Данный макрос можно выполнять только для части таймеров
; или для разных таймеров с разной периодичностью
;
; Использует регистры: ZL, ZH

#if NumTimers

	OS_interrupt_status \iev, .L_iev, .L_iev_reg


    .if	\start_timer - \end_timer


	letw	Z, OS_Timers + (\end_timer - 1) * 2

	.ifeq .L_iev ; .L_iev == 0
	in	.L_iev_reg, SREG
	.else
	.endif ; .L_iev == 0
101:
	.iflt .L_iev - 2 ; .L_iev < 2
	cli
	.else
	.endif ; .L_iev < 2

	ldd	\work_reg, Z+0
	subi	\work_reg, 1
	brcc	102f
	ldd	\work_reg, Z+1
	subi	\work_reg, 1
	brcs	103f
	std	Z+1 ,\work_reg
	ldi	\work_reg, 0xFF
102:
	std	Z+0, \work_reg
103:
	OS_Restore_Interrupts	.L_iev, .L_iev_reg

	sbiw	Z, 2
	cpi	ZL, Low( OS_Timers + 2*(\start_timer-2) )
	brne	101b

	.ifge	\start_timer - \end_timer - 128
	cpi	ZH, High( OS_Timers + 2*(\start_timer-2) )
	brne	101b
	.endif


    .else ; \start_timer - \end_timer


	.ifeq .L_iev ; .L_iev == 0
	in	.L_iev_reg, SREG
	.else
	.endif ; .L_iev == 0
101:
	.iflt .L_iev - 2 ; .L_iev < 2
	cli
	.else
	.endif ; .L_iev < 2

	lds	\work_reg, OS_Timers + 2*(\start_timer - 1)
	subi	\work_reg, 1
	brcc	102f
	lds	\work_reg, OS_Timers + 2*(\start_timer - 1) + 1
	subi	\work_reg, 1
	brcs	103f
	sts	OS_Timers + 2*(\start_timer - 1) + 1,\work_reg
	ldi	\work_reg, 0xFF
102:
	sts	OS_Timers + 2*(\start_timer - 1), \work_reg
103:
	OS_Restore_Interrupts	.L_iev, .L_iev_reg


    .endif ; \start_timer - \end_timer

#endif /* NumTimers */

.endm ; OS_TIMERS


#endif /* TIMERS_INC_INCLUDED */


;
; wordset:avr-gcc-os
;
; End of file  timers.inc
