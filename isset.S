; share/avr/silOS/isset.S
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

.global Signal_IsSet
.type	Signal_IsSet, @function

Signal_IsSet:
; RegType_t Signal_IsSet( Signal_t sig )
; Возвращает не 0, если сигнал установлен.
;
; На входе:
;	регистр r24: номер сигнала
; На выходе:
;	регистр r24: 0 -- сигнал не установлен
;	          не 0 -- сигнал установлен
; Портит регистры: r0, ZL, ZH

	rcall	_silOS_GetSignalMask
	ld	r0, Z
	and	r24, r0
	ret

.size	Signal_IsSet, . - Signal_IsSet


#endif /* NumSignals */


;
; wordset:avr-gcc-os
;
; End of file  isset.S
