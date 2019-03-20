; share/avr/silOS/os-internal.inc
;
;


#if !defined( OS_H_INCLUDED )
#error "Include  os/os.h  file instead of this file"
#endif

#include "genmacro/genmacro.inc"


	; set type of OS_Reg

        OS_Reg_isAbsent = 0
	OS_Reg_isLoReg = 0
	OS_Reg_isHiReg = 0
	OS_Reg_isLoIO = 0
	OS_Reg_isHiIO = 0
	OS_Reg_isVarIO = 0


#if !defined( OS_Reg )
	OS_Reg_isAbsent = 1
#else /* defined( OS_Reg ) */

	; check for wrong register
	.irp	_reg,	r0, r1, r24,r25,r26,r27,r28,r29,r30,r31, \
			R0, R1, R24,R25,R26,R27,R28,R29,R30,R31, \
			XL,XH,YL,YH,ZL,ZH,xl,xh,yl,yh,zl,zh
		.ifc	OS_Reg, \_reg
			.error Wrong register for OS_Reg
		.endif
	.endr

	; check for low register
	.irp	_reg,	r2, r3, r4, r5, r6, r7, r8, \
			R2, R3, R4, R5, R6, R7, R8, \
			r9, r10,r11,r12,r13,r14,r15, \
			R9, R10,R11,R12,R13,R14,R15

		.ifc	OS_Reg, \_reg
			OS_Reg_isLoReg = 1
		.endif
	.endr

	; check for high register
	.irp	_reg,	r16,r17,r18,r19,r20,r21,r22,r23, \
			R16,R17,R18,R19,R20,R21,R22,R23
		.ifc	OS_Reg, \_reg
			OS_Reg_isHiReg = 1
		.endif
	.endr

	.ifeq OS_Reg_isLoReg + OS_Reg_isHiReg
#if _SFR_IO_ADDR(OS_Reg) < 0x20
		; OS_Reg is low I/O register
		; we can use commands: sbis, sbic, in, out
		OS_Reg_isLoIO = 1
#elif _SFR_IO_ADDR(OS_Reg) < 0x40
		; OS_Reg is high I/O register
		; we can use commands: in, out
		OS_Reg_isHiIO = 1
#elif _SFR_IO_ADDR(OS_Reg) >= 0x40
		; OS_Reg is very high I/O register
		; we may use macros: in, out
		OS_Reg_isVarIO = 1
#endif
	.endif /* OS_Reg_isLoReg + OS_Reg_isHiReg */

#endif /* !defined( OS_Reg ) */


	OS_Reg_isIO = OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO


	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Undefined type of  OS_Reg
	.endif

	.if OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO \
		- 1
	.error Wrong type of  OS_Reg
	.endif


.macro	OS_interrupt_status	iev, v, reg
	_get_reg \iev, \reg	; \reg = \iev

	.L_m_iev = 0

	.ifc \iev, interrupt_enabled
	.L_m_iev = 1
	.endif ; interrupt_enabled

	.ifc \iev, Interrupt_Enabled
	.L_m_iev = 1
	.endif ; Interrupt_Enabled

	.ifc \iev, INTERRUPT_ENABLED
	.L_m_iev = 1
	.endif ; INTERRUPT_ENABLED

	.ifc \iev, interrupts_enabled
	.L_m_iev = 1
	.endif ; interrupts_enabled

	.ifc \iev, Interrupts_Enabled
	.L_m_iev = 1
	.endif ; Interrupts_Enabled

	.ifc \iev, INTERRUPTS_ENABLED
	.L_m_iev = 1
	.endif ; INTERRUPTS_ENABLED

	.ifc \iev, interrupt_enable
	.L_m_iev = 1
	.endif ; interrupt_enable

	.ifc \iev, Interrupt_Enable
	.L_m_iev = 1
	.endif ; Interrupt_Enable

	.ifc \iev, INTERRUPT_ENABLE
	.L_m_iev = 1
	.endif ; INTERRUPT_ENABLE

	.ifc \iev, interrupts_enable
	.L_m_iev = 1
	.endif ; interrupts_enable

	.ifc \iev, Interrupts_Enable
	.L_m_iev = 1
	.endif ; Interrupts_Enable

	.ifc \iev, INTERRUPTS_ENABLE
	.L_m_iev = 1
	.endif ; INTERRUPTS_ENABLE


	.ifc \iev, interrupt_disabled
	.L_m_iev = 2
	.endif ; interrupt_disabled

	.ifc \iev, Interrupt_Disabled
	.L_m_iev = 2
	.endif ; Interrupt_Disabled

	.ifc \iev, INTERRUPT_DISABLED
	.L_m_iev = 2
	.endif ; INTERRUPT_DISABLED

	.ifc \iev, interrupts_disabled
	.L_m_iev = 2
	.endif ; interrupts_disabled

	.ifc \iev, Interrupts_Disabled
	.L_m_iev = 2
	.endif ; Interrupts_Disabled

	.ifc \iev, INTERRUPTS_DISABLED
	.L_m_iev = 2
	.endif ; INTERRUPTS_DISABLED

	.ifc \iev, interrupt_disable
	.L_m_iev = 2
	.endif ; interrupt_disable

	.ifc \iev, Interrupt_Disable
	.L_m_iev = 2
	.endif ; Interrupt_Disable

	.ifc \iev, INTERRUPT_ENABLE
	.L_m_iev = 2
	.endif ; INTERRUPT_DISABLE

	.ifc \iev, interrupts_disable
	.L_m_iev = 2
	.endif ; interrupts_disable

	.ifc \iev, Interrupts_Disable
	.L_m_iev = 2
	.endif ; Interrupts_Disable

	.ifc \iev, INTERRUPTS_DISABLE
	.L_m_iev = 2
	.endif ; INTERRUPTS_DISABLE

	\v = .L_m_iev
