; share/avr/silOS/get.S
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


	.section        ".text.OS", "x"

.global Mutex_Get
.type   Mutex_Get, @function

.global Mutex_GetWithTimeout
.type   Mutex_GetWithTimeout, @function


Mutex_Get:
; RegType_t Mutex_Get( Mutex_t mut )
; Захват мьютекса с блокировкой.
; После захвата мьютекса разрешает прерывания и разблокирует диспетчер потоков.
; Если мьютекс занят, разрешает прерывания, разблокирует диспетчер потоков
; и бесконечно долго ожидает его освобождения.
;
; На входе:
;	регистр r24: номер мьютекса
;	регистр r1: ноль
; На выходе:
;	регистр r24: 1 -- успешный захват мьютекса
;	             3 -- повторный захват мьютекса
;	             4 -- мьютекс не захвачен; взаимная блокировка (deadlock)
;	           240 -- мьютекс не захвачен; поток активизирован
;	                  Функцией Thread_Activate
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.
; Функция разрешает прерывания и разблокирует диспетчер потоков.

	clr     r22             ; обнуляем таймаут
#if BIG_SLEEP
	clr     r23
#endif /* BIG_SLEEP */

Mutex_GetWithTimeout:
; RegType_t GetWithTimeout( Mutex_t mut, SleepTime_t ticks )
; Захват мьютекса с блокировкой и таймаутом.
; После захвата мьютекса разрешает прерывания и разблокирует диспетчер потоков.
; Если мьютекс занят, разрешает прерывания, разблокирует диспетчер потоков
; и ожидает его освобождения в течении указаного времени.
;
; На входе:
;	регистр r24: номер мьютекса
;	регистр r22: длительность ожидания освобождения мьютекса;
;	             если определён макрос BIG_SLEEP, то для передачи
;	             времени используется пара регистров r23:r22
;	регистр r1: ноль
; На выходе:
;	регистр r24: 0 -- мьютекс не захвачен; выход по таймауту
;	             1 -- успешный захват мьютекса
;	             3 -- повторный захват мьютекса
;	             4 -- мьютекс не захвачен; взаимная блокировка (deadlock)
;	           240 -- мьютекс не захвачен; поток активизирован
;	                  Функцией Thread_Activate
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.
; Функция разрешает прерывания и разблокирует диспетчер потоков.

	letw    X, OS_Mutexes + NumCMutexes - 1
	add     XL, r24
	adc     XH, r1
	lds     r20, OS_CurTSBindex
	ldi     r25, 240        ; возвращаемое значение

	; блокируем переключение потоков
	.if OS_Reg_isHiReg
	addi    OS_Reg, 2
	.elseif OS_Reg_isLoReg
	ldi     r31, 2
	add     OS_Reg, r31
	.else
	rcall	Scheduler_Lock
	.endif	; OS_Reg_isHiReg

	ldsw    Z, OS_CurTSB

	; операции анализа и захвата мьютекса должны выполняться атомарно
	cli
	ld      r21, X          ; определяем, кто владеет мьютексом
	tst     r21
	breq    occupyMutex     ; мьютекс свободен
	; мьютекс занят
	cp      r21, r20
	breq    repeatOccupy    ; повторный захват мьютекса
	; мьютекс занят, надо ждать его освобождения

	; блокируем текущий поток
	std     Z+BlockingRes, r24
#if BIG_SLEEP
	std     Z+SleepCounter+1, r23
#endif /* BIG_SLEEP */
	std     Z+SleepCounter, r22
	sei                     ; обязательно разрешаем прерывания
	std     Z+SaveR24, r25  ; возвращаемое значение 240

	; r20 -- номер текущего потока
	; r21 -- номер потока-владельца мьютекса
	; r24 -- mutexID
	; r25 -- 240
	; Z -- OS_CurTSB

#if __AVR_HAVE_MUL__
	ldi     r20, SizeOfTSB
#endif /* __AVR_HAVE_MUL__ */

loop:
	; определяем, что ожидает поток-владелец мьютекса
	; вычисляем адрес TSB потока-владельца (в регистрах XH:XL)
	letw    X, OS_TSBs - SizeOfTSB + BlockingRes
#if __AVR_HAVE_MUL__
	mul     r20, r21
	addw    X, r0
#else /* !__AVR_HAVE_MUL__ */
 #if SizeOfTSB <= 31
	subi    r21, 2
	brcs    1f
2:	adiw    X, 2 * SizeOfTSB
	subi    r21, 2
	brcc    2b
	sbrc    r21, 0
1:	adiw    X, SizeOfTSB
 #else /* SizeOfTSB > 31 */
1:	adiw    X, SizeOfTSB
	dec     r21
	brne    1b
 #endif /* SizeOfTSB <= 31 */
#endif /* __AVR_HAVE_MUL__ */

#if __AVR_HAVE_MUL__ && (SizeOfTSB * (NumThreads) > 255)
	; перед уходом в диспетчер потоков нужно будет обнулить r1
#else
#define suspend_thread  OS_Scheduler_SuspendThread
#endif

	ld      XL, X           ; XL := TSBs[x].resourceID
	tst     XL
	breq    suspend_thread  ; поток-владелец мьютекса ничего не ждёт

	cpi     XL, (TotalMutexes) + 1
	brcc    suspend_thread  ; ждёт не мьютекс
	; поток-владелец мьютекса тоже ждёт мьютекс (номер мьютекса в XL)

	; определим, кто владеет мьютексом
	clr     XH
	addiw   X, OS_Mutexes + NumCMutexes - 1
	ld      r21, X

	; r20 -- номер текущего потока
	cp      r21, r20
	brne    loop            ; мьютексом владеет не текущий поток

	; мьютексом владеет текущий поток, обнаружили взаимную блокировку
	; активизируем текущий поток
#if __AVR_HAVE_MUL__ && (SizeOfTSB * (NumThreads) > 255)
	clr     r1
#endif
	cli
#if BIG_SLEEP
	std     Z+SleepCounter+1, r1
#endif /* BIG_SLEEP */
	std     Z+SleepCounter, r1
	std     Z+BlockingRes, r1
	sei
	ldd     r24, Z+SaveR24  ; там было 240

	; поток мог получить мьютекс (во время обработки прерывания)
	; или мог наступить таймаут
	cpse    r24, r25        ; только значение 240 меняем на 4
	rjmp    Scheduler_Deblock
	; если в SaveR24 осталось значение 240, то возвращаем 4
	ldi     r24, 4
	rjmp    Scheduler_Deblock


occupyMutex:	
	; свободный мьютекс, захватываем его
	sei
	st      X, r24
	ldi     r24, 1
	rjmp    Scheduler_Deblock


repeatOccupy:
	; повторный захват мьютекса

#if NumCMutexes
#if NumCMutexes != TotalMutexes
	cpi     r24, NumCMutexes+1
	brcc    binaryMutex
#endif /* NumCMutexes != TotalMutexes */
	sbwi    X, NumCMutexes
	ld      r0, X
	inc     r0
	st      X, r0
binaryMutex:
#endif /* NumCMutexes */
	sei
	ldi     r24, 3
	rjmp    Scheduler_Deblock


#if __AVR_HAVE_MUL__ && (SizeOfTSB * (NumThreads) > 255)
suspend_thread:
	clr     r1
	rjmp    OS_Scheduler_SuspendThread
#endif


.size   Mutex_Get, . - Mutex_Get
.size   Mutex_GetWithTimeout, . - Mutex_GetWithTimeout


#endif /* TotalMutexes */


;
; wordset:avr-gcc-os
;
; End of file  get.S

