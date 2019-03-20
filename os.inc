; share/avr/silOS/os.inc
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


#if !defined( OS_H_INCLUDED )
#error "Include  os/os.h  file instead of this file (os/os.inc)"
#endif

#include "genmacro/genmacro.inc"


;
; Макросы для обработчиков прерываний.
;
; SAVE_REGS          	- сохранение регистров OS_wReg и SREG
; RESTORE_REGS       	- восстановление регистров SREG и OS_wReg
; TO_ISR_STACK       	- переключение на стек прерываний
;
; ISR_ENTER          	- макрос входа в прерывание (сохраняет регистры и
;                    	  переключает стек)
; ISR_EXIT           	- макрос выхода из прерывания (восстанавливает регистры
;                    	  и выполняет команду reti)
;
; RESET_SIGNAL       	- сброс сигнала
; IS_SIGNAL_SET      	- проверка состояния сигнала
; SET_OS_TIMER       	- установка таймера ОС
; GET_OS_TIMER       	- получение значения таймера ОС
; GET_MUTEX_OWNER    	- получение номера потока-владельца мьютекса
; GET_SEMAPHORE_STATE	- получение состояния семафора
; ACTIVATE_THREAD    	- активизация потока
;

;
; Примерная структура обработчика прерывания
;
; ISR:	SAVE_REGS
;	; желательно стек (потока) не использовать
;	....
;	brxx	m_1		; не обязательно
;	....
;	RESTORE_REGS
;	sei			; не обязательно
;	reti
;
; m_1:	....
;	; состояние стека должно быть таким же, как после макроса SAVE_REGS
;	TO_ISR_STACK	Interrupts_Disable
;	; стек (прерываний) можно свободно использовать
;	....
;	sei			; не обязательно
;	....
;	cli			; может быть нужно
;	....			; если есть iSREG, то необходимо его восстановить
;	RESTORE_REGS
;	sei			; не обязательно
;	reti
;


;
; Состояние стеков после макроса TO_ISR_STACK
;
; Первое прерывание
;
; Стек потока        		Стек прерываний
;   ...used space... 		  OS's scheduler address
;   return address   		  fake OS_wReg
;   OS_wReg          		  [fake SREG]
;   SREG             		  ...free space...
;   ...free space...
;
;
; Вложенное прерывание (состояние стека потока не меняется)
;
; Стек потока			Стек прерываний
;   ...used space... 		  OS's scheduler address
;   return address   		  fake OS_wReg
;   OS_wReg          		  [fake SREG]
;   SREG             		  ...used space...
;   ...free space... 		  return into first ISR address
;                    		  OS_wReg
;                    		  [SREG]
;                    		  ...free space...
;


;
; Идеалогия следующая: при программировании на ассемблере у программиста
; должна быть максимальная свобода выбора.  Должна быть возможность
; совершать полезные действия сразу после перехода на подпрограмму обработки
; прерывания, даже ещё до сохранения регистров (в том числе и регистра флагов).
; Такой свободы можно достичь только разделив сохранение контекста на
; стадии сохранения регистров и переключения на стек прерываний.
; Сохранение регистров до переключения на стек прерываний программист
; может выполнять любым образом; необходимо только, чтобы перед
; выполенением макроса TO_ISR_STACK стек потока был в том же состоянии,
; что и после выполнения макроса SAVE_REGS.
;

;
; Полагаем, что в икс-мегах сохранение регистра SREG в регистре iSREG
; не используется (т.к. в общем случае избавиться от вложенных прерываний
; невозможно); т.е. в икс-мегах ОС ни для каких целей не использует
; регистр iSREG (если он определён).
;
; В мегах регистр флагов SREG может сохраняться в регистре iSREG (для
; ускорения обработки прерываний), и ОС именно так и поступает (если
; определён регистр с именем iSREG).  Сохранение регистра iSREG в стеке
; (в стеке прерываний) перед разрешением вложенных прерываний, --
; забота программиста.
;


.macro	SAVE_REGS

	push	OS_wReg

#if defined( iSREG ) && !__ATXMEGA__
	in	iSREG, SREG
#else /* !defined( iSREG ) || __ATXMEGA__ */
	in	OS_wReg, SREG
	push	OS_wReg
#endif /* defined( iSREG ) && !__ATXMEGA__ */

