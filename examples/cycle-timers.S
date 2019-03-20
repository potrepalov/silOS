; share/avr/silOS/examples/cycle-timers.S
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


.lcomm	cycle_timers, 6 * NumCTimers
.global	cycle_timers


	.macro	CYCLE_TIMERS
#if NumCTimers
	; обработка циклических таймеров
	; все рабочие регистры уже должны быть сохранены
	pushw	Y
	letw	Y, cycle_timers
	clr	r24
1:	inc	r24
	in	r25, SREG
	cli
	; x = .cnt - 1
	ldd	ZL, Y+0
	ldd	ZH, Y+1
	sbiw	Z, 1
	brcs	2f		; .cnt == 0  -- таймер не работает
	brne	3f		; x != 0
	; таймер сработал
	; .cnt := .start
	ldd	ZL, Y+2
	ldd	ZH, Y+3
	std	Y+1, ZH
	std	Y+0, ZL
	ldd	ZL, Y+4
	out	SREG, r25
	ldd	ZH, Y+5
	; func( timer + CYCLE_TIMER_EVENT_BASE )
	push	r24		; номер таймера
#if CYCLE_TIMER_EVENT_BASE
	subi	r24, 0 - CYCLE_TIMER_EVENT_BASE	; добавляем смещение
#endif
	; параметр функции: номер таймера со смещением
	icall			; вызов функции (Signal_Set, Event_Occur и т.п.)
	pop	r24
	rjmp	4f

3:	; .cnt := x
	std	Y+1, ZH
	std	Y+0, ZL

2:	out	SREG, r25
4:	adiw	Y, 6
	cpi	r24, NumCTimers - 1
	brne	1b
	popw	Y
#endif /* NumCTimers */
	.endm ; CYCLE_TIMERS


; End of file  cycle-timers.S
