; share/avr/silOS/scheduler.S
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



.macro	ReturnToThread_code
; возврат в активный поток:
; либо переключения между потоками запрещены,
; либо активный поток менять не нужно,
; либо это возврат в начало прерванного прерывания в икс-меге

	; во время восстановления указателя стека прерывания
	; должны быть запрещены (вплоть до возврата в поток)

#if defined( iSPL )

	out	SPL, iSPL
#if __AVR_HAVE_SPH__
	out	SPH, iSPH
#endif /* __AVR_HAVE_SPH__ */

#else /* !defined( iSPL ) */

	lds	OS_wReg, ISR_SPsave
	out	SPL, OS_wReg
#if __AVR_HAVE_SPH__
	lds	OS_wReg, ISR_SPsave+1
	out	SPH, OS_wReg
#endif /* __AVR_HAVE_SPH__ */

#endif /* defined( iSPL ) */

	; состояние стека потока (верхнее значение сверху):
	; SREG
	; OS_wReg
	; адрес возврата из прерывания

	pop	OS_wReg
#if __ATXMEGA__
	; у икс-меги необходимо сбросить флаг прерывания
	; т.к. возможна ситуация, когда в стеке потока
	; будут накапливаться адреса возвратов из прерываний
	; (которые будут обрабатываться в интервале между
	; нижеследующими командами out и ret)
	andi	OS_wReg, ~(1 << SREG_I)
#else /* !__ATXMEGA__ */
	; у не икс-мег флаг прерываний сброшен, ничего делать не надо
#endif /* __ATXMEGA__ */
	out	SREG, OS_wReg
	pop	OS_wReg
	sei
	ret
.endm	; ReturnToThread_code


	.section	".text.OS", "x"

.global OS_Scheduler
.type	OS_Scheduler, @function

#if __ATXMEGA__
	.ifeq OS_Reg_isLoReg + OS_Reg_isHiReg
ReturnToThread_cli:
	cli
ReturnToThread:
	ReturnToThread_code
	.endif	; OS_Reg_isLoReg + OS_Reg_isHiReg

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

#else /* !__ATXMEGA__ */
ReturnToThread:
	ReturnToThread_code
#endif /* __ATXMEGA__ */

OS_Scheduler:
; Запуск (переход к выполнению) наиболее приоритетного из активных потоков
; Сюда попадаем из первого прерывания после выполнения команды reti
; (у икс-меги сюда можем попасть из вложенного прерывания)
; На входе:
;	текущий стек: стек прерываний
;	в стеке потока находятся следующие элементы (верхний сверху):
;		SREG
;		OS_wReg
;		адрес возврата из прерывания
;
; Замечание: в программах для икс-мег стеки потоков должны учитывать
; возможность возникновения вложенных прерываний: возможна обработка
; более приоритетного прерывания возникшего после входа в обработчик
; прерывания, но до переключения на стек прерываний.
;
	; готовим стек прерываний для перехода сюда из первого прерывания
	; (значения, которые были в стеке и использовались для перехода сюда,
	; уже могли быть потёрты прерываниями, обработанными сразу после
	; команды перехода сюда)

	; в стеке прерываний должны быть следующие элементы (верхний сверху):
	;	fake SREG  (if iSREG is not defined)
	;	fake OS_wReg
	;	адрес перехода на OS_Scheduler

	ldi	OS_wReg, lo8(pm(OS_Scheduler))
	push	OS_wReg
	ldi	OS_wReg, hi8(pm(OS_Scheduler))
	push	OS_wReg
#if RA_Stack_Space == 3
	ldi	OS_wReg, hlo8(pm(OS_Scheduler))
	push	OS_wReg
#endif /* RA_Stack_Space == 3 */
	push	OS_wReg			; fake OS_wReg
#if !defined( iSREG ) || __ATXMEGA__
	ldi	OS_wReg, (1 << SREG_I)	; fake SREG, enable interrupts
	push	OS_wReg
#endif /* defined( iSREG ) || __ATXMEGA__ */


