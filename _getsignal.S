; share/avr/silOS/_getsignal.S
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

.global	_silOS_GetSignalMask
.type	_silOS_GetSignalMask, @function

_silOS_GetSignalMask:
; Вычисляет и возвращает маску бита сигнала и адрес байта с битом сигнала.
;
; На входе:
;	регистр r24: номер сигнала
; На выходе:
;	регистр r24: маска бита сигнала
;	регистр Z: адрес байта с битом сигнала
; Портит регистр: r0

	letw	Z, OS_Signals-0x100
	dec	r24
	mov	r0, r24
	lsr	r24
	lsr	r24
	lsr	r24
	add	ZL, r24
	ldi	r24, 1		; x0x -> 0000 0001
	adc	ZH, r24
	sbrc	r0, 1
	ldi	r24, 4		; x1x -> 0000 0100
	sbrc	r0, 0
	lsl	r24		; x00 -> 0000 0001
				; x01 -> 0000 0010
				; x10 -> 0000 0100
				; x11 -> 0000 1000
	sbrc	r0, 2
	swap	r24
_silOS_SignalReturn_Internal:	.global _silOS_SignalReturn_Internal
	ret

.size	_silOS_GetSignalMask, . - _silOS_GetSignalMask


#endif /* NumSignals */


;
; wordset:avr-gcc-os
;
; End of file  reset.S
