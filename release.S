; share/avr/silOS/release.S
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


#if TotalMutexes


	.section	".text.OS", "x"

.global Mutex_Release
.type	Mutex_Release, @function

Mutex_Release:
; void Mutex_Release( Mutex_t mut )
; Освобождает мьютекс.
;
; На входе:
;	регистр r24: номер мьютекса
;	регистр r1: ноль
; Портит регистры: r0, r24, r25, XL, XH, ZL, ZH
;
; Если функция вызывается из обработчика прерывания при разрешённых прерываниях,
; то должен использоваться стек прерываний

	letw	X, OS_Mutexes - 1
	add	XL, r24
	adc	XH, r1

	; проверка, что мьютекс освобождает именно тот поток,
	; который им владеет
;	adiw	X, NumCMutexes
;	ld	ZH, X	; ZH - индекс TSB потока, который владел мьютексом
;	sbiw	X, NumCMutexes
;	lds	ZL, OS_CurTSBindex
;	cp	ZL, ZH
;	brne	9f

#if NumCMutexes
	; уменьшаем счетчик вложенности для данного мьютекса
#if NumCMutexes != TotalMutexes
	cpi	r24, NumCMutexes+1
	brcc	NoCmutex
#endif /* NumCMutexes != TotalMutexes */
	in	r0, SREG
	cli
	ld	r25, X
	subi	r25, 1
	brcs	RelMutex
	st	X, r25
	brne	RestoreIret
RelMutex:
	out	SREG, r0
NoCmutex:
#if NumCMutexes < 64
	adiw	X, NumCMutexes
#else /* NumCMutexes >= 64 */
	subi	XL, Low( 0-NumCMutexes )
	sbci	XH, High( 0-NumCMutexes )
#endif /* NumCMutexes < 64 */
#endif /* NumCMutexes */
	.if OS_Reg_isHiReg
	addi	OS_Reg, 2
	.else
	rcall	Scheduler_Lock
	.endif	; OS_Reg_isHiReg
	; ищем самый приоритетный поток, который
	; был блокирован ожиданием этого мьютекса
	letw	Z, OS_TSBs
	ldi	r25, NumThreads - 1
1:	ldd	r0, Z+BlockingRes
	cp	r0, r24
	breq	Found		; нашли
	adiw    Z, SizeOfTSB
	subi	r25, 1
	brcc	1b
	; ни один поток не ожидает данный мьютекс
	; освобождаем мьютекс
	st	X, r1
	rjmp	Scheduler_Unlock
#if NumCMutexes
RestoreIret:
	out	SREG, r0
	ret
#endif /* NumCMutexes */


Found:	; нашли наиболее приоритетный поток, который ожидал освобождаемый
	; мьютекс (номер этого потока: NumThreads - r25)
	; активизируем поток и возвращаем ему значение 1: мьютекс захвачен

	; вычисляем номер активизируемого потока
	subi	r25, NumThreads	; r25 - NumThreads
	neg	r25		; NumThreads - r25
	; активизируем поток
	in	r0, SREG
	cli
#if BIG_SLEEP
	std	Z+SleepCounter+1, r1
#endif /* BIG_SLEEP */
	std	Z+SleepCounter, r1	; обнуляем счётчик сна
	std	Z+BlockingRes, r1

	; занимаем мьютекс (тем потоком, который активизировали)
	st	X, r25

#if NumCMutexes
#if NumCMutexes != TotalMutexes
	cpi	r24, NumCMutexes + 1
	ldi	r24, 1
	brcc	NoCmutex2
#else /* NumCMutexes == TotalMutexes */
	ldi	r24, 1
#endif /* NumCMutexes != TotalMutexes */
#if NumCMutexes < 64
	sbiw	X, NumCMutexes
#else /* NumCMutexes >= 64 */
	subi	X, Low( NumCMutexes )
	sbci	X, High( NumCMutexes )
#endif /* NumCMutexes < 64 */
	st	X, r24		; мьютекс захвачен один раз
NoCmutex2:
#else /* !NumCMutexes */
	ldi	r24, 1		; возвращаемое в поток значение
#endif /* NumCMutexes */

	; меняем возвращаемое в ожидавший мьютекс поток значение на 1
	std	Z+SaveR24, r24
	; осталось разблокировать планировщик потоков и искать
	; наиболее приоритетный активный поток
	sbrc	r0, SREG_I
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

	ret

InterruptsEnabled:
	; прерывания были разрешены

	.if OS_Reg_isAbsent
	lds	r31, OS_Flags
	andi	r31, ~1
	rjmp	_silOS_Unlock_Release
	.endif	; OS_Reg_isAbsent


	.if OS_Reg_isLoReg
	mov	r31, OS_Reg
	andi	r31, ~1
	rjmp	_silOS_Unlock_Release
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	sei
	andi	OS_Reg, ~1
	subi	OS_Reg, 2
	breq	_silOS_Unlock_Release
	ret
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	in	r31, OS_Reg
	andi	r31, ~1
	rjmp	_silOS_Unlock_Release
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

;9:	; FIXME: ресурс освобождает не тот поток, который его захватил
;	rjmp	9b

.size	Mutex_Release, . - Mutex_Release


#endif /* TotalMutexes */


; Случай, когда функция Release вызывается во время обработки прерывания,
; которе случилось во время работы функции Release, ничем не отличается
; от случая, когда функция Release вызывается во время обработки прерывания
; непосредственно перед или сразу после работы функции Release в потоке.
;
; Также см. замечания к функции Mutex_Owner


;
; wordset:avr-gcc-os
;
; End of file  release.S
