; timer.S
;
; Обработка прерывания от системного таймера
; (переполнение таймера 0)
;


#include <avr/io.h>
#include "silOS/genmacro/genmacro.inc"
#include "silOS/os.h"
#include "silOS/tick.inc"
#include "silOS/timers.inc"


#if __AVR_ARCH__ >= 100 /* __ATXMEGA__ */
#define OS_TIMER_VECT	TCC0_OVF_vect
#else /* !__ATXMEGA__ */
#define OS_TIMER_VECT	TIMER0_OVF_vect
#endif /* __ATXMEGA__ */

.lcomm	TicksCounter, 2
.global	TicksCounter


	.section	".text.OS", "x"

.global	OS_TIMER_VECT
.type	OS_TIMER_VECT,  @function

OS_TIMER_VECT:
; Обработка прерывания от системного таймера
	SAVE_REGS
	TO_ISR_STACK
	sei
	pushw	Z

	lds	ZL, TicksCounter
	addi	ZL, 1
	sts	TicksCounter, ZL
	brne	1f
	lds	ZL, TicksCounter+1
	inc	ZL
	sts	TicksCounter+1, ZL
1:

	OS_TICK		interrupts_enable, OS_wReg
	OS_TIMERS	interrupts_enable, OS_wReg

	popw	Z
	RESTORE_REGS
	sei
	reti

.size	OS_TIMER_VECT, . - OS_TIMER_VECT


;
; wordset:avr-gcc-os
;
; End of file  timer.S
