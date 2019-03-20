; share/avr/silOS/prepare.S
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

;
; Подготовка блока состояния потока (TSB) к запуску функции потока.
; В функцию потока в качестве данных передается указатель.
; Функция потока должна либо завершаться вызовом функции Stop,
; либо не завершаться никогда (нельзя возвращаться из функции потока).
;
; Реализуется два варианта: 1) функция Thread_Prepare не вызывается
; из обработчиков прерываний; и 2) функция Thread_Prepare вызывается
; из обработчиков прерываний.  Во втором случае параметр в функцию
; потока нужно передавать только через стек (при вызове
; функции Thread_Prepare из обработчика прерывания мы не можем
; менять регистры в TSB текущего потока, т.к. регистры сейчас могут
; находиться в стеке и при переключении потока они будут перенесены в TSB).
;


#include <avr/io.h>
#include "genmacro/genmacro.inc"
#include "os.h"


	.section	".text.OS", "x"

.macro	gts
; Извлекает из таблицы StacksTable в регистр X адрес вершины стека потока
; Номер потока в регистре r24
	letw	Z, StacksTable-2
	add	ZL, r24
	adc	ZH, r1
	add	ZL, r24
	adc	ZH, r1
	lpm	XL, Z+
	lpm	XH, Z
.endm	; gts


.macro	calc_tsb
; Вчисляет адрес TSB подготавливаемого потока
; Номер потока в регистре r24
; Адрес TSB возвращает в регистрах ZH:ZL
#if __AVR_HAVE_MUL__
	ldi	ZL, SizeOfTSB
	mul	ZL, r24
	letw	Z, OS_TSBs - SizeOfTSB
	addw	Z, r0
#if NumThreads * SizeOfTSB > 255
	clr	r1
#endif /* NumThreads * SizeOfTSB */
#else /* __AVR_HAVE_MUL__ */
	mov	r0, r24
	letw	Z, OS_TSBs - SizeOfTSB
1:	adiw	Z, SizeOfTSB
	dec	r0
	brne	1b
#endif /* __AVR_HAVE_MUL__ */
.endm	; calc_tsb


.macro	block_thread
; "Блокирует" поток и устанавливает часть регистров потока
; Адрес блокируемого потока в регистрах ZH:ZL
; Значение для блокировки потока в регистре r25
#if BIG_SLEEP
	std	Z+SleepCounter+1, r1
#endif /* BIG_SLEEP */
#if __BlockingRes
	std	Z+SleepCounter, r1
	std	Z+BlockingRes, r25
#else /* __BlockingRes */
	std	Z+SleepCounter, r25
#endif /* __BlockingRes */


#if defined( RAMPD ) && !defined( NoSaveRAMPD )
	std	Z+SaveRAMPD, r1
#endif /* RMAPD */

#if defined( RAMPX ) && !defined( NoSaveRAMPX )
	std	Z+SaveRAMPX, r1
#endif /* RMAPX */

#if defined( RAMPY ) && !defined( NoSaveRAMPY )
	std	Z+SaveRAMPY, r1
#endif /* RMAPY */

#if defined( RAMPZ ) && !defined( NoSaveRAMPZ )
	std	Z+SaveRAMPZ, r1
#endif /* RMAPZ */

#if defined( EIND ) && !defined( NoSaveEIND )
	std	Z+SaveEIND, r1
#endif /* EIND */
.endm	; block_thread




#if PREPARE_IN_ISR


; Функция Thread_Prepare вызывается из обработчиков прерываний.
; Возможно, что функцию Thread_Prepare вызовут в прерывании для текущего
; потока; в этом случае для передачи параметров в функцию потока можно
; использовать только стек (т.к. неизвестно, где сохранялись регистры).


.global Thread_Prepare
.type	Thread_Prepare, @function

