; share/avr/silOS/misc/eememory.S
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
#include "../os.h"


#if defined( EE_Semaphore )


	.section	".text.OS", "x"

.global	ReadEE
.type	ReadEE, @function

ReadEE:
; unsigned char ReadEE( uint16_t addr )
; Читает байт из памяти EEPROM контроллера по указаному адресу
; Перед чтением ожидает освобождения памяти
; На входе:
;	регистры r25:r24: адрес читаемого байта в памяти EEPROM
; На выходе:
;	регистр r24: считаный байт
#if defined( EEARH )
	pushw	Y
	movw	Y, r24
	ldi	r24, EE_Semaphore
	rcall	Semaphore_Down
	outw	EEAR, Y
	sbi	EECR, EERE
	in	YL, EEDR
	ldi	r24, EE_Semaphore
	rcall	Semaphore_Up
	mov	r24, YL
	popw	Y
#else /* EEARH */
	push	YL
	mov	YL, r24
	ldi	r24, EE_Semaphore
	rcall	Semaphore_Down
	out	EEAR, YL
	sbi	EECR, EERE
	in	YL, EEDR
	ldi	r24, EE_Semaphore
	rcall	Semaphore_Up
	mov	r24, YL
	pop	YL
#endif /* EEARH */
	ret

.size	ReadEE, . - ReadEE


.global WriteEE
.type	WriteEE, @function

WriteEE:
; void WriteEE( uint16_t addr, unsigned char c )
; Записывает байт данных по указаному адресу в памяти EEPROM
; Перед записью ожидает освобождения памяти
; После записи память остается занятой до окончания программирования EEPROM
#if defined( EEARH )
	push	r22
	pushw	r24
	ldi	r24, EE_Semaphore
	rcall	Semaphore_Down
	popw	r24
	outw	EEAR, r24
#else /* EEARH */
	push	r22
	push	r24
	ldi	r24, EE_Semaphore
	rcall	Semaphore_Down
	pop	r24
	out	EEAR, r24
#endif /* EEARH */
	pop	r22
	; проверяем, что байт точно нужно записывать
	sbi	EECR, EERE
	in	r23, EEDR
	cp	r22, r23
	breq	1f		; байт не меняется, писать не нужно
	; байт нужно записывать
	out	EEDR, r22
	in	r24, SREG
	cli
#if defined( EEMPE )
	sbi	EECR, EEMPE
	sbi	EECR, EEPE
#else /* EEMPE */
	sbi     EECR, EEMWE
	sbi	EECR, EEWE
#endif /* EEMPE */
	out	SREG, r24
	sbi     EECR, EERIE
	ret

1:	; байт не изменился, освобождаем семафор
	ldi	r24, EE_Semaphore
	rjmp	Semaphore_Up

.size	WriteEE, . - WriteEE



#if defined( EE_RDY_vect )
#define EE_READY_vect	EE_RDY_vect
#endif


.global	EE_READY_vect
.type	EE_READY_vect, @function

EE_READY_vect:
	SAVE_REGS_SOFT
	TO_ISR_STACK
	cbi	EECR, EERIE
	sei

	pushw	X
	pushw	r24
	pushw	r0

	clr	r1
	ldi	r24, EE_Semaphore
	rcall	Semaphore_Up

	popw	r0
	popw	r24
	popw	X
	FINISH_SOFT_ISR

.size	EE_READY_vect, . - EE_READY_vect


#endif /* EE_Semaphore */


;
; wordset:avr-gcc-os
;
; End of file  eememory.S
