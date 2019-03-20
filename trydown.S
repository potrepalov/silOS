; share/avr/silOS/trydown.S
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

.global Semaphore_TryDown
.type	Semaphore_TryDown, @function

.global Semaphore_TryPend
.type	Semaphore_TryPend, @function

.global Semaphore_TryClose
.type	Semaphore_TryClose, @function

Semaphore_TryDown:
Semaphore_TryPend:
Semaphore_TryClose:
; RegType_t Semaphore_TryDown( Semaphore_t sem )
; Если счетчик семафора не 0 (семафор открыт), то уменьшает его на 1 (закрывает)
; Если счетчик семафора 0 (семафор закрыт), то сразу возвращается.
;
; На входе:
;	регистр r24: номер семафора
;	регистр r1: ноль
; На выходе:
;	регистр r24: 1 -- семафор был открыт, закрыли (удачный проход семафора)
;	             0 -- семафор закрыт (нужно ожидать его открытия)
; Портит регистры: r0, ZL, ZH

	letw	Z, OS_Semaphores-1
	add	ZL, r24
	adc	ZH, r1
	in	r0, SREG
	cli
	ld	r24, Z
	subi	r24, 1		; пытаемся "закрыть" семафор
	brcs	1f		; семафор уже был "закрыт", r24 === 0xFF
	; семафор был "открыт"
	st	Z, r24		; меняем состояние счётчика семафора
	clr	r24		; r24 := 0; семафор был "открыт"
1:	out	SREG, r0
	subi	r24, 0xFF	; 0x00 -> 0x01;  0xFF -> 0x00
	ret

.size	Semaphore_TryDown, . - Semaphore_TryDown
.size	Semaphore_TryPend, . - Semaphore_TryPend
.size	Semaphore_TryClose, . - Semaphore_TryClose


#endif /* NumSemaphores */


;
; wordset:avr-gcc-os
;
; End of file  trydown.S