Thread_Prepare:
; TSBindex_t Thread_Prepare(TSBindex_t idx, void (*func)(void*,...), void * dp)
; Готовит TSB потока с номером idx для запуска функции потока func.
; Если номер потока отрицательный, то поток блокируется (т.е. для запуска
; потока необходимо будет выполнить функцию Thread_Activate(idx)).
; В функцию func в качестве параметра передается указатель dp.
; Возвращает номер подготовленного потока (всегда положительное число);
; т.е. можно писать так: Thread_Activate( Thread_Prepare(-idx,func,dp) ).
; Если подготавливает текущий поток вне прерывания, то не возвращается
; (переходит к выполнению указаной функции потока).
; Освобождает все мьютексы, которыми владеет подготавливаемый поток.
; Параметр dp передаётся в функцию потока через стек.
;
; На входе:
;	регистр r24: модуль этого числа -- это номер подготавливаемого
;	             потока (idx); если число больше 0, то поток сразу
;	             после подготовки готов к работе (сразу активизируется);
;	             если число меньше 0, то поток блокируется
;	регистры r23:r22: адрес функции потока (func)
;	регистры r21:r20: данные для потока (dp)
;	регистр r1: ноль
; На выходе:
;	регистр r24: номер подготовленного потока
; Расход стека: 2 байта (адрес возврата)
;
; Если функция вызывается из обработчика прерывания,
; то должен использоваться стек прерываний.

	; блокируем диспетчер потоков (запрещаем переключаться между потоками)
	.if OS_Reg_isHiReg
	addi	OS_Reg, 2
	.else
	rcall	Scheduler_Lock
	.endif	; OS_Reg_isHiReg

	ldi	r25, 0		; значение для SleepCounter/BlockingRes
	tst	r24
	brpl	1f		; номер потока больше нуля
	; номер потока меньше нуля, поток нужно блокировать
	neg	r24
#if __BlockingRes
	ldi	r25, 0xFF	; значение для BlockingRes
#else /* __BlockingRes */
	ldi	r25, 1		; значение для SleepCounter
#endif /* __BlockingRes */
1:
	gts

	; вычисляем адрес TSB подготавливаемого потока
	calc_tsb
	; в Z адрес TSB подготавливаемого потока

	; защищаемся от такой ситуации: поток А вызвал Thread_Prepare( B, ...);
	; происходит прерывание, когда TSB потока B слегка изменен;
	; в прерывании происходит вызов Thread_Prepare( A, ... ).
	; Если прерывания сейчас не запретить, то TSB потока B может
	; так и останется в промежуточном состоянии (т.к. из прерывания
	; возврат будет уже не в поток A, где выполнялась
	; функция Thread_Prepare, а в какой-то другой)
	in	r0, SREG
	cli

	; "блокируем" поток
	block_thread
	; прерывания нельзя разрешать до того, как подготовим стек потока,
	; т.к. возможно, что мы прямо сейчас на него переключимся

	; помещаем параметр в стек потока
	st	X, r21
	st	-X, r20
;	sbiw	X, 2		; место для адреса возврата из функции потока
;	адрес возврата не нужен, т.к. функция потока имеет атрибут naked
;	и мы сами (а не компилятор) извлекаем параметр из стека
;	(если параметр извлекает компилятор, то он учитывает наличие
;	в стеке адреса возврата из функции потока, и тогда нужно
;	выделить место для него)
;	т.о. функцию потока нельзя вызывать как обычную функцию
	; адрес функции потока (к функции потока переходим командой ret)
	st	-X, r22
	st	-X, r23

	; проверяем, не текущий ли поток подготавливаем
	lds	r25, OS_CurTSBindex
	cp	r24, r25
	breq	CurrentThread
	; готовим не текущий поток

	out	SREG, r0	; "разрешаем" прерывания

	; в стеке потока должно находиться ещё два регистра (OS_wReg и SREG)
	; и аппаратный указатель стека должен указывать на свободную ячейку
	st	-X, r1		; OS_wReg
	st	-X, r1		; SREG (флаг I обязательно сброшен)
	sbiw	X, 1		; адрес свободной ячейки
	; запоминаем указатель стека в TSB подготавливаемого потока
#if __AVR_HAVE_SPH__
	std	Z+SaveSPH, XH
#endif /* __AVR_HAVE_SPH__ */
	std	Z+SaveSPL, XL

	; если r25 ноль, значит поток сразу был активизирован
	; и поэтому нужно выставить флаг необходимости переключения потока
	tst	r25
	; если планировщик (OS_Scheduler) работает с тем же потоком,
	; который мы готовим, то результат работы планировщика может
	; быть неправильными (работал планировщик, случилось прерывание,
	; в прерывании вызвали Thread_Prepare, состояние потока поменялось)
	lds	r25, OS_ThreadInProcess
	cpse	r24, r25
	brne	1f

	.if OS_Reg_isAbsent
	cli
	lds	r25, OS_Flags
	andi	r25, ~1
	out	SREG, r0	; "разрешаем" прерывания
	sts	OS_Flags, r25
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	cli
	sbrc	OS_Reg, 0
	dec	OS_Reg
	out	SREG, r0	; "разрешаем" прерывания
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	andi	OS_Reg, ~1
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	cli
	in	r25, OS_Reg
	andi	r25, ~1
	out	SREG, r0	; "разрешаем" прерывания
	out	OS_Reg, r25
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		
1:

