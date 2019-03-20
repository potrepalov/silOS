; share/avr/silOS/idle/IdleProc.S
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

;
; Подпрограмма бездействия системы
;


#include <avr/io.h>
#include "../os.h"


	.section	".text.OS", "x"

.global IdleProc
.type	IdleProc, @function

IdleProc:
; Подпрограмма, которая вызывается во время ожидания активизации
; какого-либо потока, т.е. во время бездействия системы (см. scheduler.S)
; Можно использовать регистры: r0, r1, r24, r25, YL, YH, ZL, ZH
; Активный контекст -- контекст прерываний (активен стек прерываний)
;
; Фрагмент кода, откуда вызывается функция IdleProc:
;
;
;5:
;	; активного потока нет, делать нечего
;
;	.if OS_Reg_isAbsent
;	lds	r25, OS_Flags
;	sbrs	r25, 0
;	rjmp	FindAT_Idle	; необходимо изменить активный поток
;	.endif	; OS_Reg_isAbsent
;
;	.if OS_Reg_isLoReg + OS_Reg_isHiReg
;	sbrs	OS_Reg, 0
;	rjmp	FindAT_Idle	; необходимо изменить активный поток
;	.endif	; OS_Reg_isLoReg + OS_Reg_isHiReg
;
;	.if OS_Reg_isLoIO
;	sbis	OS_Reg, 0	; необходимо изменить активный поток
;	rjmp	FindAT_Idle
;	.endif	; OS_Reg_isLoIO
;
;	.if OS_Reg_isHiIO + OS_Reg_isVarIO
;	in	r25, OS_Reg
;	sbrs	r25, 0
;	rjmp	FindAT_Idle	; необходимо изменить активный поток
;	.endif	; OS_Reg_isHiIO + OS_Reg_isVarIO
;
;#ifdef IdleFunc
;	rcall	IdleFunc
;#endif /* IdleFunc */
;
;	rjmp	5b
;
;
; IdleCounter считает такты процессора в течении которых выполняется
; данный код.  Подсчитаем такты на выполнение этих команд:
;

#if __ATXMEGA__
.set	lds_tc,		3
.set	rcall_tc,	2
#else /* !__ATXMEGA__ */
.set	lds_tc,		2
.set	rcall_tc,	3
#endif /* __ATXMEGA__ */

.set	subi_tc,	1
.set	sts_tc,		2
.set	br_tc,		2
.set	no_br_tc,	1
.set	ret_tc,		4
.set	inc_tc,		1
.set	sbrs_tc,	2	; нас интересует пропуск следующей команды
.set	rjmp_tc,	2


	.if OS_Reg_isAbsent
;	lds	r25, OS_Flags
;	sbrs	r25, 0
;	rjmp	FindAT_Idle	; необходимо изменить активный поток
.set	Load_tc,	lds_tc + sbrs_tc
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg + OS_Reg_isHiReg
;	sbrs	OS_Reg, 0
;	rjmp	FindAT_Idle	; необходимо изменить активный поток
.set	Load_tc,	sbrs_tc
	.endif	; OS_Reg_isLoReg + OS_Reg_isHiReg

	.if OS_Reg_isLoIO
;	sbis	OS_Reg, 0	; необходимо изменить активный поток
;	rjmp	FindAT_Idle
.set	Load_tc,	sbrs_tc
	.endif	; OS_Reg_isLoIO

	.if OS_Reg_isHiIO + OS_Reg_isVarIO
;	in	r25, OS_Reg
;	sbrs	r25, 0
;	rjmp	FindAT_Idle	; необходимо изменить активный поток
	.if OS_RegisVarIO
	; in заменяется на lds
.set	Load_tc,	2 + sbrs_tc
	.else
	; используется команда in
.set	Load_tc,	1 + sbrs_tc
	.endif	; OS_RegisVarIO
	.endif	; OS_Reg_isHiIO + OS_Reg_isVarIO

;	rcall	IdleFunc
;	rjmp	5b
.set	Upper_tc,	Load_tc + rcall_tc + rjmp_tc


	; в счетчике IdleCounter считаем такты вызывающей программы и свои
	lds	r24, IdleCounter	; 0
	subi	r24, 0 - (Upper_tc + lds_tc + subi_tc + br_tc + sts_tc + ret_tc)
	brcs	1f
	subi	r24, 0 - (no_br_tc + subi_tc + lds_tc + inc_tc + sts_tc)
	lds	r0, IdleCounter+1	; 1
	inc	r0
	sts	IdleCounter+1, r0
	brne	1f
	subi	r24, 0 - (no_br_tc + subi_tc + lds_tc + inc_tc + sts_tc)
	lds	r0, IdleCounter+2	; 2
	inc	r0
	sts	IdleCounter+2, r0
	brne	1f
	subi	r24, 0 - (no_br_tc + subi_tc + lds_tc + inc_tc + sts_tc - br_tc)
	lds	r0, IdleCounter+3	; 3
	inc	r0
	sts	IdleCounter+3, r0
1:	sts	IdleCounter, r24
	ret

.size	IdleProc, . - IdleProc


;
; wordset:avr-gcc-os
;
; End of file  IdleProc.S
