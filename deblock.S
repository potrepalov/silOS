; share/avr/silOS/deblock.S
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


	.section	".text.OS", "x"

.global Scheduler_Deblock
.type	Scheduler_Deblock, @function

Scheduler_Deblock:
; void Scheduler_Deblock( void )
; Разблокирует диспетчер потоков и разрешает прерывания.
; При необходимости, выполняет переключение потока.
;
; Функцию ни в коем случае нельзя вызывать из обработчиков прерываний.
; Функция разрешает прерывания.

	check = 0

	.if OS_Reg_isAbsent
	check = check + 1
	cli
	lds	r31, OS_Flags
	andi	r31, 1
	breq	_silOS_Real_Switch	; see in unlock.S
	sei
	sts	OS_Flags, r31
	ret
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	check = check + 1
	ldi     r31, 1
	and     OS_Reg, r31
	brne    SeiRet                  ; see in unlock.S
	cli
	rjmp	_silOS_Real_Switch      ; see in unlock.S
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	check = check + 1
	andi	OS_Reg, 1
	brne	SeiRet			; see in unlock.S
	cli
	rjmp	_silOS_Real_Switch	; see in unlock.S
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	check = check + 1
	cli
	in	r31, OS_Reg
	andi	r31, 1
	breq	_silOS_Real_Switch	; see in unlock.S
	sei
	out	OS_Reg, r31
	ret
	.endif	; OS_Reg_isIO


	.ifne   check - 1
	.error Unsupported type of  OS_Reg
	.endif		


.size	Scheduler_Deblock, . - Scheduler_Deblock


;
; wordset:avr-gcc-os
;
; End of file  deblock.S
