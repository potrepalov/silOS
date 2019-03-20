/* share/avr/silOS/idle/idle.c */

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


/* Вычисление степени бездействия процессора */


#include "../os.h"
#include "idle.h"


unsigned long IdleCounter;	// счетчик бездействия системы (см. IdleProc.S)

void IdleCalc_10ms( unsigned char skipped, Idle_t * idle )
{
// вычисляет степень бейздействия процессора на интервалах
// времени кратных 10 ms
// на входе:
// skipped - количество пропущеных интервалов по 10 ms
// idle - указатель на структуру Idle_t
//
// если значение skiped равно 0, то выполняется инициализация структуры idle
// если значение skiped не 0, выполняет вычисление степени бездействия
// процессора и структура Idle обязательно должна быть инициализирована
//
// На самом деле, степень бездействия имеет смысл вычислять только
// для наиболее длительного циклического интервала программы

	if ( skipped )
	{
		// определяем, сколько тактов потратили на безделье реально
#if defined( IDLE_INTERVALS ) && (IDLE_INTERVALS - 1 > 0)
		const unsigned long int real_idle = IdleCounter - idle->prev;
		idle->prev = IdleCounter;
#else
		const unsigned long int real_idle = IdleCounter;
#endif
		// вычисляем, сколько тактов могли бы потратить на безделье,
		// если бы ничем другим не занимались
		const unsigned long int max_idle_2 = skipped * (Fosc/200ul);

		// вычисляем удвоенный процент безделья
		const unsigned char persent_doble =
			100 * real_idle / max_idle_2;

		idle->cur = persent_doble;
		if ( persent_doble > idle->max ) idle->max = persent_doble;
		if ( persent_doble < idle->min ) idle->min = persent_doble;
	} else {
		// инициализируем структуру idle
		idle->min = 0xFF;
		idle->max = 0;
#if defined( IDLE_INTERVALS ) && (IDLE_INTERVALS > 1)
		idle->prev = IdleCounter;
	}
#else
	}
	IdleCounter = 0;
#endif
} // IdleCalc_10ms


/* End of file */
