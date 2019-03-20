; share/avr/silOS/up.S
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

.global Semaphore_Up
.type	Semaphore_Up, @function

.global Semaphore_Post
.type	Semaphore_Post, @function

.global Semaphore_Open
.type	Semaphore_Open, @function

Semaphore_Up:
Semaphore_Post:
Semaphore_Open:
; SemaphoreCounter_t Semaphore_Up( Semaphore_t sem )
; Увеличивает счетчик семафора на 1 (открывает семафор).
; При необходимости, активизирует поток (только один поток), который
; ожидает открытия данного семафора.
;
; На входе:
;	регистр r24: номер семафора
;	регистр r1: ноль
; На выходе:
;	регистр r24: новое значение счетчика семафора (возможно 0)
; Портит регистры: r0, r25, XL, XH, ZL, ZH

	letw	X, OS_Semaphores-1
	add	XL, r24
	adc	XH, r1
	in	r25, SREG
	cli
	ld	r0, X
	tst	r0
	brne	Fast		; в семафоре не 0, увеличиваем значение на 1
	; в семафоре 0, нужно искать поток, который ожидает данный
	; семафор; для того, чтобы состояние уже проанализированных потоков
	; не изменилось, блокируем работу диспетчера потоков
	.if OS_Reg_isHiReg
	out	SREG, r25
	addi	OS_Reg, 2
	.else
	rcall	Scheduler_Lock
	out	SREG, r25
	.endif	; OS_Reg_isHiReg
	; сейчас ещё нельзя менять состояние счетчика семафора:
	; в прерываниях могут ещё не раз вызвать функцию Semaphore_Up для
	; этого же семафора, и в этом случае нужно будет разблокировать
	; не один, а несколько потоков (если же мы установим счетчик
	; семафора в 1, то последующие вызовы Semaphore_Up не будут
	; разблокировать потоки)

	; если найдём такой поток, который ожидает данный семафор,
	; то возвращать надо будет 0
#if START_SEMAPHORES != 1
	subi	r24, Low(0-(START_SEMAPHORES-1))
#endif /* START_SEMAPHORES */
	letw	Z, OS_TSBs
3:	cli
	ldd	r0, Z+BlockingRes
	sub	r0, r24
	breq	Found		; нашли поток, который ожидал данный семафор
	out	SREG, r25
	adiw	Z, SizeOfTSB
	cpi	ZL, Low(OS_TSBs+SizeOfTSB*NumThreads)
	brne	3b
#if LONG_TSBS
	cpi	ZH, High(OS_TSBs+SizeOfTSB*NumThreads)
	brne	3b
#endif /* LONG_TSBS */
	; не нашли потока, который бы ожидал данный семафор
	; состояние семафора уже могло измениться (в прерывании, например)
	cli
	ld	r24, X
	inc	r24
	out	SREG, r25
	st	X, r24
	rjmp	Scheduler_Unlock

Fast:	; увеличиваем значение в счетчике семафора и возвращаемся
	inc	r0
	out	SREG, r25
	st	X, r0
	mov	r24, r0
	ret

Found:	; нашли поток, которому нужен данный семафор
	; прерывания запрещены
	; разблокируем поток
#if BIG_SLEEP
	std	Z+SleepCounter+1, r1
#endif /* BIG_SLEEP */
	std	Z+SleepCounter, r1
	std	Z+BlockingRes, r1
	ldi	r24, 1		; в поток возвращаем 1
	std	Z+SaveR24, r24

	; возвращаем 0, т.к. значение семафора было 0, и мы его не меняли
	; если же значение семафора изменится после Scheduler_Unlock, то
	; это уже логика работы программы (другие потоки, прерывания...)
	clr	r24

	; осталось разблокировать планировщик потоков и искать
	; наиболее приоритетный активный поток
	sbrc	r25, SREG_I
	rjmp	InterruptsEnabled
	; прерывания были запрещены

	.if OS_Reg_isAbsent
	lds	r31, OS_Flags
	andi	r31, ~1
	subi	r31, 2
	sts	OS_Flags, r31
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	sbrc	OS_Reg, 0
	dec	OS_Reg
	dec	OS_Reg
	dec	OS_Reg
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	andi	OS_Reg, ~1
	subi	OS_Reg, 2
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	in	r31, OS_Reg
	andi	r31, ~1
	subi	r31, 2
	out	OS_Reg, r31
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

4:	ret

InterruptsEnabled:
	; прерывания были разрешены

	.if OS_Reg_isAbsent
	lds	r31, OS_Flags
	andi	r31, ~1
	rjmp	_silOS_Unlock_Up
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	mov	r31, OS_Reg
	andi	r31, ~1
	rjmp	_silOS_Unlock_Up
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	sei
	andi	OS_Reg, ~1
	subi	OS_Reg, 2
	brne	4b
	rjmp	_silOS_Unlock_Up
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	in	r31, OS_Reg
	andi	r31, ~1
	rjmp	_silOS_Unlock_Up
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

.size	Semaphore_Up, . - Semaphore_Up
.size	Semaphore_Post, . - Semaphore_Post
.size	Semaphore_Open, . - Semaphore_Open


#endif /* NumSemaphores */


;
; wordset:avr-gcc-os
;
; End of file  up.S