#if TotalMutexes
	; освобождаем все мьютексы, которыми владеет подготавливаемый поток
	rcall	ReleaseMutexes
#endif /* TotalMutexes */
	; разблокируем диспетчер потоков
	rjmp	Scheduler_Unlock


CurrentThread:
	; меняем функцию текущего потока
	; после изменения функции потока нужно будет гарантированно
	; разблокировать диспетчер потоков

	; проверим, не в прерывании ли мы
#if __AVR_HAVE_SPH__
	in	r31, SPH
	cpi	r31, High( ISR_Stack_Fence )
#else /* !__AVR_HAVE_SPH__ */
	in	r31, SPL
	cpi	r31, Low( ISR_Stack_Fence )
#endif /* __AVR_HAVE_SPH__ */
	brcs	InInterrupt
	; мы не в прерывании и меняем функцию текущего потока
	; аппаратный указатель стека указывает на свободную ячейку
	sbiw	X, 1		; правим указатель стека
#if __AVR_HAVE_SPH__
	out	SPH, XH
#endif /* __AVR_HAVE_SPH__ */
	sei			;
	out	SPL, XL

#if TotalMutexes
	; освобождаем все мьютексы, которыми владеет подготавливаемый поток
	rcall	ReleaseMutexes
#endif /* TotalMutexes */

	; диспетчер потоков гарантировано будет разблокирован
	; уходим искать активный поток
	cli
	rjmp	_silOS_Real_Switch


InInterrupt:
	; мы в прерывании и меняем функцию текущего потока,
	; и значит стек потока сейчас не используем
	out	SREG, r0	; "разрешаем" прерывания

	; делаем вид, что в прерывание попали непосредственно перед
	; функцией потока (меняем указатель стека прерванного потока)

	; функция потока должна начинаться очисткой регистра r1
	; (в прерывание, откуда будет возврат на начало функции потока,
	; могли попасть при r1 != 0)

	; в стеке потока должно находиться ещё два регистра (OS_wReg и SREG)
	; и аппаратный указатель стека должен указывать на свободную ячейку
	st	-X, r1		; OS_wReg
	st	-X, r1		; SREG (флаг I обязательно сброшен)
	sbiw	X, 1		; адрес свободной ячейки
	; запоминаем указатель стека
#if defined( iSPL )
#if __AVR_HAVE_SPH__
	movw	iSP, X
#else /* !__AVR_HAVE_SPH__ */
	mov	iSPL, XL
#endif /* __AVR_HAVE_SPH__ */
#else /* !iSPL */
	sts	ISR_SPsave, XL
#if __AVR_HAVE_SPH__
	sts	ISR_SPsave+1, XH
#endif /* __AVR_HAVE_SPH__ */
#endif /* iSPL */

#if TotalMutexes
	; освобождаем все мьютексы, которыми владеет подготавливаемый поток
	rcall	ReleaseMutexes
#endif /* TotalMutexes */

	; разблокируем диспетчер потоков
	.if OS_Reg_isAbsent
	sts	OS_Flags, r1
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg + OS_Reg_isHiReg
	clr	OS_Reg
	.endif	; OS_Reg_isLoReg + OS_Reg_isHiReg

	.if OS_Reg_isIO
	out	OS_Reg, r1
	.endif	; OS_Reg_isIO
;	rjmp	Scheduler_Unlock
;	мы сейчас в прерывании, поэтому Scheduler_Unlock только
;	снимит флаг OS_NoSwitchBit, а это мы уже сделали
	ret

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		

#else /* !PREPARE_IN_ISR */


; Функция Thread_Prepare не вызывается из обработчиков прерываний


.global Thread_Prepare
.type	Thread_Prepare, @function

