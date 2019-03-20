/* share/avr/silOS/isr.h */

/*
 silOS: Short Interrupt Latency OS
 Copyright (C) 2010 Potrepalov I.S.  potrepalov@list.ru

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/


/*
  import macros: OS_ISR( vect, ... )
*/


#if !defined( OS_ISR_H_INCLUDED )
#define OS_ISR_H_INCLUDED


#include "os.h"


#if (__GNUC__ == 4 && __GNUC_MINOR__ >= 1) || (__GNUC__ > 4)
#	define __INTR_ATTRS used, externally_visible
#else /* GCC < 4.1 */
#	define __INTR_ATTRS used
#endif



/*
; Состояние стеков после макроса OS_ISR
;
; Первое прерывание
;
; Стек потока        		Стек прерываний
;   ...used space... 		  OS's scheduler address
;   return address   		  ...free space...
;   OS_wReg
;   SREG
;   ...free space...
;
;
; Вложенное прерывание (состояние стека потока не меняется)
;   ...used space... 		  OS's scheduler address
;   return address   		  fake OS_wReg
;   OS_wReg          		  [fake SREG]
;   SREG             		  ...used space...
;   ...free space... 		  return into ISR address
;                    		  ...free space...
;
*/

/* вспомогательные макросы для макроса OS_ISR */


#define	OS_ISR__SaveRegs					\
	"push	" OS_H_TOSTR( OS_wReg )			"\n"	\
	"in	" OS_H_TOSTR( OS_wReg ) ", %[sreg]"	"\n"	\
	"push	" OS_H_TOSTR( OS_wReg )			"\n"

#define OS_ISR__RestoreRegs					\
	"pop	" OS_H_TOSTR( OS_wReg )			"\n"	\
	"out	%[sreg]," OS_H_TOSTR( OS_wReg )		"\n"	\
	"pop	" OS_H_TOSTR( OS_wReg )			"\n"


#if defined( __ATXMEGA__ )

// на время сохранения и изменения регистра SP запрещаем прерыания
#define	OS_ISR__Enable		"sei"
#define OS_ISR__Defence		"cli"

#else /* !defined( __ATXMEGA__ ) */

// убираем флаг I в том значении, которое попадёт в регистр SREG при
// выполнении макроса OS_ISR__RestoreRegs после переключения на
// стек прерываний
#define	OS_ISR__Enable	""
#define OS_ISR__Defence						\
	"ldi	" OS_H_TOSTR( OS_wReg ) ", 0"		"\n"	\
	"sts	%[sreg_pos]," OS_H_TOSTR( OS_wReg )

#endif /* !defined( __ATXMEGA__ ) */





#if __AVR_HAVE_SPH__		/* =============[ 1 (SPH) ]============ */


#if defined( iSPL )		/* -------------[ 2 (iSPL) ]------------ */

#define OS_ISR__SaveSP						\
	"in	" OS_H_TOSTR( iSPL ) ", %[spl]"		"\n"	\
	"in	" OS_H_TOSTR( iSPH ) ", %[sph]"

#define OS_ISR__SP_PARAMS		\
	[spl] "I" (_SFR_IO_ADDR(SPL)),	\
	[sph] "I" (_SFR_IO_ADDR(SPH))

#else /* !defined( iSPL ) */	/* -------------[ 2 (iSPL) ]------------ */

#define OS_ISR__SaveSP						\
	"in	" OS_H_TOSTR( OS_wReg ) ", %[spl]"	"\n"	\
	"sts	%[spsave0]," OS_H_TOSTR( OS_wReg )	"\n"	\
	"in	" OS_H_TOSTR( OS_wReg ) ", %[sph]"	"\n"	\
	"sts	%[spsave1]," OS_H_TOSTR( OS_wReg )

#define OS_ISR__SP_PARAMS			\
	[spsave0] "m" (OS_Vars.SPsave[0]),	\
	[spsave1] "m" (OS_Vars.SPsave[1]),	\
	[spl] "I" (_SFR_IO_ADDR(SPL)),		\
	[sph] "I" (_SFR_IO_ADDR(SPH))

