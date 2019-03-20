; share/avr/silOS/owner.S
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

.global Mutex_Owner
.type	Mutex_Owner, @function

Mutex_Owner:
; TSBindex_t Mutex_Owner( Mutex_t m )
; Возвращает номер TSB потока-владельца мьютекса.
;
; На входе:
;	регистр r24: номер мьютекса
;	регистр r1: ноль
; На выходе:
;	регистр r24: номер потока-владельца мьютекса
;	             0 -- мьютекс совбоден
; Портит регистры: ZL, ZH

	letw	Z, OS_Mutexes + NumCMutexes - 1
	add	ZL, r24
	adc	ZH, r1
	ld	r24, Z
	ret

.size	Mutex_Owner, . - Mutex_Owner


#endif /* TotalMutexes */


; Результат функции Mutex_Owner может оказаться неточным, если
; вызов функции Mutex_Owner произойдёт во время обработки прерывания,
; которое случилось во время работы фунции Mutex_Release (с тем же
; параметром, что и у функции Mutex_Owner): после возврата из прерывания
; владелец мьютекса будет другим.
;
; Но этот случай ничем не отличается от вызова функции Mutex_Owner в
; прерывании, которое случится непосредственно перед вызовом функции
; Mutex_Release в потоке.


;
; wordset:avr-gcc-os
;
; End of file  owner.S