Thread_Prepare:
; TSBindex_t Thread_Prepare(TSBindex_t idx, void (*func)(void*), void * data);
; Готовит TSB потока с номером idx для запуска функции потока func.
; Если номер потока отрицательный, то поток блокируется (т.е. для запуска
; потока необходимо будет выполнить функцию Thread_Activate(idx)).
; В функцию func в качестве параметра передается указатель data.
; Возвращает номер подготовленного потока (всегда положительное число);
; т.е. можно писать так: Thread_Activate( Thread_Prepare(-idx,func,data) ).
; Если подготавливает текущий поток, то не возвращается (переходит к
; выполнению указаной функции потока).
; Освобождает все мьютексы, которыми владеет подготавливаемый поток.
; Параметр data передаётся в функцию потока через регистры.
;
; На входе:
;	регистр r24: модуль этого числа -- это номер подготавливаемого
;	             потока (idx); если число больше 0, то поток сразу
;	             после подготовки готов к работе (сразу активизируется);
;	             если число меньше 0, то поток блокируется
;	регистры r23:r22: адрес функции потока (func)
;	регистры r21:r20: данные для потока (data)
;	регистр r1: ноль
; На выходе:
;	регистр r24: номер подготовленного потока
; Расход стека: 2 байта (адрес возврата)

	; блокируем диспетчер потоков (запрещаем переключаться между потоками)
	.if OS_Reg_isHiReg
	addi	OS_Reg, 2
	.else
	rcall	Scheduler_Lock
	.endif	; OS_Reg_isHiReg

	ldi	r25, 0
	tst	r24
	brpl	1f		; номер потока больше нуля
	; номер потока меньше нуля, поток нужно блокировать
	neg	r24
#if __BlockingRes
	ldi	r25, 0xFF	; значение для BlockingRes
#else /* __BlockingRes */
	ldi	r25, 1		; значение для SleepCounter
#endif /* __BlockingRes */
1:
	gts

	; вычисляем адрес TSB подготавливаемого потока
	calc_tsb
	; в Z адрес TSB подготавливаемого потока

	; "блокируем" поток (диспетчер потоков блокирован, поэтому текущий
	; поток продолжит работать, даже если мы именно его блокируем)
	block_thread

	; проверяем, не текущий ли поток подготавливаем
	lds	r0, OS_CurTSBindex
	cp	r24, r0
	breq	CurrentThread
	; подготавливаем не текущий поток
	; регистры r21:r20 (третий параметр функции) передаются
	; в подготавливаемый поток в регистрах r25:r24 (параметр потока)
	std	Z+SaveR25, r21
	std	Z+SaveR24, r20
	std	Z+SaveR1, r1	; в r1 должен быть ноль

	; на вершину стека подготавливаемого потока помещаем адрес функции
	st	X, r22
	st	-X, r23
	; в стеке потока должно находиться ещё два регистра (OS_wReg и SREG)
	; и аппаратный указатель стека должен указывать на свободную ячейку
	sbiw	X, 3		; OS_wReg, SREG, свободная ячейка

	; запоминаем указатель стека в TSB подготавливаемого потока
#if __AVR_HAVE_SPH__
	std	Z+SaveSPH, XH
#endif /* __AVR_HAVE_SPH__ */
	std	Z+SaveSPL, XL

	; если r25 ноль, значит поток сразу был активизирован
	; и поэтому нужно выставить флаг необходимости прерключения потока
	tst	r25
	brne	1f

	.if OS_Reg_isAbsent
	in	r0, SREG
	cli
	lds	r25, OS_Flags
	andi	r25, ~1
	out	SREG, r0	; "разрешаем" прерывания
	sts	OS_Flags, r25
	.endif	; OS_Reg_isAbsent

	.if OS_Reg_isLoReg
	in	r0, SREG
	cli
	sbrc	OS_Reg, 0
	dec	OS_Reg
	out	SREG, r0	; "разрешаем" прерывания
	.endif	; OS_Reg_isLoReg

	.if OS_Reg_isHiReg
	andi	OS_Reg, ~1
	.endif	; OS_Reg_isHiReg

	.if OS_Reg_isIO
	in	r0, SREG
	cli
	in	r25, OS_Reg
	andi	r25, ~1
	out	SREG, r0	; "разрешаем" прерывания
	out	OS_Reg, r25
	.endif	; OS_Reg_isIO

	.ifeq OS_Reg_isAbsent + OS_Reg_isLoReg + OS_Reg_isHiReg \
		+ OS_Reg_isLoIO + OS_Reg_isHiIO + OS_Reg_isVarIO
	.error Unsupported type of  OS_Reg
	.endif		
