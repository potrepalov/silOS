/* share/avr/silOS/misc/cmutexes.c */

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
 "Вложенные" мьютексы (мьютексы со счётчиками)

 Сейчас мьютексы со счётчиками реализованы в ядре ОС.  Здесь они оставлены
 только для примера.

 Один и тот же мьютекс функцией CMutex_Get можно захватывать несколько раз,
 такой мьютекс будет освобождён после соответствующего количества вызовов
 функции CMutex_Release

 Нельзя смешивать функции Mutex_... и CMutex_... для работы с одним и тем же
 мьютексом

 Если определён макрос NumCMutexes (количество мьютексов со счетчиками),
 то только мьютексы с номерами меньше чем NumCMutexes могут использоваться
 как мьютексы со счетчиками
*/


#if OS_VERSION <= 100


#include "cmutexes.h"


#if NumCMutexes


#define CMutex_Owner	Mutex_Owner


static unsigned char CMutexes[NumCMutexes];

RegType
CMutex_Get( Mutex mut )
{
	RegType r = Mutex_Get( mut );
	if ( 1 & r )
	{
		// успешный захват мьютекса (первичный или повторный)
		// учитываем, сколько раз захватили мьютекс
		++CMutexes[mut-1];
	}
	return r;
} // CMutex_Get


RegType
CMutex_GetWithTimeout( Mutex mut, SleepTime ticks )
{
	RegType r = Mutex_GetWithTimeout( mut, ticks );
	if ( 1 & r )
	{
		// успешный захват мьютекса (первичный или повторный)
		// учитываем, сколько раз захватили мьютекс
		++CMutexes[mut-1];
	}
	return r;
} // CMutex_GetWithTimeout


RegType
CMutex_TryGet( Mutex mut )
{
	RegType r = Mutex_TryGet( mut );
	if ( 1 & r )
	{
		// успешный захват мьютекса (первичный или повторный)
		// учитываем, сколько раз захватили мьютекс
		++CMutexes[mut-1];
	}
	return r;
} // CMutex_TryGet


void
CMutex_Release( Mutex mut )
{
	if ( (! CMutexes[mut-1]) || (! --CMutexes[mut-1]) )
		Mutex_Release( mut );
} // CMutex_Release


#endif /* NumCMutexes */


#endif /* OS_VERSION */


/* End of file  cmutexes.c */
