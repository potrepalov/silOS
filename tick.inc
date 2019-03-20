; share/avr/silOS/tick.inc
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
; Макрос системного таймера
; Уменьшает счетчики сна потоков
;


#if !defined( TICK_INC_INCLUDED )
#define TICK_INC_INCLUDED



#include "os.h"


#if __BlockingRes
#define __tick_diff	1
#else /* __BlockingRes */
	; если BlockingSem не определён, то младший бит поля SleepCounter
	; используется для блокировки потока без таймаута; и нет ни событий,
	; ни ресурсов, ни сигналов, а значит и нет функций вида ...WithTimeout;
	; и при засыпании младший бит SleepCounter'а всегда будет 0
#define __tick_diff	2
#endif /* __BlockingRes */


.macro	OS_TICK	iev, work_reg, wr2=ttt, start_thread = 1, end_thread = NumThreads
; Использование рабочих регистров происходит при запрещённых прерываниях
; wr2 используется в случае, когда счетчики сна занимают 2 байта
;
; Данный макрос можно выполнять только для части потоков
; или для разных потоков с разной периодичностью
;
; Использует регистры ZL и ZH
; Время выполнения: в среднем не более 28 тактов на поток
;	(и точно не более 36 тактов на поток)

	OS_interrupt_status \iev, .L_iev, .L_iev_reg


	.L_LongTSB = 0
#if SizeOfTSB % 128 == 0
	.ifgt \end_thread - \start_thread - 2
	.L_LongTSB = 1
	.endif ; .ifgt
#elif SizeOfTSB % 64 == 0
	.ifgt \end_thread - \start_thread - 4
	.L_LongTSB = 1
	.endif ; .ifgt
#elif SizeOfTSB % 32 == 0
	.ifgt \end_thread - \start_thread - 8
	.L_LongTSB = 1
	.endif ; .ifgt
#elif SizeOfTSB % 16 == 0
	.ifgt \end_thread - \start_thread - 16
	.L_LongTSB = 1
	.endif ; .ifgt
#elif SizeOfTSB % 8 == 0
	.ifgt \end_thread - \start_thread - 32
	.L_LongTSB = 1
	.endif ; .ifgt
#elif SizeOfTSB % 4 == 0
	.ifgt \end_thread - \start_thread - 64
	.L_LongTSB = 1
	.endif ; .ifgt
#elif SizeOfTSB % 2 == 0
	.ifgt \end_thread - \start_thread - 128
	.L_LongTSB = 1
	.endif ; .ifgt
#endif /* SizeOfTSB */


  .if \start_thread - \end_thread


#if BIG_SLEEP
  .ifc \wr2,ttt
	push	r28
	.L_wr = 28
  .else
	_get_reg \wr2, .L_wr
  .endif
#endif /* BIG_SLEEP */


	letw	Z, OS_TSBs + (\end_thread-1) * SizeOfTSB

	.ifeq .L_iev ; .L_iev == 0
	in	.L_iev_reg, SREG
	.else
	.endif ; .L_iev == 0
101:
	.iflt .L_iev - 2 ; .L_iev < 2
	cli
	.else
	.endif ; .L_iev < 2

	ldd	\work_reg, Z+SleepCounter
	subi	\work_reg, __tick_diff
#if BIG_SLEEP
	ldd	.L_wr, Z+SleepCounter+1
	sbci	.L_wr, 0
#endif /* BIG_SLEEP */

	brcc	102f		; поток спит или спал
	; активный поток (счетчик сна был и остаётся равен 0)

	OS_Restore_Interrupts	.L_iev, .L_iev_reg

	sbiw	Z, SizeOfTSB
	cpi	ZL, Low(OS_TSBs+SizeOfTSB*(\start_thread-2))
	brne	101b

	.if .L_LongTSB
	cpi	ZH, High(OS_TSBs+SizeOfTSB*(\start_thread-2))
	brne	101b
	.endif	; .L_LongTSB
	rjmp	104f

103:	; будим поток
	; \work_reg == 0
;	std	Z+SleepCounter, \work_reg
#if __BlockingRes
	std	Z+BlockingRes, \work_reg