#if __ATXMEGA__
; у икс-меги необходимо проверять состояние регистра PMIC_STATUS, т.к.
; мы можем попасть сюда даже в прерывании: начало обработки LOW prio
; прерывания, затем сразу MID prio, после MID prio попадём сюда, отсюда
; должны вернуться к обработке LOW prio прерывания и уже после
; обработки LOW prio прерывания менять активный поток
;
; по этой же причине почти всегда прерывания икс-меги необходимо оформлять
; как допускающие вложенность (вложенное прерывание может случиться даже
; до выполнения первой команды обработчика прерывания): поток могут
; активизировать во вложенном прерывании; если же есть гарантия, что во
; вложенных прерываниях не выполняют переключение активного потока
; (или вложенных прерываний нет), то из этого правила можно сделать исключение

	in	OS_wReg, PMIC_STATUS

	.if OS_Reg_isLoReg + OS_Reg_isHiReg
	cli
	or	OS_wReg, OS_Reg
	breq	1f
	ReturnToThread_code
1:	
	.else	; !(OS_Reg_isLoReg + OS_Reg_isHiReg)
	tst	OS_wReg
	brne	ReturnToThread_cli
	.endif	; OS_Reg_isLoReg + OS_Reg_isHiReg
#endif /* __ATXMEGA__ */

	; проверяем можно ли и нужно ли менять поток
	.if OS_Reg_isAbsent
	cli
	lds	OS_wReg, OS_Flags
	tst	OS_wReg
	; если не 0, значит поток менять нельзя или не нужно
	brne	ReturnToThread
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg + OS_Reg_isHiReg
#if !__ATXMEGA__
	cli
	tst	OS_Reg
	; если не 0, значит поток менять нельзя или не нужно
	brne	ReturnToThread
#endif /* !__ATXMEGA__ */
	.endif	; OS_Reg_isLoReg + OS_Reg_isHiReg

	.if OS_Reg_isIO
	cli
	in	OS_wReg, OS_Reg
	tst	OS_wReg
	; если не 0, значит поток менять нельзя или не нужно
	brne	ReturnToThread
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

	; меняем активный поток
	sei

OS_Scheduler_Unlocked:	.global	OS_Scheduler_Unlocked
; I. Сохраняем регистры (в регистрах r24, r25 в текущий поток передается
; возвращаемое из функций значение; это значение не может измениться
; в прерываниях или в других потоках; для передачи в текущий поток
; значения, которое может измениться в прерывании или других потоках,
; используется другая точка входа в планировщик: OS_Scheduler_SuspendThread)

	; регистры ZH и ZL сохраняем в стеке прерываний
	pushw	Z		; r31:r30
	ldsw	Z, OS_CurTSB
	std	Z+SaveR24, r24
;	sei			здесь прерывания всегда разрешены
	std	Z+SaveR25, r25

	std	Z+SaveR0, r0

	; если мьютексов нет, то регистры XL и XH не портим
#if TotalMutexes
	std	Z+SaveR26, r26	; XL
	std	Z+SaveR27, r27	; XH
#endif /* TotalMutexes */

OS_Scheduler_Suspend_Internal:
	std	Z+SaveR1, r1
	std	Z+SaveR28, r28	; YL
	std	Z+SaveR29, r29	; YH


	; II. Ищем наиболее приоритетный поток, готовый к выполнению
FindActiveThread:
	sei
FindAT_Idle:
	clr	r1		; возможно, что в R1 не 0

	ldi	r25, 1		; индекс текущего потока

	; для очистки флагов операционной системы требуется константа 1
	; используем значение индекса текущего потока
	.if OS_Reg_isAbsent
	sts	OS_Flags, r25
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg + OS_Reg_isHiReg
	mov	OS_Reg, r25
	.endif	; OS_Reg_isLoReg + OS_Reg_isHiReg

	.if OS_Reg_isIO
	out	OS_Reg, r25
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		


#if TotalMutexes


	; при наличии мьютексов возможена передача приоритета
	letw	X, OS_TSBs
o_Loop:	; цикл по всем потокам (номер текущего потока в регистре r25)
	movw	Y, X
	mov	r0, r25
i_Loop:	; внутренний цикл по взаимосвязанным потокам
	; проверяем поток, номер (индекс) которого в регистре r0

#if STOP_IN_ISR
	; отмечаем, состояние какого потока сейчас анализируем
	; (если в прерывании приостановят именно этот поток, то
	; поиск активного потока нужно будет повторить)
	sts	OS_ThreadInProcess, r0
