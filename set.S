; share/avr/silOS/set.S
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


#if NumSignals


	.section	".text.OS.signal", "x"

.global	Signal_Set
.type	Signal_Set, @function

Signal_Set:
; RegType_t Signal_Set( Signal_t sig )
; Устанавливает сигнал sig и активизирует все потоки, которые ожидали
; данный сигнал; возвращает не 0, если был хотя бы один поток, который
; ожидал данный сигнал.
;
; На входе:
;	регистр r24: номер сигнала
; На выходе:
;	регистр r24: 0 -- данный сигнал ни один поток не ожидал
;	          не 0 -- данный сигнал ожидал хотя бы один поток
; Портит регистры: r0, r25, XL, XH, ZL, ZH
;
; Если функция вызывается из обработчика прерывания
; (с разрешёнными прерываниями), то должен использоваться стек прерываний

	mov	XH, r24
	rcall	_silOS_GetSignalMask
	mov	r0, r24

	ld	r24, Z
	and	r24, r0
	ldi	r24, 0
	; если не 0, значит сигнал установлен, и его никто не ждёт
	brne	_silOS_SignalReturn_Internal

	; Для обеспечения атомарности операции установки сигнала
	; требуется запретить переключение потоков перед его установкой.

	; Иначе может получиться так: установили здесь сигнал (но ещё не
	; активизировали потоки, ожидающие данный сигнал);
	; один из потоков (с приоритетом большим, чем у текущего потока)
	; сбросил сигнал; другой более приоритетный поток начал ожидать
	; появления сигнала; продолжили здесь активизировать потоки,
	; ожидающие данный сигнал.  В этом случае поток, начавший ожидать
	; появления сигнала после его сброса, будет активизирован ошибочно.

	; Необходимо отметить, что запрещение переключения потоков
	; не обеспечивает атомарности операции установки сигнала
	; по отношению к прерываниям и потокам одновременно.
	; Атомарность обеспечивается отдельно для потоков
	; и одтельно для прерываний.  Т.е. в прерываниях мы всегда
	; видим определённое состояние сигналов, и в потоках
	; (сразу во всех) мы тоже видим вполне определённое состояние
	; сигналов.  В прерываниях же мы можем увидеть промежуточное
	; состояние процесса активизации потоков, ожидающих какой-либо
	; сигнал.

	; Запрет прерываний на время активизации потоков очень сильно
	; увеличит время задержки обработки прерываний (Interrupt Latency
	; Time), и это представляется излишним.

	; Операция установки бита сигнала должна быть атомарной по отношению
	; к прерываниям (т.к. в прерываниях могут менять другие биты сигналов
	; в том же байте).

#if __ATXMEGA__ && !DO_NOT_USE_LAC
	.if OS_Reg_isHiReg
	addi	OS_Reg, 2
	las	Z, r0
	.else
	in	r25, SREG
	cli
	las	Z, r0
	.endif	; OS_Reg_HiReg
#else
	in	r25, SREG
	cli
	ld	r24, Z
	or	r24, r0
	st	Z, r24

	.if OS_Reg_isHiReg
	out	SREG, r25
	addi	OS_Reg, 2
	.endif	; OS_Reg_isHiReg
#endif

	.if OS_Reg_isAbsent
	lds	r24, OS_Flags
	addi	r24, 2
	out	SREG, r25
	sts	OS_Flags, r24
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	inc	OS_Reg
	out	SREG, r25
	inc	OS_Reg
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isIO
	in	r24, OS_Reg
	addi	r24, 2
	out	SREG, r25
	out	OS_Reg, r24
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

	; переключение потоков будет разрешено после выполнения
	; функции Event_Occur (если переключение потоков не было запрещено
	; до входа в функцию Signal_Set)

	mov	r24, XH
	; Event_Occur( sig + START_SIGNALS-1 - (START_EVENTS-1) )
	; т.к. START_EVENTS-1 в Event_Occur не добавляем,
	; то здесь это значение не отнимаем
#if START_SIGNALS != 1
	subi	r24, Low(0 - (START_SIGNALS-1))
#endif /* START_SIGNALS */
	rjmp	Event_Occur_Internal

.size	Signal_Set, . - Signal_Set


#endif /* NumSignals */


;
; wordset:avr-gcc-os
;
; End of file  set.S