.endm	; SAVE_REGS



.macro	RESTORE_REGS

#if defined( iSREG ) && !__ATXMEGA__
	out	SREG, iSREG	; always must be real SREG
#else /* !defined( iSREG ) || __ATXMEGA__*/
	pop	OS_wReg		; fake (in first ISR) or real SREG
	out	SREG, OS_wReg
#endif /* defined( iSREG ) && !__ATXMEGA__ */

	pop	OS_wReg		; fake (in first ISR) or real OS_wReg

.endm	; RESTORE_REGS



; Переключение на стек прерываний

#if __ATXMEGA__

.macro	TO_ISR_STACK	iev="unknown"
; На входе макроса прерывания могут быть как разрешены, так и запрещены.
;
; Interrupts_Enabled  -- прерывания разрешены
; Interrupts_Disabled -- прерывания запрещеры
	OS_interrupt_status	\iev, .L_iev, .L_iev_reg

#else /* !__ATXMEGA__ */

.macro	TO_ISR_STACK	iev="Interrupts_Disable"
; На входе макроса прерывания обязательно должны быть запрещены!
;
; Interrupts_Enable  -- разрешить прерывания на выходе макроса
; Interrupts_Disable -- запретить прерывания на выходе макроса
	OS_interrupt_status	\iev, .L_iev, .L_iev_reg
	.ifeq	.L_iev
	.error	"Parameter of TO_ISR_STACK must be 'Interrupts_Enable' or 'Interrupts_Disable'"
	.endif

#endif /* __ATXMEGA__ */


#if defined( SPH )		/* указатель стека из двух байтов */


	in	OS_wReg, SPH
	cpi	OS_wReg, High( ISR_Stack_Fence )
	brcs	101f		; уже активен стек прерываний; ничего не делаем
	; now we use thread's stack

#if __ATXMEGA__
	; запрещаем прерывания, если они были разрешены
	.ifeq	.L_iev
	brid	102f
	sec			; установили флаг разрешённых пренываний
	cli
102:
	.endif

	.ifeq	.L_iev - 1
	cli
	.endif
#else /* !__ATXMEGA__ */
#if defined( iSREG )
	; always save SREG in thread's stack
	push	iSREG
#if !defined( iSPH )
	; указатель стека поменялся, обновляем значение в OS_wReg
	; (значение из OS_wReg используется, если не определён регистр iSPH)
	in	OS_wReg, SPH
#endif /* !defined( iSPH ) */
#endif /* defined( iSREG ) */
#endif /* __ATXMEGA__ */

	; save SPH:SPL
#if defined( iSPH )
	in	iSPH, SPH
	in	iSPL, SPL
#else /* !defined( iSPH ) */
	sts	ISR_SPsave+1, OS_wReg
	in	OS_wReg, SPL
	sts	ISR_SPsave, OS_wReg
#endif /* defined( iSPH ) */

	; set new value in SPH:SPL
	ldi	OS_wReg, Low( ISR_Stack_Top )
	out	SPL, OS_wReg
	ldi	OS_wReg, High( ISR_Stack_Top )

	; разрешаем прерывания, если об этом попросили
#if __ATXMEGA__
	.ifeq	.L_iev
	brcc	102f
	sei
102:
	.endif

	.ifeq	.L_iev - 1
	sei
	.endif

	out	SPH, OS_wReg
#else /* !__ATXMEGA__ */
	out	SPH, OS_wReg
	.ifeq	1 - .L_iev
101:
	sei
	.endif
#endif /* __ATXMEGA__ */


#else /* !defined( SPH ) */	/* указатель стека из одного байта */


	in	OS_wReg, SPL
	cpi	OS_wReg, Low( ISR_Stack_Fence )
	brcs	101f		; уже активен стек прерываний; ничего не делаем
	; now we use thread's stack
#if defined( iSREG )
	; always save SREG in thread's stack
	push	iSERG
#if !defined( iSPL )
	; указатель стека поменялся, обновляем значение в OS_wReg
	; (значение из OS_wReg используется, если не определён регистр iSPL)
	in	OS_wReg, SPL
#endif /* !defined( iSPL ) */
#endif /* !defined( iSREG ) */

	; save SPL
#if defined( iSPL )
	in	iSPL, SPL