#endif /* STOP_IN_ISR */

	; сначала проверяем BlockingRes (для случая GetWithTimeout)
#if RELEASE_IN_ISR
	cli
#endif /* RELEASE_IN_ISR */
	ldd	r24, Y+BlockingRes
	tst	r24
	breq	1f		; поток не ожидает ресурсов
	; поток ожидает какой-то ресурс
	; в r24 может быть флаг, номер мьютекса, сигнала и т.п;
	; приоритет передаём только тогда, когда в r24 номер мьютекса
	cpi	r24, TotalMutexes + 1
	brcc	2f		; в r24 не номер мьютекса
	; по номеру мьютекса определяем поток, который владеет мьютексом
	letw	Y, OS_Mutexes + NumCMutexes - 1
	add	YL, r24
	adc	YH, r1
#if RELEASE_IN_ISR
	sei
#endif /* RELEASE_IN_ISR */
	ld	r24, Y		; в r24 номер потока-владельца мьютекса
	cp	r24, r25	; сравниваем приоритеты потока-владельца
				; мьютекса и текущего потока
	brcs	3f		; поток-владелец имеет больший приоритет
	; переходим к потоку-владельцу мьютекса с меньшим приоритетом
	; (выполняем передачу приоритета)
#if __AVR_HAVE_MUL__
	ldi	YL, SizeOfTSB
	mul	YL, r24
	letw	Y, OS_TSBs - SizeOfTSB
	addw	Y, r0
#if NumThreads * SizeOfTSB > 255
	clr	r1
#endif /* NumThreads * SizeOfTSB */
	mov	r0, r24		; в r0 номер анализируемого потока
#else /* __AVR_HAVE_MUL__ */
	mov	r0, r24		; в r0 номер анализируемого потока
	letw	Y, OS_TSBs - SizeOfTSB
9:	adiw	Y, SizeOfTSB
	dec	r24
	brne	9b
#endif /* __AVR_HAVE_MUL__ */
	rjmp	i_Loop		; цикл по взаимосвязанным потокам

2:
#if RELEASE_IN_ISR
	sei
#endif /* RELEASE_IN_ISR */
3:	; поток не готов к выполнению
	; переходим к следующему потоку
	adiw	X, SizeOfTSB
	inc	r25
	cpi	r25, NumThreads+1
	brne	o_Loop		; цикл по всем потокам
	; активного потока не нашли

#if STOP_IN_ISR
	sts	OS_ThreadInProcess, r1	; OS_ThreadInProcess := 0
#endif /* STOP_IN_ISR */
5:
	; активного потока нет, делать нечего
	; зависаем в ожидании активизации какого-либо потока

	.if OS_Reg_isAbsent
	lds	r25, OS_Flags
	sbrs	r25, 0
	rjmp	FindAT_Idle	; необходимо изменить активный поток
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg + OS_Reg_isHiReg
	sbrs	OS_Reg, 0
	rjmp	FindAT_Idle	; необходимо изменить активный поток
	.endif	; OS_Reg_isLoReg + OS_Reg_isHiReg

	.if OS_Reg_isLoIO
	sbis	OS_Reg, 0	; необходимо изменить активный поток
	rjmp	FindAT_Idle
	.endif	; OS_Reg_isLoIO

	.if OS_Reg_isHiIO + OS_Reg_isVarIO
	in	r25, OS_Reg
	sbrs	r25, 0
	rjmp	FindAT_Idle	; необходимо изменить активный поток
	.endif	; OS_Reg_isHiIO + OS_Reg_isVarIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

#ifdef IdleFunc
	rcall	IdleFunc
#endif /* IdleFunc */

	rjmp	5b

1:	; поток не ожидает никакого ресурса
	; осталось проверить, что поток не спит
#if BIG_SLEEP
#if !RELEASE_IN_ISR
	; здесь нам нужен cli
	; если определён макрос RELEASE_IN_ISR, значит cli уже было
	cli
#endif /* RELEASE_IN_ISR */
	ldd	r0, Y+SleepCounter+1
	sei
	ldd	r24, Y+SleepCounter
	or	r24, r0
#else /* BIG_SLEEP */
#if RELEASE_IN_ISR
	; если определён макрос RELEASE_IN_ISR, значит была команда cli
	sei
