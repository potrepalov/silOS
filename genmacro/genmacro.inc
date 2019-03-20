; share/avr/genmacro/genmacro.inc
;
; Copyright Potrepalov I.S.  potrepalov@list.ru
;
;  ћакросы общего назначени€
;


#ifndef SHARE_AVR_GENMACRO_INC_INCLUDED
#define SHARE_AVR_GENMACRO_INC_INCLUDED


#define Low( val )	lo8( val )
#define High( val )	hi8( val )


#undef in
#undef out
#undef sbi
#undef cbi
#undef sbic
#undef sbis
#undef adiw
#undef sbiw
#undef movw


.macro _get_reg	reg,v
; ѕо имени регистра reg возвращает его номер в переменной v
; »м€ может быть одним из следующих: r0, r1, ..., r31, R0, R1, ..., R31,
; x, y, z, X, Y, Z, xl, xh, yl, yh, zl, zh, XL, XH, YL, YH, ZL, ZH
; ≈сли им€ не совпадает ни с одним из указанных, то в переменной v возвращаетс€
; значение reg.

; Ётот макрос позвол€ет писать команды 'adiw Z, xxx', 'movw X, r10'

	.L_reg = \reg	; возвращаемое значение по умолчанию

	.L_reg_n = 26
	.irp	_reg,	X,Y,Z
		.ifc	\reg,\_reg
			.L_reg = .L_reg_n
		.endif
		.L_reg_n = .L_reg_n + 2
	.endr

	.L_reg_n = 26
	.irp	_reg,	x,y,z
		.ifc	\reg,\_reg
			.L_reg = .L_reg_n
		.endif
		.L_reg_n = .L_reg_n + 2
	.endr

	.L_reg_n = 26
	.irp	_reg,	xl,xh,yl,yh,zl,zh
		.ifc	\reg,\_reg
			.L_reg = .L_reg_n
		.endif
		.L_reg_n = .L_reg_n + 1
	.endr

	.L_reg_n = 26
	.irp	_reg,	XL,XH,YL,YH,ZL,ZH
		.ifc	\reg,\_reg
			.L_reg = .L_reg_n
		.endif
		.L_reg_n = .L_reg_n + 1
	.endr

	.L_reg_n = 0
	.irp	_reg,	r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, \
			r10,r11,r12,r13,r14,r15,r16,r17,r18,r19, \
			r20,r21,r22,r23,r24,r25,r26,r27,r28,r29, \
			r30,r31
		.ifc	\reg,\_reg
			.L_reg = .L_reg_n
		.endif
		.L_reg_n = .L_reg_n + 1
	.endr

	.L_reg_n = 0
	.irp	_reg,	R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, \
			R10,R11,R12,R13,R14,R15,R16,R17,R18,R19, \
			R20,R21,R22,R23,R24,R25,R26,R27,R28,R29, \
			R30,R31
		.ifc	\reg,\_reg
			.L_reg = .L_reg_n
		.endif
		.L_reg_n = .L_reg_n + 1
	.endr

	\v = .L_reg
.endm ; _get_reg


.macro addi	to, val
; ѕрибавление константы к регистру
	subi	\to, 0 - (\val)
.endm ; addi

.macro addiw	to, val
; ѕрибавление константы к регистровой паре
	_get_reg	\to, .L_to
	subi	.L_to, lo8(-(\val))
	sbci    .L_to+1, hi8(-(\val))
.endm ; addiw

.macro subiw    to, val
; ¬ычитание константы из регистровой пары
	_get_reg	\to, .L_to
	subi	.L_to, lo8((\val))
	sbci    .L_to+1, hi8((\val))
.endm ; subiw


; «амена команд работающих с парами регистров.
; “ака€ замена позволит использовать удобные имена регистров.

.macro adwi     to, val
	_get_reg        \to, .L_to

	.if	((24 == .L_to) || (26 == .L_to)                 \
			|| (28 == .L_to) || (30 == .L_to))      \
		&& (\val <= 63)
	adiw    .L_to, \val
	.else
	subi    .L_to + 0, lo8(-(\val))
	sbci    .L_to + 1, hi8(-(\val))
	.endif
.endm ; adwi

.macro sbwi     to, val
	_get_reg        \to, .L_to

	.if	((24 == .L_to) || (26 == .L_to)                 \
			|| (28 == .L_to) || (30 == .L_to))      \
		&& (\val <= 63)
	sbiw    .L_to, \val
	.else
	subi    .L_to + 0, lo8(\val)
	sbci    .L_to + 1, hi8(\val)
	.endif
.endm ; sbwi


.macro adiw_x	to, val
	_get_reg	\to, .L_to
	adiw	.L_to, \val
.endm ; adiw_x

.macro sbiw_x	to, val
	_get_reg	\to, .L_from
	sbiw	.L_from, \val
.endm ; sbiw_x

.macro movw_x	to, from
	_get_reg	\to, .L_to
	_get_reg	\from, .L_from
	movw	.L_to, .L_from
.endm ; movw_x


