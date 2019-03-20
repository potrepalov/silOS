; share/avr/silOS/activate.S
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

.global Thread_Activate
.type	Thread_Activate, @function

Thread_Activate:
; TSBindex_t Thread_Activate( TSBindex_t idx )
; Активизирует указаный поток.
;
; На входе:
;	регистр r24: номер активизируемого потока
;	регистр r1: ноль
; Портит регистры: r0, r25, ZL, ZH
;
; Если функция вызывается из обработчика прерывания при разрешённых прерываниях,
; то должен использоваться стек прерываний

#if __AVR_HAVE_MUL__
	ldi	ZL, SizeOfTSB
	mul	ZL, r24
	letw	Z, OS_TSBs - SizeOfTSB
	addw	Z, r0
#if NumThreads * SizeOfTSB > 255
	clr	r1
#endif /* NumThreads * SizeOfTSB */
#else /* __AVR_HAVE_MUL__ */
	mov	r0, r24
	letw	Z, OS_TSBs - SizeOfTSB
1:	adiw	Z, SizeOfTSB
	dec	r0
	brne	1b
#endif /* __AVR_HAVE_MUL__ */

	in	r0, SREG
	cli

#if BIG_SLEEP
	std	Z+SleepCounter+1, r1
#endif /* BIG_SLEEP */
	std	Z+SleepCounter, r1
#if __BlockingRes
	std	Z+BlockingRes, r1
#endif /* __BlockingRes */


	; устанавливаем флаг необходимости поиска активного потока
	; (сбрасываем нулевой бит)

	.if OS_Reg_isAbsent
	lds	r25, OS_Flags
	andi	r25, ~1
	sts	OS_Flags, r25
	sbrs	r0, SREG_I	; возвращаемся, если прерывания запрещены
	ret
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	sbrc	OS_Reg, 0	; пропускаем, если бит уже сброшен
	dec	OS_Reg
	sbrs	r0, SREG_I	; возвращаемся, если прерывания запрещены
	ret
	tst	OS_Reg
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	andi	OS_Reg, ~1
	sbrs	r0, SREG_I	; возвращаемся, если прерывания запрещены
	ret
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	in	r25, OS_Reg
	andi	r25, ~1
	out	OS_Reg, r25
	sbrs	r0, SREG_I	; возвращаемся, если прерывания запрещены
	ret
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

	; счётчик блокировок 0 и прерывания разрешены
	; если флаг Z установлен, значит счётчик блокировок равен 0,
	; и значит осталось проверить, что мы не в прерывании

	breq	_silOS_Switch_Internal

	; возвращаемся, т.к. потоки нельзя переключать
	sei
	ret

.size	Thread_Activate, . - Thread_Activate


;
; wordset:avr-gcc-os
;
; End of file  activate.S