#endif /* BlockingRes */

	; меняем возвращаемое в поток значение (в поток вернётся 0)
	; и выставляем флаг поиска активного потока
	.if OS_Reg_isAbsent
	std	Z+SaveR24, \work_reg
	lds	\work_reg, OS_Flags
	andi	\work_reg, ~1
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	sts	OS_Flags, \work_reg
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	std	Z+SaveR24, \work_reg
	sbrc	OS_Reg, 0
	dec	OS_Reg
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	std	Z+SaveR24, \work_reg
	andi	OS_Reg, ~1
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	std	Z+SaveR24, \work_reg
	in	\work_reg, OS_Reg
	andi	\work_reg, ~1
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	out	OS_Reg, \work_reg
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		


	sbiw	Z, SizeOfTSB
	cpi	ZL, Low(OS_TSBs+SizeOfTSB*(\start_thread-2))
	brne	101b

	.if .L_LongTSB
	cpi	ZH, High(OS_TSBs+SizeOfTSB*(\start_thread-2))
	brne	101b
	.endif	; .L_LongTSB
	rjmp	104f

102:	; поток спит или только что проснулся
#if BIG_SLEEP
	std	Z+SleepCounter+1, .L_wr
#endif /* BIG_SLEEP */
	std	Z+SleepCounter, \work_reg
	breq	103b		; поток нужно будить
	; поток продолжает спать
	OS_Restore_Interrupts	.L_iev, .L_iev_reg

	sbiw	Z, SizeOfTSB
	cpi	ZL, Low(OS_TSBs+SizeOfTSB*(\start_thread-2))
	brne	101b

	.if .L_LongTSB
	cpi	ZH, High(OS_TSBs+SizeOfTSB*(\start_thread-2))
	brne	101b
	.endif	; .L_LongTSB

104:


#if BIG_SLEEP
  .ifc \work_reg2,ttt
	pop	r28
  .endif
#endif /* BIG_SLEEP */




  .else	; \start_thread - \end_thread
	; start_thread == end_thread


	OS_Disable_Interrupts	.L_iev, .L_iev_reg

	lds	ZL, OS_TSBs + (\end_thread-1)*SizeOfTSB + SleepCounter
#if BIG_SLEEP
	lds	ZH, OS_TSBs + (\end_thread-1)*SizeOfTSB + SleepCounter+1
	sbiw	Z, __tick_diff
#else /* BIG_SLEEP */
	subi	ZL, __tick_diff
#endif /* BIG_SLEEP */
	brcs	105f		; активный поток (счетчик сна был и остаётся 0)
	; поток спит или спал
	sts	OS_TSBs + (\end_thread - 1)*SizeOfTSB + SleepCounter, ZL
#if BIG_SLEEP
	sts	OS_TSBs + (\end_thread - 1)*SizeOfTSB + SleepCounter+1, ZH
#endif /* BIG_SLEEP */
	brne	106f		; поток продолжает спать
	; будим поток
	; \work_reg == 0
#if __BlockingRes
	sts	OS_TSBs + (\end_thread - 1)*SizeOfTSB + BlockingRes, ZL
#endif /* BlockingRes */
	; меняем возвращаемое потоку значение на 0
	; (поток был активизирован по таймауту)
	sts	OS_TSBs + (\end_thread - 1)*SizeOfTSB + SaveR24, ZL

	.if OS_Reg_isAbsent
	lds	\work_reg, OS_Flags
	andi	\work_reg, ~1
	sts	OS_Flags, \work_reg
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	sbrc	OS_Reg, 0
	dec	OS_Reg
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	andi	OS_Reg, ~1
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	in	\work_reg, OS_Reg
	andi	\work_reg, ~1
	out	OS_Reg, \work_reg
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

106:
105:
	OS_Restore_Interrupts	.L_iev, .L_iev_reg



  .endif ; \start_thread - \end_thread


.endm ; OS_TICK

#endif /* TICK_INC_INCLUDED */


;
; wordset:avr-gcc-os
;
; End of file  tick.inc
