/* share/avr/silOS/idle/idle.h */

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

/* Средство замера загруженности системы */


typedef struct tagIdle {
	unsigned char cur;	// текущее бездействие в полупроцентах
	unsigned char min;	// минимальное бездействие в полупроцентах
	unsigned char max;	// максимальное бездействие в полупроцентах
#if defined( IDLE_INTERVALS ) && (IDLE_INTERVALS - 1 > 0)
	unsigned long prev;	// предыдущее состояние переменной IdleCounter
#endif
} Idle_t;

void IdleCalc_10ms( unsigned char skiped, Idle_t * idle );
// вычисляет степень бейздействия процессора на интервалах
// времени кратных 10 ms
// на входе:
// skiped - количество пропущеных интервалов по 10 ms
// idle - указатель на структуру Idle
//
// если значение skiped равно 0, то выполняется инициализация структуры Idle
// если значение skiped не 0, выполняет вычисление степени бездействия
// процессора и структура Idle обязательно уже должна быть инициализирована


/* End of file  idle.h */