#else /* !defined( iSPL ) */
	sts	ISR_SPsave, OS_wReg
#endif /* defined( iSPL ) */
	; set new value in SPL
	ldi	OS_wReg, Low( ISR_Stack_Top )
	out	SPL, OS_wReg
	.ifeq	1 - .L_iev
101:
	sei
	.endif


#endif /* defined( SPH ) */

101:
.endm	; TO_ISR_STACK



.macro	ISR_ENTER
	SAVE_REGS
#if __ATXMEGA__
	TO_ISR_STACK	Interrupts_Enabled
#else /* !__ATXMEGA__ */
	TO_ISR_STACK	Interrupts_Disable
#endif /* __ATXMEGA__ */
.endm	; ISR_ENTER


.macro	ISR_EXIT
	RESTORE_REGS
	sei
	reti
.endm



.macro	RESET_SIGNAL	iev, work_reg, signal
; Сброс указанного сигнала
; Параметры:
;	iev: interrupt_enabled - прерывания разрешены
;	     interrupt_disabled - прерывания запрещены
;	     либо имя регистра для сохранения регистра флагов на время
;	     запрещения прерываний
;	work_reg: рабочий регистр из верхней половины, который используется
;	     макросом (регистр используется при запрещённых прерываниях,
;	     поэтому им может быть и несохраняемый в прерываниях регистр)
;	signal: номер сигнала

	OS_interrupt_status	\iev, .L_iev, .L_iev_reg

	OS_Disable_Interrupts	.L_iev, .L_iev_reg
	lds	\work_reg, OS_Signals + (\signal-1) / 8
	andi	\work_reg, ~(1 << ((\signal-1) & 7))
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	sts	OS_Signals + (\signal-1) / 8, \work_reg

.endm	; RESET_SIGNAL


.macro	IS_SIGNAL_SET	work_reg, signal
; Проверка состояния указанного сигнала
; Параметры:
;	work_reg: рабочий регистр из верхней половины (используется макросом)
;	     т.к. прерывания не разрешаются и не запрещаются
;	     work_reg не должен меняться в прерываниях или прерывания
;	     должны быть запрещены
;	signal: номер сигнала
; На выходе:
;	в регистре work_reg: 0 -- сигнал сброшен, не 0 -- сигнал установлен
;	флаг Z: есть флаг -- сигнал сброшен, нет флага -- сигнал установлен
;

	lds	\work_reg, OS_Signals + (\signal-1) / 8
	andi	\work_reg, (1 << ((\signal-1) & 7))

.endm	; IS_SIGNAL_SET


.macro	SET_OS_TIMER	iev, timer, regHi, regLo
; Установка таймера ОС
; Параметры:
;	iev: interrupt_enabled - прерывания разрешены
;	     interrupt_disabled - прерывания запрещены
;	     либо имя регистра для сохранения регистра флагов на время
;	     запрещения прерываний
;	timer: устанавливаемый таймер
;	regHi, regLo: пара регистров со значением для таймера
;

	OS_interrupt_status	\iev, .L_iev, .L_iev_reg

	OS_Disable_Interrupts	.L_iev, .L_iev_reg
	sts	OS_Timers + (\timer-1)*2, \regLo
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	sts	OS_Timers + (\timer-1)*2 + 1, \regHi

.endm	; SET_OS_TIMER


.macro	GET_OS_TIMER	iev, timer, regHi, regLo
; Получение значения таймера ОС
; Параметры:
;	iev: interrupt_enabled - прерывания разрешены
;	     interrupt_disabled - прерывания запрещены
;	     либо имя регистра для сохранения регистра флагов на время
;	     запрещения прерываний
;	timer: устанавливаемый таймер
;	regHi, regLo: пара регистров под значение таймера
;

	OS_interrupt_status	\iev, .L_iev, .L_iev_reg

	OS_Disable_Interrupts	.L_iev, .L_iev_reg
	lds	\regLo, OS_Timers + (\timer-1)*2
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	lds	\regHi, OS_Timers + (\timer-1)*2 + 1

.endm	; GET_OS_TIMER


.macro	GET_MUTEX_OWNER	reg, mutex
	lds	\reg, OS_Mutexes + NumCMutexes + \mutex - 1
.endm	; GET_MUTEX_OWNER


