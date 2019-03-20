; share/avr/silOS/init.S
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


.macro	Init_ISR_Stack
	; готовим стек прерываний
#if RA_Stack_Space == 3

	ldi	ZL, lo8(pm(OS_Scheduler))
	sts	ISR_Stack_End, ZL
	ldi	ZL, hi8(pm(OS_Scheduler))
	sts	ISR_Stack_End - 1, ZL
	ldi	ZL, hlo8(pm(OS_Scheduler))
	sts	ISR_Stack_End - 2, ZL
;	ldi	ZL, 0
;	sts	ISR_Stack_End - 3, ZL	fake OS_wReg is not needed
#if !defined( iSREG ) || __ATXMEGA__
	ldi	ZL, (1 << SREG_I)	; fake SREG, enable interrupts
	sts	ISR_Stack_End - 4, ZL
#endif /* defined( iSREG ) || __ATXMEGA__ */

#else /* RA_Stack_Space != 3 */

	ldi	ZL, lo8(pm(OS_Scheduler))
	sts	ISR_Stack_End, ZL
	ldi	ZL, hi8(pm(OS_Scheduler))
	sts	ISR_Stack_End - 1, ZL
;	ldi	ZL, 0
;	sts	ISR_Stack_End - 2, ZL	fake OS_wReg is not needed
#if !defined( iSREG ) || __ATXMEGA__
	ldi	ZL, (1 << SREG_I)	; fake SREG, enable interrupts
	sts	ISR_Stack_End - 3, ZL
#endif /* defined( iSREG ) || __ATXMEGA__ */

#endif /* RA_Stack_Space == 3 */

	; на дне стека прерываний находятся следующие значения
	;  - поддельный регистр SREG (если это atXmega или нет регистра iSREG)
	;  - поддельный регистр OS_wReg
	;  - адрес точки входа в диспетчер потоков OS_Scheduler (для перехода
	;    к диспетчеру потоков при выходе из прерываний)

.endm	; Init_ISR_Stack



#if !NO_OS_INIT

	; функция OS_Init вызывается явно


	.section	".text.OS", "x"

.global OS_Init
.type	OS_Init, @function

OS_Init:
; void OS_Init( void )
; Инициализирует переменные операционной системы и потоки.
; Все вызовы функции OS_Init можно выполнять только из потока
; с наибольшим номером.
;
; На входе:
;	регистр r1: ноль

	in	r0, SREG
	cli

	Init_ISR_Stack

	; запрещаем переключать потоки

	.if OS_Reg_isAbsent
	ldi	r24, 3
	sts	OS_Flags, r24
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	ldi	r24, 3
	mov	OS_Reg, r24
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	ldi	OS_Reg, 3
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	ldi	r24, 3
	out	OS_Reg, r24
	.endif	; OS_Reg_isIO


	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		


	; считаем, что сейчас выполняется поток с наибольшим номером
	ldi	XL, NumThreads
	sts	OS_CurTSBindex, XL
#if STOP_IN_ISR
	sts	OS_ThreadInProcess, r1
#endif /* STOP_IN_ISR */

	out	SREG, r0

	letw	Z, OS_TSBs + (NumThreads-1)*SizeOfTSB
	stsw	OS_CurTSB, Z
#if BIG_SLEEP
	std	Z+SleepCounter+1, r1
#endif /* BIG_SLEEP */
	std	Z+SleepCounter, r1
#if __BlockingRes
	std	Z+BlockingRes, r1
#endif /* __BlockingRes */

#if NumThreads > 1
#if NumThreads == 2
#if !NO_THREAD_KILL
	; есть функция Thread_Kill - прибиваем поток 1
	ldi	r24, 1
	rcall	Thread_Kill
#else /* NO_THREAD_KILL */
#if !NO_STOP
	; есть функция Stop -- назначаем потоку 1 эту функцию
	ldi	r24, 1
	letw	r22, Stop
	rcall	Thread_Prepare
#else /* NO_STOP */
	; функций нет, блокируем поток 1
#if __BlockingRes
	sbiw	Z, SizeOfTSB
	ldi	r24, 0xFF
	std	Z+BlockingRes, r24
	std	Z+SleepCounter, r1
#if BIG_SLEEP
	std	Z+SleepCounter+1, r1
#endif /* BIG_SLEEP */
#else /* !__BlockingRes */
	ldi	r24, 1
#if BIG_SLEEP
	sts	OS_TSBs+SleepCounter, r24
#else /* !BIG_SLEEP */
	sbiw	Z, SizeOfTSB
	std	Z+SleepCounter, r24
	std	Z+SleepCounter+1, r1
#endif /* BIG_SLEEP */
#endif /* __BlockingRes */
#endif /* NO_STOP */
#endif /* NO_THREAD_KILL */
#else /* NumThread != 2 */
#if !NO_THREAD_KILL

	; есть функция Thread_Kill - прибиваем все потоки
	push	YL
	ldi	YL, 1
1:	mov	r24, YL
	rcall	Thread_Kill
	inc	YL
	cpi	YL, NumThreads
	brne	1b
	pop	YL

#else /* NO_THREAD_KILL */
#if !NO_STOP

	; есть функция Stop - назначаем всем потокам эту функцию
	push	YL
	ldi	YL, 0 - NumThreads + 1
1:	mov	r24, YL
	letw	r22, Stop
	rcall	Thread_Prepare
	inc	YL
	brne	1b
	pop	YL

#else /* NO_STOP */

	; функций нет, блокируем все потоки
#if LONG_TSBS
	ldi	r23, High(OS_TSBs)
#endif /* LONG_TSBS */
#if __BlockingRes
	ldi	r24, 0xFF
1:	sbiw	Z, SizeOfTSB
	std	Z+BlockingRes, r24
	std	Z+SleepCounter, r1
#else /* !__BlockingRes */
	ldi	r24, 1
1:	sbiw	Z, SizeOfTSB
	std	Z+SleepCounter, r24
#endif /* __BlockingRes */
#if BIG_SLEEP
	std	Z+SleepCounter+1, r1
#endif /* BIG_SLEEP */
	cpi	ZL, Low(OS_TSBs)
#if LONG_TSBS
	cpc	ZH, r23
#endif /* LONG_TSBS */
	brne	1b

#endif /* NO_STOP */
#endif /* NO_THREAD_KILL */
#endif /* NumThreads == 2 */
#endif /* NumThreads */

	; разрешаем переключать потоки
	rjmp	Scheduler_Unlock

.size	OS_Init, . - OS_Init


#else /* NO_OS_INIT */

	; функция OS_Init явно не вызывается
	; для инициализации используем возможности компилятора


	.section	".init8", "x"

.global OS_Init
.type	OS_Init, @function

;OS_Init:	функция не имеет имени, т.к. размещается в коде инициализации
; void OS_Init( void )
; Инициализация переменных ядра многозадачности
; На входе:
;	регистр r1: ноль
;	прерывания запрещены

	.if OS_Reg_isAbsent
	; OS_Flags инициализирует компилятор
	.endif

	.if OS_Reg_isLoReg
	ldi	r24, 1
	mov	OS_Reg, r24
	.endif

	.if OS_Reg_isHiReg
	ldi	OS_Reg, 1
	.endif

	.if OS_Reg_isIO
	ldi	r24, 1
	out	OS_Reg, r24
	.endif

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		


	Init_ISR_Stack

;.size	OS_Init, . - OS_Init


#endif /* NO_OS_INIT */


;
; wordset:avr-gcc-os
;
; End of file  init.S