.endm	; OS_interrupt_status



.macro	OS_Disable_Interrupts	iev_s, iev_reg
	; запрещает прерывания (если нужно)
	.ifeq 1 - \iev_s ; iev_s == 1
	cli
	.else ; iev_s == 1
	.ifeq \iev_s ; iev_s == 0
	_get_reg \iev_reg, .L_osdi_reg
	in	.L_osdi_reg, SREG
	cli
	.endif ; iev_s == 0
	.endif ; iev_s == 1
.endm	; OS_Disable_Interrupts


.macro	OS_Restore_Interrupts	iev_s, iev_reg
	; разрешает прерывания (если нужно)
	.ifeq 1 - \iev_s ; iev_s == 1
	sei
	.else ; iev_s == 1
	.ifeq \iev_s ; iev_s == 0
	_get_reg \iev_reg, .L_osdi_reg
	out	SREG, .L_osdi_reg
	.endif ; iev_s == 0
	.endif ; iev_s == 1
.endm	; OS_Enable_Interrupts



.macro	set_rampD	reg, var, old = "unknown"
#if defined(RAMPD) && !defined(NoSaveRAMPD)
	ldi	\reg, hlo8(var)
	out	RAMPD, \reg
#endif
.endm	; set_rampD

.macro	set_rampX	reg, var, old = "unknown"
#if defined(RAMPX) && !defined(NoSaveRAMPX)
	ldi	\reg, hlo8(var)
	out	RAMPX, \reg
#endif
.endm	; set_rampX

.macro	set_rampY	reg, var, old = "unknown"
#if defined(RAMPY) && !defined(NoSaveRAMPY)
	ldi	\reg, hlo8(var)
	out	RAMPY, \reg
#endif
.endm	; set_rampY

.macro	set_rampZ	reg, var, old = "unknown"
#if defined(RAMPZ) && !defined(NoSaveRAMPZ)
	ldi	\reg, hlo8(var)
	out	RAMPZ, \reg
#endif
.endm	; set_rampZ


.macro	post_add_X	reg
#if defined(RAMPX) && !defined(NoSaveRAMPX)
	brcc	201f
	in	\reg, RAMPX
	inc	\reg
	out	RAMPX, \reg
201:
#endif
.endm	; post_add_X

.macro	post_add_Y	reg
#if defined(RAMPY) && !defined(NoSaveRAMPY)
	brcc	201f
	in	\reg, RAMPY
	inc	\reg
	out	RAMPY, \reg
201:
#endif
.endm	; post_add_Y

.macro	post_add_Z	reg
#if defined(RAMPZ) && !defined(NoSaveRAMPZ)
	brcc	201f
	in	\reg, RAMPZ
	inc	\reg
	out	RAMPZ, \reg
201:
#endif
.endm	; post_add_Z


.macro	post_sub_X	reg
#if defined(RAMPX) && !defined(NoSaveRAMPX)
	brcc	201f
	in	\reg, RAMPX
	dec	\reg
	out	RAMPX, \reg
201:
#endif
.endm	; post_sub_X

.macro	post_sub_Y	reg
#if defined(RAMPY) && !defined(NoSaveRAMPY)
	brcc	201f
	in	\reg, RAMPY
	dec	\reg
	out	RAMPY, \reg
201:
#endif
.endm	; post_sub_Y

.macro	post_sub_Z	reg
#if defined(RAMPZ) && !defined(NoSaveRAMPZ)
	brcc	201f
	in	\reg, RAMPZ
	dec	\reg
	out	RAMPZ, \reg
201:
#endif
.endm	; post_sub_Z


;
; wordset:avr-gcc-os
;
; End of file  os-internal.inc