#endif /* RELEASE_IN_ISR */
	ldd	r24, Y+SleepCounter
	tst	r24
#endif /* BIG_SLEEP */
	brne	3b		; поток спит, переходим к следующему потоку


#else /* TotalMutexes */

	; без мьютексов нет передачи приоритета, поэтому обходимся одним циклом
	letw	Y, OS_TSBs
o_Loop:	; цикл по всем потокам (номер текущего потока в регистре r25)

#if STOP_IN_ISR
	; отмечаем, состояние какого потока сейчас анализируем
	; (если в прерывании приостановят именно этот поток, то
	; поиск активного потока нужно будет повторить)
	sts	OS_ThreadInProcess, r25
#endif /* NO_STOP_IN_ISR */

#if BIG_SLEEP
	cli
	ldd	r0, Y+SleepCounter+1
	sei
	ldd	r24, Y+SleepCounter
	or	r24, r0
#else /* BIG_SLEEP */
	ldd	r24, Y+SleepCounter
	tst	r24
#endif /* BIG_SLEEP */
	breq	1f		; поток не спит
	; поток спит (или ожидает ресурс с таймаутом)

3:	; поток не готов к выполнению
	; переходим к следующему потоку
	adiw	Y, SizeOfTSB
	inc	r25
	cpi	r25, NumThreads+1
	brne	o_Loop		; цикл по всем потокам
	; активного потока не нашли

#if STOP_IN_ISR
	sts	OS_ThreadInProcess, r1	; OS_ThreadInProcess := 0
#endif /* STOP_IN_ISR */
5:
	; активного потока нет, делать нечего
	.if OS_Reg_isAbsent
	lds	r25, OS_Flags
	sbrs	r25, 0
	rjmp	FindAT_Idle	; необходимо изменить активный поток
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg + OS_Reg_isHiReg
	sbrs	OS_Reg, 0
	rjmp	FindAT_Idle	; необходимо изменить активный поток
	.endif	; OS_Reg_isLoReg + OS_Reg_isHiReg

	.if OS_Reg_isLoIO
	sbis	OS_Reg, 0	; необходимо изменить активный поток
	rjmp	FindAT_Idle
	.endif	; OS_Reg_isLoIO

	.if OS_Reg_isHiIO + OS_Reg_isVarIO
	in	r25, OS_Reg
	sbrs	r25, 0
	rjmp	FindAT_Idle	; необходимо изменить активный поток
	.endif	; OS_Reg_isHiIO + OS_Reg_isVarIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

#ifdef IdleFunc
	rcall	IdleFunc
#endif /* IdleFunc */

	rjmp	5b

1:	; поток не спит
#if __BlockingRes
	; проверяем блокировку потока
	ldd	r24, Y+BlockingRes
	tst	r24
	brne	3b		; поток блокирован
#endif /* __BlockingRes */

;	mov	r0, r25
#endif /* TotalMutexes */


	; нашли активный поток
	; Z - адрес TSB текущего потока
	; Y - адрес TSB найденого потока
	; r0/r25 - номер (индекс) найденого потока (с/без мьютексов)


; III. Проверяем, поменялся ли поток
	; Z - адрес TSB текущего потока
	; Y - адрес TSB найденого потока
	cp	ZL, YL
#if LONG_TSBS
	cpc	ZH, YH
#endif /* LONG_TSBS */

#if STOP_IN_ISR
	cli
	sts	OS_ThreadInProcess, r1	; OS_ThreadInProcess := 0
#endif /* STOP_IN_ISR */

#if SizeOfTSB < 20
	breq	ThreadIsSame	; активный поток остался прежнним
#else /* SizeOfTSB >= 20 */
	brne	2f		; активный поток поменялся
	rjmp	ThreadIsSame	; активный поток остался прежнним
2:
#endif /* SizeOfTSB < 20 */
	; поток поменялся

	; перенос указателя стека в TSB прежнего потока
	; и восстановление указателя стека нового потока
#if defined( iSPL )

	std	Z+SaveSPL, iSPL
	ldd	iSPL, Y+SaveSPL
#if __AVR_HAVE_SPH__
	std	Z+SaveSPH, iSPH
	ldd	iSPH, Y+SaveSPH
#endif /* __AVR_HAVE_SPH__ */