.macro	GET_SEMAPHORE_STATE	reg, semaphore
	lds	\reg, OS_Semaphores + \semaphore - 1
.endm	; GET_SEMAPHORE_STATE


	.macro	ACTIVATE_THREAD iev, work_reg, thread
; Активизация указанного потока
; Параметры:
;	iev: interrupt_enabled - прерывания разрешены
;	     interrupt_disabled - прерывания запрещены
;	     либо имя регистра для сохранения регистра флагов на время
;	     запрещения прерываний
;	work_reg: рабочий регистр, который используется макросом
;	     (использование рабочего регистра происходит при запрещённых
;	     прерываниях, поэтому рабочим регистром может быть iReg)
;	thread: номер активизируемого потока

	.ifeq	\thread
	.error	"'thread' is 0"
	.endif

	.iflt	NumThreads - \thread
	; NumThreads < thread
	.error	"'thread' is greater than number of threads"
	.endif   ; NumThreads - \thread

	OS_interrupt_status	\iev, .L_iev, .L_iev_reg



#if __BlockingRes || BIG_SLEEP || !defined( ZeroReg )



	OS_Disable_Interrupts	.L_iev, .L_iev_reg

#if defined( ZeroReg )
#define ZRR	ZeroReg
#else /* ZeroReg */
	clr	\work_reg
#define ZRR	\work_reg
#endif /* ZeroReg */

	; обнуляем поле BlockingRes
#if __BlockingRes
	sts	OS_TSBs + (\thread - 1)*SizeOfTSB + BlockingRes, ZRR
#endif /* __BlockingRes */

	; обнуляем поле SleepCounter
	; и сбрасываем флаг неизменности списка активных потоков
#if BIG_SLEEP
	sts	OS_TSBs + (\thread - 1)*SizeOfTSB + SleepCounter+1, ZRR
#endif /* BIG_SLEEP */

	.if OS_Reg_isAbsent
	sts	OS_TSBs + (\thread - 1)*SizeOfTSB + SleepCounter, ZRR
	lds	\work_reg, OS_Flags
	andi	\work_reg, ~1
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	sts	OS_Flags, \work_reg
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	sbrc	OS_Reg, 0
	dec	OS_Reg
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	sts	OS_TSBs + (\thread - 1)*SizeOfTSB + SleepCounter, ZRR
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	sts	OS_TSBs + (\thread - 1)*SizeOfTSB + SleepCounter, ZRR
	andi	OS_Reg, ~1
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	sts	OS_TSBs + (\thread - 1)*SizeOfTSB + SleepCounter, ZRR
	in	\work_reg, OS_Reg
	andi	\work_reg, ~1
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	out	OS_Reg, \work_reg
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

#undef ZRR



#else /* !__BlockingRes && !BIG_SLEEP && !defined( ZeroReg ) */



	; обнуляем поле SleepCounter
	; и сбрасываем флаг неизменности списка активных потоков
	.if OS_Reg_isAbsent
	sts	OS_TSBs + (\thread - 1)*SizeOfTSB + SleepCounter, ZeroReg
	OS_Disable_Interrupts	.L_iev, .L_iev_reg
	lds	\work_reg, OS_Flags
	andi	\work_reg, ~1
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	sts	OS_Flags, \work_reg
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	OS_Disable_Interrupts	.L_iev, .L_iev_reg
	sbrc	OS_Reg, 0
	dec	OS_Reg
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	sts	OS_TSBs + (\thread - 1)*SizeOfTSB + SleepCounter, ZeroReg
	.else	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	sts	OS_TSBs + (\thread - 1)*SizeOfTSB + SleepCounter, ZeroReg
	andi	OS_Reg, ~1
	.else	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	sts	OS_TSBs + (\thread - 1)*SizeOfTSB + SleepCounter, ZeroReg
	OS_Disable_Interrupts	.L_iev, .L_iev_reg
	in	\work_reg, OS_Reg
	andi	\work_reg, ~1
	OS_Restore_Interrupts	.L_iev, .L_iev_reg
	out	OS_Reg, \work_reg
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		


#endif /* __BlockingRes || BIG_SLEEP || !defined( ZeroReg ) */

	.endm ; ACTIVATE_THREAD


;
; wordset:avr-gcc-os
;
; End of file  os.inc
