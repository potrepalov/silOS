; share/avr/silOS/occur-1.S
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

.global Event_Occur_One
.type	Event_Occur_One, @function

Event_Occur_One:
; RegType_t Event_Occur_One( Event_t event )
; Посылает событие наиболее приоритетному потоку из тех, которые его ожидают.
; Возвращает не 0, если был поток, ожидавший данное событие.
; Возвращает 0, если потока, ожидающего данное событие, не было.
; Значение номера события должно быть в диапазоне 1..NumEvents(+NumSignals)
; включительно (значения из диапазона от NumEvents+1 до NumEvents+NumSignals
; используются операционной системой; см. Signal_Set).
;
; На входе:
;	регистр r24: номер события
; На выходе:
;	регистр r24: 0 -- события ни один поток не ожидал
;	          не 0 -- нашли поток, ожидавший данное событие
; Портит регистры: r25, ZL, ZH
;
; Если функция вызывается из обработчика прерывания
; (с разрешёнными прерываниями), то должен использоваться стек прерываний

#if START_EVENTS != 1
	subi	r24, (0 - (START_EVENTS-1))
#endif /* START_EVENTS */
	.if OS_Reg_isHiReg
	addi	OS_Reg, 2
	.else
	rcall	Scheduler_Lock
	.endif	; OS_Reg_isHiReg

Event_Occur_One_Internal:.global Event_Occur_One_Internal
	letw	Z, OS_TSBs
Loop:	; цикл по потокам
	;
	; поведение будет зависить от того, что произойдёт раньше:
	; здесь считаем поле BlockingRes или макрос OS_TICK обнулит это поле;
	; но это соответствует двум случаям: поток дождался или не дождался
	; события, и в любом случае состояние потока будет вполне определённым

	ldd	r25, Z+BlockingRes
	sub	r25, r24
	breq	Found
	; переходим к следующему потоку
	adiw	Z, SizeOfTSB
	cpi	ZL, Low(OS_TSBs + NumThreads*SizeOfTSB)
	brne	Loop
#if LONG_TSBS
	cpi	ZH, High(OS_TSBs + NumThreads*SizeOfTSB)
	brne	Loop
#endif /* LONG_TSBS */
	; не нашли ни одного потока, ожидающего данное событие
	clr	r24
	rjmp	Scheduler_Unlock


Found:	; нашли поток, который ожидает данное событие
	; в этом месте возможна гонка (race condition):
	; поток мог ожидать событие с таймаутом,
	; и таймаут наступил как раз в этом месте
	; (и макрос OS_TICK активизировал поток и уже изменил значение
	; полей BlockingRes, SleepCounter и SaveR24);
	; но нам это уже неважно: поток события дождался

	; поток дождался события, активизируем его
	ldi	r24, 1
	std	Z+BlockingRes, r25	; r25 === 0
#if BIG_SLEEP
	std	Z+SleepCounter+1, r25
#endif /* BIG_SLEEP */
	std	Z+SleepCounter, r25
	std	Z+SaveR24, r24

	.if OS_Reg_isAbsent
	in	ZL, SREG
	cli
	lds	r25, OS_Flags
	andi	r25, ~1
	out	SREG, ZL
	sts	OS_Flags, r25
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	in	ZL, SREG
	cli
	sbrc	OS_Reg, 0
	dec	OS_Reg
	out	SREG, ZL
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	andi	OS_Reg, ~1
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	in	ZL, SREG
	cli
	in	r25, OS_Reg
	andi	r25, ~1
	out	SREG, ZL
	out	OS_Reg, r25
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

	rjmp	Scheduler_Unlock

.size	Event_Occur_One, . - Event_Occur_One


#endif /* NumEvents + NumSignals */


;
; wordset:avr-gcc-os
;
; End of file  occur-1.S