#else /* iSPL */

	lds	r24, ISR_SPsave
	std	Z+SaveSPL, r24
	ldd	r24, Y+SaveSPL
	sts	ISR_SPsave, r24
#if __AVR_HAVE_SPH__
	lds	r24, ISR_SPsave+1
	std	Z+SaveSPH, r24
	ldd	r24, Y+SaveSPH
	sts	ISR_SPsave+1, r24
#endif /* __AVR_HAVE_SPH__ */

#endif /* iSPL */

#if STOP_IN_ISR
	sei
#endif /* STOP_IN_ISR */

#if TotalMutexes
	sts	OS_CurTSBindex, r0
#else /* TotalMutexes */
	sts	OS_CurTSBindex, r25
#endif /* TotalMutexes */

	; значение OS_CurTSB используется только в тех функциях, которые
	; нельзя вызывать во время обработки прерываний; прочие функции
	; используют значение OS_CurTSBindex
	stsw	OS_CurTSB, Y

; IV. Сохраняем контекст текущего потока
#if SaveR2
	std	Z+SaveR2, r2
#endif /* SaveR2 */
#if SaveR3
	std	Z+SaveR3, r3
#endif /* SaveR3 */
#if SaveR4
	std	Z+SaveR4, r4
#endif /* SaveR4 */
#if SaveR5
	std	Z+SaveR5, r5
#endif /* SaveR5 */
#if SaveR6
	std	Z+SaveR6, r6
#endif /* SaveR6 */
#if SaveR7
	std	Z+SaveR7, r7
#endif /* SaveR7 */
#if SaveR8
	std	Z+SaveR8, r8
#endif /* SaveR8 */
#if SaveR9
	std	Z+SaveR9, r9
#endif /* SaveR9 */
#if SaveR10
	std	Z+SaveR10, r10
#endif /* SaveR10 */
#if SaveR11
	std	Z+SaveR11, r11
#endif /* SaveR11 */
#if SaveR12
	std	Z+SaveR12, r12
#endif /* SaveR12 */
#if SaveR13
	std	Z+SaveR13, r13
#endif /* SaveR13 */
#if SaveR14
	std	Z+SaveR14, r14
#endif /* SaveR14 */
#if SaveR15
	std	Z+SaveR15, r15
#endif /* SaveR15 */
#if SaveR16
	std	Z+SaveR16, r16
#endif /* SaveR16 */
#if SaveR17
	std	Z+SaveR17, r17
#endif /* SaveR17 */
#if SaveR18
	std	Z+SaveR18, r18
#endif /* SaveR18 */
#if SaveR19
	std	Z+SaveR19, r19
#endif /* SaveR19 */
#if SaveR20
	std	Z+SaveR20, r20
#endif /* SaveR20 */
#if SaveR21
	std	Z+SaveR21, r21
#endif /* SaveR21 */
#if SaveR22
	std	Z+SaveR22, r22
#endif /* SaveR22 */
#if SaveR23
	std	Z+SaveR23, r23
#endif /* SaveR23 */

#if defined( RAMPD ) && !defined( NoSaveRAMPD )
	in	r23, RAMPD
	std	Z+SaveRAMPD, r23
#endif /* RAMPD */

#if defined( RAMPX ) && !defined( NoSaveRAMPX )
	in	r23, RAMPX
	std	Z+SaveRAMPX, r23
#endif /* RAMPX */

#if defined( RAMPY ) && !defined( NoSaveRAMPY )
	in	r23, RAMPY
	std	Z+SaveRAMPY, r23
#endif /* RAMPY */

#if defined( RAMPZ ) && !defined( NoSaveRAMPZ )
	in	r23, RAMPZ
	std	Z+SaveRAMPZ, r23
#endif /* RAMPZ */

#if defined( EIND ) && !defined( NoSaveEIND )
	in	r23, EIND
	std	Z+SaveEIND, r23
#endif /* EIND */


#if !TotalMutexes
	std	Z+SaveR26, r26	; XL
	std	Z+SaveR27, r27	; XH
