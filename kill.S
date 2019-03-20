; share/avr/silOS/kill.S
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

.global Stop
.type	Stop, @function

.global Thread_Kill
.type	Thread_Kill, @function

Stop:
; void Stop( void )
; Останавливает текущий поток.
; Освобождает все мьютексы, которыми владеет текущий поток.
;
; На входе:
;	регистр r1: ноль
;
; Функцию нельзя вызывать из обработчиков прерываний.

	lds	r24, OS_CurTSBindex

Thread_Kill:
; TSBindex_t Thread_Kill( TSBindex_t idx )
; Останавливает указаный поток.
; Освобождает все мьютексы, которыми владеет останавливаемый поток.
;
; На входе:
;	регистр r24: номер останавливаемого потока
;	регистр r1: ноль
; На выходе:
;	регистр r24: номер остановленного потока;
;	             если останавливает текущий поток не в прерывании,
;	             то из функции выхода не происходит, управление
;	             передаётся в диспетчер потоков
; Портит регистры: FIXME
;
; Если функция вызывается из обработчика прерывания при разрешённых прерываниях,
; то должен использоваться стек прерываний.

	neg	r24
	letw	r22, pm(Stop)	; при активизации потока будет
				; выполняться функция Stop
	rjmp	Thread_Prepare

.size	Stop, . - Stop
.size	Thread_Kill, . - Thread_Kill


;
; wordset:avr-gcc-os
;
; End of file  kill.S
