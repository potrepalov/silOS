; share/avr/silOS/tryget.S
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

.global Mutex_TryGet
.type	Mutex_TryGet, @function

Mutex_TryGet:
; RegType_t Mutex_TryGet( Mutex_t mut )
; Попытка захватить мьютекс (без блокировки потока)
; Если мьютекс занят, то сразу возвращается
; На входе:
;	регистр r24: номер мьютекса
;	регистр r1: ноль
; На выходе:
;	регистр r24: 0 -- мьютекс занят, но занят не нами
;	             1 -- успешный захват мьютекса
;	             3 -- повторный захват мьютекса
; Портит регистры: r0, r25, ZH, ZL
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний

#if NumCMutexes < 64


	letw	Z, OS_Mutexes - 1
	add	ZL, r24
	adc	ZH, r1

	in	r0, SREG
	cli
	ldd	r25, Z + NumCMutexes
	tst	r25
	breq	1f		; мьютекс свободен, захватываем его
	; мьютекс занят
#if !RELEASE_IN_ISR
	out	SREG, r0
#endif /* RELEASE_IN_ISR */
	; проверим, что он занят не нами
	lds	r0, OS_CurTSBindex
	cp	r0, r25
	brne	2f		; мьютекс занят, но не нами
	; повторный захват мьютекса
#if NumCMutexes
#if NumCMutexes != TotalMutexes
	cpi	r24, NumCMutexes+1
	brcc	NoCMutex1
#endif /* NumCMutexes != TotalMutexes */
	ld	r24, Z
	inc	r24		; ещё раз захватили мьютекс
	st	Z, r24
NoCMutex1:
#endif /* NumCMutexes */
#if RELEASE_IN_ISR
	out	SREG, r0
#endif /* RELEASE_IN_ISR */
	ldi	r24, 3		; повторный захват мьютекса
	ret

2:	; мьютекс занят, но не нами
#if RELEASE_IN_ISR
	out	SREG, r0
#endif /* RELEASE_IN_ISR */
	ldi	r24, 0		; мьютекс занят, но не нами
	ret


1:	; мьютекс свободен, захватываем его

#if NumCMutexes

	lds	r25, OS_CurTSBindex
	std	Z + NumCMutexes, r25	; отметили захват мьютекса
#if NumCMutexes != TotalMutexes
	cpi	r24, NumCMutexes+1
	ldi	r24, 1		; захват мьютекса выполнен один раз
	brcc	NoCMutex2
#else /* NumCMutexes == TotalMutexes */
	ldi	r24, 1
#endif /* NumCMutexes != TotalMutexes */
	st	Z, r24		; установили счётчик мьютекса в 1
NoCMutex2:
	out	SREG, r0

#else /* !NumCMutexes */

	lds	r25, OS_CurTSBindex
	out	SREG, r0
	std	Z + NumCMutexes, r25	; отметили захват мьютекса
	ldi	r24, 1		; успешный захват мьютекса

#endif /* NumCMutexes */

	ret


#else /* NumCMutexes >= 64 */


	letw	Z, OS_Mutexes + NumCMutexes - 1
	add	ZL, r24
	adc	ZH, r1

	in	r0, SREG
	cli
	ld	r25, Z
	tst	r25
	breq	1f		; мьютекс свободен, захватываем его
	; мьютекс занят
#if !RELEASE_IN_ISR
	out	SREG, r0
#endif /* RELEASE_IN_ISR */
	; проверим, что он занят не нами
	lds	r0, OS_CurTSBindex
	cp	r0, r25
	brne	2f		; мьютекс занят, но не нами
	; повторный захват мьютекса

#if NumCMutexes != TotalMutexes
	cpi	r24, NumCMutexes+1
	brcc	NoCMutex1
#endif /* NumCMutexes != TotalMutexes */

	subi	ZL, Low( NumCMutexes )
	sbci	ZH, High( NumCMutexes )
	ld	r24, Z
	inc	r24		; ещё раз захватили мьютекс
#if RELEASE_IN_ISR
	out	SREG, r0
#endif /* RELEASE_IN_ISR */
	st	Z, r24

#if NumCMutexes != TotalMutexes
NoCMutex1:
#if RELEASE_IN_ISR
	out	SREG, r0
#endif /* RELEASE_IN_ISR */
#endif /* NumCMutexes != TotalMutexes */

	ldi	r24, 3		; повторный захват мьютекса
	ret

2:
#if RELEASE_IN_ISR
	out	SREG, r0
#endif /* RELEASE_IN_ISR */
	ldi	r24, 0		; мьютекс занят, но не нами
	ret

1:	; мьютекс свободен, захватываем его
	lds	r25, OS_CurTSBindex
	st	Z, r25
#if NumCMutexes != TotalMutexes
	cpi	r24, NumCMutexes+1
	ldi	r24, 1		; успешный захват мьютекса
	brcc	NoCMutex2
	subi	ZL, Low( NumCMutexes )
	sbci	ZH, High( NumCMutexes )
	st	Z, r24		; захват мьютекса выполнен один раз
NoCMutex2:
	out	SREG, r0
#else /* NumCMutexes == TotalMutexes */
	ldi	r24, 1
	subi	ZL, Low( NumCMutexes )
	sbci	ZH, High( NumCMutexes )
	out	SREG, r0
	st	Z, r24		; захват мьютекса выполнен один раз
#endif /* NumCMutexes != TotalMutexes */
	ret


#endif /* NumCMutexes < 64 */


.size	Mutex_TryGet, . - Mutex_TryGet


#endif /* TotalMutexes */


;
; wordset:avr-gcc-os
;
; End of file  tryget.S