#endif /* !TotalMutexes */

	; сохраняем регистры ZH и ZL
	; (переносим их из стека прерываний в TSB потока)
	popw	r26
	std	Z+SaveR30, r26
	std	Z+SaveR31, r27

	; здесь можно собирать какую-нибудь статистику
	;
	; при наличии мьютексов здесь имеем:
	; r0 - номер нового потока
	; r25 - номер потока, от имени которого запускается новый поток
	; Y - адрес TSB нового потока
	; Z - адрес TSB старого потока
	;
	; при отсутствии мьютексов здесь имеем:
	; r25 - номер нового потока
	; Y - адрес TSB нового потока
	; Z - адрес TSB старого потока
	;
	; все прочие регистры сохранены, прерывания разрешены
	; текущий стек -- стек прерываний
	;
	; OS_CurTSBindex и OS_CurTSB уже указывают на новый поток
	;

; V. Восстанавливаем контекст нового потока
	movw	Z, Y

	; переносим регистры ZH и ZL из TSB потока в стек прерываний
	; восстанавливать регистры ZH и ZL будем перед возвратом в поток
	ldd	r26, Z+SaveR30
	ldd	r27, Z+SaveR31
	pushw	r26


#if !TotalMutexes
	ldd	r26, Z+SaveR26	; XL
	ldd	r27, Z+SaveR27	; XH
#endif /* !TotalMutexes */

#if defined( RAMPD ) && !defined( NoSaveRAMPD )
	ldd	r23, Z+SaveRAMPD
	out	RAMPD, r23
#endif /* RAMPD */

#if defined( RAMPX ) && !defined( NoSaveRAMPX )
	ldd	r23, Z+SaveRAMPX
	out	RAMPX, r23
#endif /* RAMPX */

#if defined( RAMPY ) && !defined( NoSaveRAMPY )
	ldd	r23, Z+SaveRAMPY
	out	RAMPY, r23
#endif /* RAMPY */

#if defined( RAMPZ ) && !defined( NoSaveRAMPZ )
	ldd	r23, Z+SaveRAMPZ
	out	RAMPZ, r23
#endif /* RAMPZ */

#if defined( EIND ) && !defined( NoSaveEIND )
	ldd	r23, Z+SaveEIND
	out	EIND, r23
#endif /* EIND */

#if SaveR2
	ldd	r2, Z+SaveR2
#endif /* SaveR2 */
#if SaveR3
	ldd	r3, Z+SaveR3
#endif /* SaveR3 */
#if SaveR4
	ldd	r4, Z+SaveR4
#endif /* SaveR4 */
#if SaveR5
	ldd	r5, Z+SaveR5
#endif /* SaveR5 */
#if SaveR6
	ldd	r6, Z+SaveR6
#endif /* SaveR6 */
#if SaveR7
	ldd	r7, Z+SaveR7
#endif /* SaveR7 */
#if SaveR8
	ldd	r8, Z+SaveR8
#endif /* SaveR8 */
#if SaveR9
	ldd	r9, Z+SaveR9
#endif /* SaveR9 */
#if SaveR10
	ldd	r10, Z+SaveR10
#endif /* SaveR10 */
#if SaveR11
	ldd	r11, Z+SaveR11
#endif /* SaveR11 */
#if SaveR12
	ldd	r12, Z+SaveR12
#endif /* SaveR12 */
#if SaveR13
	ldd	r13, Z+SaveR13
#endif /* SaveR13 */
#if SaveR14
	ldd	r14, Z+SaveR14
#endif /* SaveR14 */
#if SaveR15
	ldd	r15, Z+SaveR15
#endif /* SaveR15 */
#if SaveR16
	ldd	r16, Z+SaveR16
#endif /* SaveR16 */
#if SaveR17
	ldd	r17, Z+SaveR17
#endif /* SaveR17 */
#if SaveR18
	ldd	r18, Z+SaveR18
#endif /* SaveR18 */
#if SaveR19
	ldd	r19, Z+SaveR19
#endif /* SaveR19 */
#if SaveR20
	ldd	r20, Z+SaveR20
#endif /* SaveR20 */
#if SaveR21
	ldd	r21, Z+SaveR21
#endif /* SaveR21 */
#if SaveR22
	ldd	r22, Z+SaveR22
#endif /* SaveR22 */
#if SaveR23
	ldd	r23, Z+SaveR23
#endif /* SaveR23 */


ThreadIsSame:
	; при неизменном потоке нужно восстанавливать измененные регистры
#if STOP_IN_ISR
	sei