1:

#if TotalMutexes
	; освобождаем все мьютексы, которыми владеет подготавливаемый поток
	rcall	ReleaseMutexes
#endif /* TotalMutexes */

	rjmp	Scheduler_Unlock


CurrentThread:
	; меняем функцию текущего потока
#if __AVR_HAVE_SPH__
	cli
	out	SPH, XH
#endif /* __AVR_HAVE_SPH__ */
	; мы не в прерывании, поэтому прерывания разрешаем безусловно
	; (прерывания могли запретить перед вызовом функции Thread_Prepare)
	sei
	out	SPL, XL
	push	r22		; адрес функции потока на вершину стека
	push	r23

#if TotalMutexes
	movw	Y, r20		; сохранаем параметр для функции потока
	; освобождаем все мьютексы, которыми владеет подготавливаемый поток
	rcall	ReleaseMutexes
	movw	r24, Y		; передаём параметр в функцию потока
#else /* !TotalMutexes */
	movw	r24, r20	; передаём второй параметр в функции потока
#endif /* TotalMutexes */

	; диспетчер потоков гарантировано будет разблокирован
	; уходим искать активный поток
	cli
	rjmp	_silOS_Real_Switch


#endif /* PREPARE_IN_ISR */




#if TotalMutexes

ReleaseMutexes:
; освобождает все мьютексы, которыми владеет поток, номер которого
; в регистре r24
; регистр r24 сохраняется
#if TotalMutexes == 1


	lds	r22, OS_Mutexes + NumCMutexes
	cpse	r22, r24
	ret			; мы семафором не владеем
	; семафором владеет поток, номер которого в регистре r24
	; (т.е. семафором владеем мы)
	mov	r22, r24
	ldi	r24, 1
#if NumCMutexes
	sts	OS_Mutexes, r1
#endif /* NumCMutexes */
	rcall	Mutex_Release
	mov	r24, r22
	ret


#else /* TotalMutexes != 1*/


#if NumCMutexes < 64

	mov	r22, r24
	movw	r20, Y
	letw	Y, OS_Mutexes
1:	ldd	r24, Y+NumCMutexes
	cp	r22, r24
	brne	2f		; поток мьютексом не владеет
	; нашли мьютекс, которым владеет поток
	mov	r24, YL
	subi	r24, Low( OS_Mutexes-1 )
#if NumCMutexes
#if NumCMutexes != TotalMutexes
	cpi	r24, NumCMutexes + 1
	brcc	NoCmutex
#endif /* NumCMutexes != TotalMutexes */
	st	Y, r1		; мьютекс нужно безусловно освобождать
NoCmutex:
#endif /* NumCMutexes */
	rcall	Mutex_Release
2:	adiw	Y, 1
	cpi	YL, Low( OS_Mutexes + TotalMutexes )
	brne	1b
	movw	Y, r20
	mov	r24, r22
	ret

#else /* NumCMutexes >= 64 */

	mov	r22, r24
	movw	r20, Y
	letw	Y, OS_Mutexes + NumCMutexes
1:	ld	r24, Y+
	cp	r22, r24
	brne	2f		; поток мьютексом не владеет
	; нашли мьютекс, которым владеет поток
	mov	r24, YL
	subi	r24, Low( OS_Mutexes + NumCMutexes )
#if NumCMutexes != TotalMutexes
	cpi	r24, NumCMutexes + 1
	brcc	NoCmutex
#endif /* NumCMutexes != TotalMutexes */
	movw	Z, Y
	subi	ZL, Low( NumCMutexes )
	sbci	ZH, High( NumCMutexes )
	st	Z, r1		; мьютекс нужно безусловно освобождать
NoCmutex:
	rcall	Mutex_Release
2:	cpi	YL, Low( OS_Mutexes + NumCMutexes + TotalMutexes )
	brne	1b
	movw	Y, r20
	mov	r24, r22
	ret

#endif /* NumCMutexes < 64 */


#endif /* TotalMutexes == 1*/

#endif /* TotalMutexes */




