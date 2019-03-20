; share/avr/silOS/islocked.S
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

.global Scheduler_IsLocked
.type	Scheduler_IsLocked, @function

Scheduler_IsLocked:
; RegType_t Scheduler_IsLocked( void )
; Возвращает не 0, если диспетчер потоков заблокирован.
;
; На выходе:
;	регистр R24: 0 -- диспетчер потоков разблокирован
;	          не 0 -- диспетчер потоков заблокирован

	.if OS_Reg_isAbsent
	lds	r24, OS_Flags
	.endif

	.if OS_Reg_isLoReg + OS_Reg_isHiReg
	mov	r24, OS_Reg
	.endif

	.if OS_Reg_isIO
	in	r24, OS_Reg
	.endif

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

	; младший бит -- флаг отсутствия необходимости поиска нового потока
	andi	r24, ~1
	ret

.size	Scheduler_IsLocked, . - Scheduler_IsLocked


;
; wordset:avr-gcc-os
;
; End of file  islocked.S
