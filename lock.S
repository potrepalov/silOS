; share/avr/silOS/lock.S
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

.global Scheduler_Lock
.type	Scheduler_Lock, @function

Scheduler_Lock:
; void Scheduler_Lock( void )
; Блокирует работу деспетчера потоков и увеличивает счётчик его блокировок.
;
; Портит регистр r31

	.if OS_Reg_isAbsent
	brie	1f
	lds	r31, OS_Flags
	addi	r31, 2
	sts	OS_Flags, r31
	ret

1:	cli
	lds	r31, OS_Flags
	addi	r31, 2
	sei
	sts	OS_Flags, r31
	ret
	.endif	; OS_Reg_isAbsent


	.if OS_Reg_isLoReg
	ldi     r31, 2
	add     OS_Reg, r31
	ret
	.endif ; OS_Reg_isLoReg


	.if OS_Reg_isHiReg
	addi	OS_Reg, 2
	ret
	.endif	; OS_Reg_isHiReg


	.if OS_Reg_isIO
	brie	1f
	in	r31, OS_Reg
	addi	r31, 2
	out	OS_Reg, r31
	ret

1:	cli
	in	r31, OS_Reg
	addi	r31, 2
	sei
	out	OS_Reg, r31
	ret
	.endif	; OS_Reg_isIO


	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		


.size	Scheduler_Lock, . - Scheduler_Lock


;
; wordset:avr-gcc-os
;
; End of file  lock.S