#define StackOff1	(StackOff2  + StackSize2)
#define StackOff2	(StackOff3  + StackSize3)
#define StackOff3	(StackOff4  + StackSize4)
#define StackOff4	(StackOff5  + StackSize5)
#define StackOff5	(StackOff6  + StackSize6)
#define StackOff6	(StackOff7  + StackSize7)
#define StackOff7	(StackOff8  + StackSize8)
#define StackOff8	(StackOff9  + StackSize9)
#define StackOff9	(StackOff10 + StackSize10)
#define StackOff10	(StackOff11 + StackSize11)
#define StackOff11	(StackOff12 + StackSize12)
#define StackOff12	(StackOff13 + StackSize13)
#define StackOff13	(StackOff14 + StackSize14)
#define StackOff14	(StackOff15 + StackSize15)
#define StackOff15	(StackOff16 + StackSize16)
#define StackOff16	0


StacksTable:
#if NumThreads > 1
	.word	__stack - StackOff1
#endif
#if NumThreads > 2
	.word	__stack - StackOff2
#endif
#if NumThreads > 3
	.word	__stack - StackOff3
#endif
#if NumThreads > 4
	.word	__stack - StackOff4
#endif
#if NumThreads > 5
	.word	__stack - StackOff5
#endif
#if NumThreads > 6
	.word	__stack - StackOff6
#endif
#if NumThreads > 7
	.word	__stack - StackOff7
#endif
#if NumThreads > 8
	.word	__stack - StackOff8
#endif
#if NumThreads > 9
	.word	__stack - StackOff9
#endif
#if NumThreads > 10
	.word	__stack - StackOff10
#endif
#if NumThreads > 11
	.word	__stack - StackOff11
#endif
#if NumThreads > 12
	.word	__stack - StackOff12
#endif
#if NumThreads > 13
	.word	__stack - StackOff13
#endif
#if NumThreads > 14
	.word	__stack - StackOff14
#endif
#if NumThreads > 15
	.word	__stack - StackOff15
#endif
#if NumThreads > 16
#error See prepare.S
#endif
	.word	__stack


.size	Thread_Prepare, . - Thread_Prepare


;
; Почему необходимо особо выделять случай, когда Thread_Prepare вызывается
; в обработчиках прерываний.
;
; Рассмотрим передачу управления, сохранение и изменение контекста потока
; при обработке прерывания, в котором выполняется функция Thread_Prepare
; для текущего (активного в момент возникновения прерывания) потока:
;  -- выполняется поток А;
;  -- возникает запрос на прерывание;
;  -- начинает обрабатываться прерывание;
;  -- контекст потока А сохраняется в стеке (в стеке прерываний);
;  -- обрабатывается прерывание;
;  -- вызывается функция Thread_Prepare для потока А (в результате
;     обработки данного прерывания или вложенного);
;  -- изменяется TSB потока А (как можно было бы ожидать);
;  -- возвращаемся из функции Thread_Prepare к обработке прерывания;
;  -- обработка прерывания заканчивается;
;  -- из стека (прерываний) восстанавливается контекст потока А
;     (это уже неправильный, устаревший контекст);
;  -- управление переходит к диспетчеру потоков (т.к. изменилось состояние
;     текущего потока, т.е. изменилось состояние потока А);
;  -- диспетчер потоков сохраняет контекст потока А в TSB потока А
;     (диспетчер потоков всегда сохраняет контекст потока в соответствующем
;     потоку TSB, диспетчер потоков не знает, что содержимое регистров
;     не соответствует содержимому TSB) и "портит" TSB потока А;
;  -- диспетчер потоков в конце концов переходит к выполнению потока А
;     и восстанавливат контекст из TSB;
;  -- управление переходит к новой функции потока А;
;  -- перед выполнением кода новой функции потока А необходимо выполнить
;     некоторые вспомогательные действия: обнулить регистр r1 (его состояние
;     соответствует моменту начала обработки прерывания, в котором была
;     вызвана функция Thread_Prepare), извлечь параметры функции потока
;     из стека и т.п.; эти действия выполняются операционной системой.
;
; Таким образом, функция Thread_Prepare не может использовать TSB активного
; потока для передачи параметров в функцию потока.  Для передачи параметров
; используется стек потока.
; Указатель на вершину стека активного потока при входе в прерывание
; сохраняется в специальном месте и функция Thread_Prepare корректно
; меняет состояние этого "специального" места (переменная ISR_SPsave,
; или пара регистров iSP).
;
; В случае, когда функция Thead_Prepare не вызывается из обработчиков
; прерываний, всё проще: для передачи параметров в функцию потока
; функция Thread_Prepare использует TSB потока.
;


;
; wordset:avr-gcc-os
;
; End of file  prepare.S