; «амена команд работающих с регистрами ввода/вывода
; “ака€ замена позволит писать 'in r0, PORTA', 'out ETIFR, r0'
; вместо 'in r0, _SFR_IO_ADDR(PORTA)' и 'sts ETIFR, r0'
.macro inb	to, from
	.ifgt \from - 64 - 32
	lds	\to, \from
	.else
	in	\to, _SFR_IO_ADDR( \from )
	.endif
.endm ; inb

.macro inw	to, from
	_get_reg	\to, .L_to
	.ifgt \from - 64 - 32
	lds	.L_to, \from
	lds	.L_to+1, (\from)+1
	.else
	in	.L_to, _SFR_IO_ADDR( \from )
	in	.L_to+1, _SFR_IO_ADDR( \from )+1
	.endif
.endm ; inw


.macro outb	to, from
	.ifgt \to - 64 - 32
	sts	\to, \from
	.else
	out	_SFR_IO_ADDR( \to ), \from
	.endif
.endm ; outb


.macro outw	to, from
	_get_reg	\from, .L_from
#if __AVR_ARCH__ >= 100 /* __ATXMEGA__ */
	.ifgt \to - 64 - 32
	sts	\to, .L_from
	sts	\to+1, (.L_from)+1
	.else
	out	_SFR_IO_ADDR( \to ), .L_from
	out	_SFR_IO_ADDR( \to )+1, (.L_from)+1
	.endif
#else /* !__ATXMEGA__ */
	.ifgt \to - 64 - 32
	sts	\to+1, (.L_from)+1
	sts	\to, .L_from
	.else
	out	_SFR_IO_ADDR( \to )+1, (.L_from)+1
	out	_SFR_IO_ADDR( \to ), .L_from
	.endif
#endif /* __ATXMEGA__ */
.endm ; outw


.macro sbi_x	reg, bit
	sbi	_SFR_IO_ADDR( \reg ), \bit
.endm ; sbi_x

.macro cbi_x	reg, bit
	cbi	_SFR_IO_ADDR( \reg ), \bit
.endm ; cbi_x


.macro sbic_x	reg, bit
	sbic	_SFR_IO_ADDR( \reg ), \bit
.endm ; sbic_x

.macro sbis_x	reg, bit
	sbis	_SFR_IO_ADDR( \reg ), \bit
.endm ; sbis_x


.macro pushw	reg
	_get_reg	\reg, .L_reg
	push	.L_reg
	push	.L_reg+1
.endm ; pushw

.macro popw	reg
	_get_reg	\reg, .L_reg
	pop	.L_reg+1
	pop	.L_reg
.endm ; popw


.macro addw	to, from
	_get_reg	\to, .L_to
	_get_reg	\from, .L_from
	add	.L_to,   .L_from
	adc	.L_to+1, .L_from+1
.endm ; addw

.macro subw	to, from
	_get_reg	\to, .L_to
	_get_reg	\from, .L_from
	sub	.L_to, .L_from
	sbc	.L_to+1, .L_from+1
.endm ; subw

.macro cpw	to, from
	_get_reg	\to, .L_to
	_get_reg	\from, .L_from
	cp	.L_to, .L_from
	cpc	.L_to+1, .L_from+1
.endm ; cpw


.macro letw	reg, val
	_get_reg	\reg, .L_reg
	ldi	.L_reg, Low( \val )
	ldi	.L_reg+1, High( \val )
.endm ; letw


.macro ldsw	reg, addr
	_get_reg	\reg, .L_reg
	lds	.L_reg, \addr
	lds	.L_reg+1, (\addr)+1
.endm ; ldsw

.macro stsw	addr, reg
; ћакрос stsw правильно работает с регистрами ввода/вывода
	_get_reg	\reg, .L_reg
#if __AVR_ARCH__ >= 100 /* __ATXMEGA__ */
	sts	\addr, .L_reg
	sts	(\addr)+1, .L_reg+1
#else /* !__ATXMEGA__ */
	sts	(\addr)+1, .L_reg+1
	sts	\addr, .L_reg
#endif /* __ATXMEGA__ */
.endm ; stsw


.macro ldswr	reg, addr
	_get_reg	\reg, .L_reg
	lds	.L_reg+1, \addr
	lds	.L_reg, (\addr)+1
.endm ; ldswr

.macro stswr	addr, reg
	_get_reg	\reg, .L_reg
#if __AVR_ARCH__ >= 100 /* __ATXMEGA__ */
	sts	\addr, .L_reg+1
	sts	(\addr)+1, .L_reg
#else /* !__ATXMEGA__ */
	sts	(\addr)+1, .L_reg
	sts	\addr, .L_reg+1
#endif /* __ATXMEGA__ */
.endm ; stswr


.macro jeq	lab
	brne	7654f
	rjmp	\lab
7654:
.endm ; jeq


#define adiw	adiw_x
#define sbiw	sbiw_x
#define	movw	movw_x
#define sbic	sbic_x
#define sbis	sbis_x
#define sbi	sbi_x
#define cbi	cbi_x
#define in	inb
#define out	outb


#endif /* SHARE_AVR_GENMACRO_INC_INCLUDED */


;
; wordset:avr-gcc
;
; End of file  genmacro.inc
