; share/avr/silOS/unlock.S
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

.global Scheduler_Unlock
.type	Scheduler_Unlock, @function

Scheduler_Unlock:
; void Scheduler_Unlock( void )
; Уменьшает счётчик блокировок диспетчера потоков.
; При достижении счетчиком нуля разблокирует диспетчер потоков.
; Если прерывания запрещены, то больше ничего не делает.
; Если же прерывания разрешены, то, при необходимости, выполняет
; переключение потока.
;
; Портит регистр r31
;
; Если функция вызывается из обработчика прерывания
; (с разрешёнными прерываниями), то должен использоваться стек прерываний

	.global	_silOS_Unlock_Occur, _silOS_Unlock_Release, _silOS_Unlock_Up
	.global	Scheduler_Unlock_IE, SeiRet

	.if OS_Reg_isAbsent
	brie	Scheduler_Unlock_IE
	lds	r31, OS_Flags
	subi	r31, 2
	brcs	2f
	sts	OS_Flags, r31
2:	ret

Scheduler_Unlock_IE:
	cli
	lds	r31, OS_Flags
_silOS_Unlock_Occur:
_silOS_Unlock_Release:
_silOS_Unlock_Up:
	subi	r31, 2
	brcs	3f		; в OS_Flags 0 или 1
	sts	OS_Flags, r31
	breq	SwitchThread	; в OS_Flags было 2
SeiRet:	sei
	ret

3:	addi	r31, 2
	brne	SeiRet		; OS_Flags == 1, менять активный поток не нужно
_silOS_Unlock_SwitchThread:
SwitchThread:
	; необходимо выбирать наиболее приоритетный активный поток
	.endif	; OS_Reg_isAbsent


	.if OS_Reg_isLoReg
	brie	Scheduler_Unlock_IE
	mov	r31, OS_Reg
	subi	r31, 2
	brcs	2f
	mov	OS_Reg, r31
2:	ret

Scheduler_Unlock_IE:
	cli
	mov	r31, OS_Reg
_silOS_Unlock_Occur:
_silOS_Unlock_Release:
_silOS_Unlock_Up:
	subi	r31, 2
	brcs	3f
	mov	OS_Reg, r31
	breq	SwitchThread
SeiRet:	sei
	ret

3:	addi	r31, 2
	brne	SeiRet
_silOS_Unlock_SwitchThread:
SwitchThread:
	.endif	; OS_Reg_isLoReg


	.if OS_Reg_isHiReg
	brie	Scheduler_Unlock_IE
	subi	OS_Reg, 2
	brcc	2f
	addi	OS_Reg, 2
2:	ret

Scheduler_Unlock_IE:
	subi	OS_Reg, 2
	; если в OS_Reg был 0 или 1, то сейчас в прерываниях
	; активный поток менять не будут, т.к. OS_Reg стал не 0
	brcc    3f		; в OS_Reg было значение не меньше 2
	; в OS_Reg был 0 или 1
	; если в OS_Reg было значение 1 и после вычитания случилось прерывание,
	; то значение в OS_Reg во время обработки прерывания может измениться
	; с 0xFF на 0xFE
	cli
	addi	OS_Reg, 2
	breq	SwitchThread	; необходимо менять поток
	; в OS_Reg сейчас 1, т.е. поток менять не нужно
SeiRet:	sei
2:	ret

3:	brne	2b
_silOS_Unlock_Occur:
_silOS_Unlock_Release:
_silOS_Unlock_Up:
	; если между командами 'subi OS_Reg,2' и 'cli' случится прерывание,
	; после которого поменяется активный поток, то после возвращения
	; сюда мы ещё раз (лишний раз) попытаемся поменять активный поток;
	; ничего страшного, это редкое событие
_silOS_Unlock_SwitchThread:
	cli
SwitchThread:
	.endif	; OS_Reg_isHiReg


	.if OS_Reg_isIO
	brie	Scheduler_Unlock_IE
	in	r31, OS_Reg
	subi	r31, 2
	brcs	2f
	out	OS_Reg, r31
2:	ret

Scheduler_Unlock_IE:
	cli
	in	r31, OS_Reg
_silOS_Unlock_Occur:
_silOS_Unlock_Release:
_silOS_Unlock_Up:
	subi	r31, 2
	brcs	3f		; в OS_Reg 0 или 1
	out	OS_Reg, r31
	breq	SwitchThread	; в OS_Reg было 2
SeiRet:	sei
	ret

3:	addi	r31, 2
	brne	SeiRet		; OS_Reg == 1, менять активный поток не нужно
_silOS_Unlock_SwitchThread:
SwitchThread:
	; необходимо выбирать наиболее приоритетный активный поток
	.endif	; OS_Reg_isIO



;SwitchThread:
	; счётчик блокировок достиг 0, необходимо искать наиболее приоритетный
	; поток и прерывания разрешены
	; осталось проверить, что мы не в прерывании

_silOS_Switch_Internal:	.global	_silOS_Switch_Internal

#if __AVR_HAVE_SPH__
	in	r31, SPH
	cpi	r31, High( ISR_Stack_Fence )
#else /* !__AVR_HAVE_SPH__ */
	in	r31, SPL
	cpi	r31, Low( ISR_Stack_Fence )
#endif /* __AVR_HAVE_SPH__ */
	brcs	SeiRet
_silOS_Real_Switch:	.global	_silOS_Real_Switch
	; мы не в прерывании
	; делаем вид, что мы в прерывании
	push	OS_wReg
	in	OS_wReg, SREG
	push	OS_wReg

	; стек прерываний сейчас в правильном состоянии
	; и мы не будем его использовать для перехода в OS_Scheduler,
	; поэтому устанавливаем вершину стека в значение ISR_Stack_Top
#if __AVR_HAVE_SPH__
#if defined( iSPL )
	in	iSPH, SPH
	in	iSPL, SPL
#else /* !defined( iSPL ) */
	in	r31, SPH
	sts	ISR_SPsave+1, r31
	in	r31, SPL
	sts	ISR_SPsave, r31
#endif /* defined( iSPL ) */
	ldi	OS_wReg, Low( ISR_Stack_Top )
	out	SPL, OS_wReg
	ldi	OS_wReg, High( ISR_Stack_Top )
	sei
	out	SPH, OS_wReg
#else /* !__AVR_HAVE_SPH__ */
#if defined( iSPL )
	in	iSPL, SPL
#else /* !defined( iSPL ) */ 
	in	r31, SPL
	sts	ISR_SPsave, r31
#endif /* defined( iSPL ) */ 
	ldi	OS_wReg, Low( ISR_Stack_Top )
	sei
	out	SPL, OS_wReg
#endif /* __AVR_HAVE_SPH__ */
	rjmp	OS_Scheduler_Unlocked

.size	Scheduler_Unlock, . - Scheduler_Unlock


;
; wordset:avr-gcc-os
;
; End of file  unlock.S
