; share/avr/silOS/occur.S
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


#if NumEvents + NumSignals


	.section	".text.OS", "x"

.global Event_Occur
.type	Event_Occur, @function

Event_Occur:
; RegType_t Event_Occur( Event_t event )
; Посылает событие всем потокам, которые его ожидают.
; Возвращает не 0, если был хотя бы один поток, ожидавший данное событие.
; Возвращает 0, если не было ни одного потока, ожидающего данное событие.
; Значение номера события должно быть в диапазоне 1..NumEvents(+NumSignals)
; включительно (значения из диапазона от NumEvents+1 до NumEvents+NumSignals
; используются операционной системой; см. Signal_Set).
;
; На входе:
;	регистр r24: номер события
; На выходе:
;	регистр r24: 0 -- события ни один поток не ожидал
;	          не 0 -- событие ожидал хотя бы один поток
; Портит регистры: r25, XL, XH, ZL, ZH
;
; Если функция вызывается из обработчика прерывания при разрешённых прерываниях,
; то должен использоваться стек прерываний

#if START_EVENTS != 1
	subi	r24, (0 - (START_EVENTS-1))
#endif /* START_EVENTS */
	.if OS_Reg_isHiReg
	addi	OS_Reg, 2
	.else
	rcall	Scheduler_Lock
	.endif	; OS_Reg_isHiReg

Event_Occur_Internal:.global Event_Occur_Internal
	mov	XH, r24
	clr	r24		; возвращаемое значение (кол-во потоков)
	; в потоки, ожидающие данное событие, необходимо вернуть значение 1
	ldi	r25, 1
	letw	Z, OS_TSBs
Loop:	; цикл по потокам
	;
	; поведение будет зависить от того, что произойдёт раньше:
	; здесь считаем поле BlockingRes или макрос OS_TICK обнулит это поле;
	; но это соответствует двум случаям: поток дождался или не дождался
	; события, и в любом случае состояние потока будет вполне определённым

	ldd	XL, Z+BlockingRes
	sub	XL, XH
	breq	Found		; нашли поток, который ожидал событие
Next:	; переходим к следующему потоку
	adiw	Z, SizeOfTSB
	cpi	ZL, Low(OS_TSBs + NumThreads*SizeOfTSB)
	brne	Loop
#if LONG_TSBS
	cpi	ZH, High(OS_TSBs + NumThreads*SizeOfTSB)
	brne	Loop
#endif /* LONG_TSBS */
	; если активизировали хотя бы один поток, то нужно снова
	; искать наиболее приоритетный активный поток

	tst	r24
	breq	Scheduler_Unlock

	; т.к. это единственное место, где происходит активизация
	; потока с последующей разблокировкой планировщика,
	; сделаем небольшую оптимизацию

	brie	InterruptsEnabled
	; прерывания запрещены

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
	; прерывания разрешены

	.if OS_Reg_isAbsent
	cli
	lds	r31, OS_Flags
	andi	r31, ~1
	rjmp	_silOS_Unlock_Occur
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	cli
	mov	r31, OS_Reg
	andi	r31, ~1
	rjmp	_silOS_Unlock_Occur
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	andi	OS_Reg, ~1
	subi	OS_Reg, 2
	breq	_silOS_Unlock_Occur
	ret
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	cli
	in	r31, OS_Reg
	andi	r31, ~1
	rjmp	_silOS_Unlock_Occur
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		


Found:	; в этом месте возможна гонка (race condition):
	; поток мог ожидать событие с таймаутом,
	; и таймаут наступил как раз в этом месте
	; (и макрос OS_TICK активизировал поток и уже изменил значение
	; полей BlockingRes, SleepCounter и SaveR24);
	; но нам это уже неважно: считаем, что поток события дождался

	; поток дождался события, активизируем его
	std	Z+BlockingRes, XL	; XL === 0
#if BIG_SLEEP
	std	Z+SleepCounter+1, XL
#endif /* BIG_SLEEP */
	std	Z+SleepCounter, XL
	std	Z+SaveR24, r25		; в поток возвращаем 1
	inc	r24
	rjmp	Next

.size	Event_Occur, . - Event_Occur


#endif /* NumEvents + NumSignals */


;
; wordset:avr-gcc-os
;
; End of file  occur.S
