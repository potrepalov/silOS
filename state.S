; share/avr/silOS/state.S
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

.global Semaphore_State
.type	Semaphore_State, @function

Semaphore_State:
; SemaphoreCounter_t Semaphore_State( Semaphore_t );
; Возвращает состояние семафора.
;
; На входе:
;	регистр r24: номер семафора
;	регистр r1: ноль
; На выходе:
;	регистр r24: счетчик семафора
;	             0 -- семафор закрыт
;	          не 0 -- семафор открыт
; Портит регистры: ZH, ZL

	letw	Z, OS_Semaphores-1
	add	ZL, r24
	adc	ZH, r1
	ld	r24, Z
	ret

.size	Semaphore_State, . - Semaphore_State


#endif /* NumSemaphores */


;
; wordset:avr-gcc-os
;
; End of file  state.S
