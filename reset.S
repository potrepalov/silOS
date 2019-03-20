; share/avr/silOS/reset.S
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

.global	Signal_Reset
.type	Signal_Reset, @function

Signal_Reset:
; void Signal_Reset( Signal_t sig )
; Сбрасывает сигнал sig.
;
; На входе:
;	регистр r24: номер сигнала
; Портит регистры: r0, r24, r25, ZL, ZH

	rcall	_silOS_GetSignalMask
#if __ATXMEGA__ && !DO_NOT_USE_LAC
	lac	Z, r24
	ret
#else /* __ATXMEGA__ */
	com	r24
	in	r0, SREG
	cli
	ld	r25, Z
	and	r24, r25
	out	SREG, r0
	st	Z, r24
	ret
#endif /* __ATXMEGA__ */

.size	Signal_Reset, . - Signal_Reset


#endif /* NumSignals */


;
; wordset:avr-gcc-os
;
; End of file  reset.S