#endif /* defined( iSPL ) */	/* -------------[ 2 (iSPL) ]------------ */


#define	OS_ISR__TO_ISR_STACK					\
	"in	" OS_H_TOSTR( OS_wReg ) ", %[sph]"	"\n"	\
	"cpi	" OS_H_TOSTR( OS_wReg ) ", hi8(%[fence]) \n"	\
	"brcs	505f"					"\n"	\
	OS_ISR__Defence					"\n"	\
	OS_ISR__SaveSP					"\n"	\
	"ldi	" OS_H_TOSTR( OS_wReg ) ", hi8(%[top])"	"\n"	\
	"out	%[sph]," OS_H_TOSTR( OS_wReg )		"\n"	\
	"ldi	" OS_H_TOSTR( OS_wReg ) ", lo8(%[top])"	"\n"	\
	OS_ISR__Enable					"\n"	\
	"out	%[spl]," OS_H_TOSTR( OS_wReg )		"\n"	\
	"505:	"					"\n"


#else /* !__AVR_HAVE_SPH__ */	/* =============[ 1 (SPH) ]============ */


#if defined( iSPL )		/* -------------[ 2 (iSPL) ]------------ */

#define OS_ISR__SaveSPL						\
	"in	" OS_H_TOSTR( iSPL ) ", %[spl]"

#define OS_ISR__SP_PARAMS			\
	[spl] "I" (_SFR_IO_ADDR(SPL))

#else /* !defined( iSPL ) */	/* -------------[ 2 (iSPL) ]------------ */

#define OS_ISR__SaveSPL						\
	"in	" OS_H_TOSTR( OS_wReg ) ", %[spl]"	"\n"	\
	"sts	%[spsave0]," OS_H_TOSTR( OS_wReg )

#define OS_ISR__SP_PARAMS			\
	[spsave0] "m" (OS_Vars.SPsave[0]),	\
	[spl] "I" (_SFR_IO_ADDR(SPL))

#endif /* defined( iSPL ) */	/* -------------[ 2 (iSPL) ]------------ */


#define	OS_ISR__TO_ISR_STACK					\
	"in	" OS_H_TOSTR( OS_wReg ) ", %[spl]"	"\n"	\
	"cpi	" OS_H_TOSTR( OS_wReg ) ", lo8(%[fence]) \n"	\
	"brcs	505f"					"\n"	\
	OS_ISR__Defence					"\n"	\
	OS_ISR__SaveSPL					"\n"	\
	"ldi	" OS_H_TOSTR( OS_wReg ) ", lo8(%[top])"	"\n"	\
	OS_ISR__Enable					"\n"	\
	"out	%[spl]," OS_H_TOSTR( OS_wReg )		"\n"	\
	"505:	"					"\n"


#endif /* __AVR_HAVE_SPH__ */	/* =============[ 1 (SPH) ]============ */



#define OS_ISR( vect, ... )						\
void vect ( void )	__attribute__ ((naked,__INTR_ATTRS));		\
void __vector_silOS_func__ ## vect ( void )				\
			__attribute__ ((signal,used)) __VA_ARGS__;	\
									\
void vect ( void ) { 							\
	asm volatile(							\
		OS_ISR__SaveRegs					\
		OS_ISR__TO_ISR_STACK					\
		OS_ISR__RestoreRegs					\
		_OS_THREAD__JMP						\
		    OS_H_TOSTR( __vector_silOS_func__ ## vect )	 " \n"	\
		: /* no outputs */					\
		: [sreg] "I" (_SFR_IO_ADDR(SREG)),			\
		  [sreg_pos] "i" (OS_ISR_Stack_SREG_Pos),		\
		  [top] "i" (OS_ISR_Stack_Top),				\
		  [fence] "i" (ISR_Stack_Fence),			\
		  OS_ISR__SP_PARAMS					\
	);								\
} /* vect */								\
void __vector_silOS_func__ ## vect ( void )


#endif /* OS_ISR_H_INCLUDED */


/* wordset:avr-gcc-os */

/* End of file  isr.h */