#endif /* STOP_IN_ISR */
	ldd	r0, Z+SaveR0
	ldd	r1, Z+SaveR1
	ldd	r29, Z+SaveR29	; YH
	ldd	r28, Z+SaveR28	; YL
#if TotalMutexes
	ldd	r27, Z+SaveR27	; XH
	ldd	r26, Z+SaveR26	; XL
#endif /* TotalMutexes */
	cli
	; проверяем необходимость преключения на другой поток
	; (пока сохраняли/восстанавливали контексты потоков, мог
	; быть активизирован ещё один поток)
	.if OS_Reg_isAbsent
	lds	OS_wReg, OS_Flags
	sbrs	OS_wReg, 0
	rjmp	FindActiveThread	; необходимо изменить активный поток
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg + OS_Reg_isHiReg
	sbrs	OS_Reg, 0
	rjmp	FindActiveThread	; необходимо изменить активный поток
	.endif	; OS_Reg_isLoReg + OS_Reg_isHiReg

	.if OS_Reg_isLoIO
	sbis	OS_Reg, 0
	rjmp	FindActiveThread	; необходимо изменить активный поток
	.endif	; OS_Reg_isLoIO

	.if OS_Reg_isHiIO + OS_Reg_isVarIO
	in	OS_wReg, OS_Reg
	sbrs	OS_wReg, 0
	rjmp	FindActiveThread	; необходимо изменить активный поток
	.endif	; OS_Reg_isHiIO + OS_Reg_isVarIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

	; восстанавливаем регистры R24 и R25
	; или забираем из TSB возвращаемое в поток значение
	; (если поток был блокирован вызовом блокирующей функции)
	ldd	r24, Z+SaveR24
	ldd	r25, Z+SaveR25

	; восстанавливаем регистры ZH и ZL
	popw	Z

	ReturnToThread_code



OS_Scheduler_SuspendThread:	.global	OS_Scheduler_SuspendThread
; переход из потока в диспетчер потоков без сохранения следующих регистров:
; r0, r24, r25, r26, r27, r30, r31
; используется для приостановки потока в функциях с ожиданием: Suspend,
; Sleep, Thread_Prepare(OS_CurTSBindex, ...), ..Get.., ..Wait.., ..Watch..,
; ..Close..
; На входе:
;	регистры ZH:ZL: адрес TSB текущего потока
;	текущий стек: стек потока (обязательно!)
;	прерывания должны быть запрещены (для сохранения значений
;	  в полях SaveR24, SaveR25 структуры TSB)

	; готовим стек потока
	push	OS_wReg
	in	OS_wReg, SREG	; сохраняем бит T
	push	OS_wReg
	; делать что-либо с флагом I не нужно: перед возвратом в поток
	; прерывания обязательно разрешаем

	; в стеке прерываний должны сохранить регистры ZH и ZL,
	; но так как их содержимое роли не играет, то просто отводим
	; для них место
#if __AVR_HAVE_SPH__

#if defined( iSPH )
	in	iSPL, SPL
	in	iSPH, SPH
#else /* !defined( iSPH ) */
	in	OS_wReg, SPL
	sts	ISR_SPsave, OS_wReg
	in	OS_wReg, SPH
	sts	ISR_SPsave+1, OS_wReg
#endif /* defined( iSPH ) */
	; set new value in SPH:SPL
	ldi	OS_wReg, Low( ISR_Stack_Top-2 )
	out	SPL, OS_wReg
	ldi	OS_wReg, High( ISR_Stack_Top-2 )
	sei
	out	SPH, OS_wReg

#else /* !__AVR_HAVE_SPH__ */

#if defined( iSPL )
	in	iSPL, SPL
#else /* !defined( iSPL ) */
	in	OS_wReg, SPL
	sts	ISR_SPsave, OS_wReg
#endif /* defined( iSPL ) */
	; set new value in SPL
	ldi	OS_wReg, Low( ISR_Stack_Top-2 )
	sei
	out	SPL, OS_wReg

#endif /* __AVR_HAVE_SPH__ */

;	pushw	Z	регистры ZH и ZL уже "сохранили" в стеке прерываний
	rjmp	OS_Scheduler_Suspend_Internal



.size	OS_Scheduler, . - OS_Scheduler


;
; wordset:avr-gcc-os
;
; End of file  scheduler.S
