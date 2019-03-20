/* share/avr/silOS/misc/ee-param.c */

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
 работа с параметрами в памяти EEPROM

 Атомарность работы с одним параметром должна обеспечиваться
 внешними средствами.

 Каждый параметр состоит из двух байтов.  В памяти EEPROM параметр
 занимает пять байтов.
*/

/*
 Внутреняя организация.

 Каждый параметр из двух байтов занимает в памяти EEPROM пять байтов:
 флаг верной копии,
 младший байт копии 1, старший байт копии 1,
 младший байт копии 2, старший байт копии 2

 Если флаг верной копии 0xFF, значит верна копия 1;
 если флаг не 0xFF, значит верна копия 2.

 При считывании возвращаем верную копию.  При записи пишем в сомнительную
 копию и выставляем флаг так, чтобы после записи эта копия стала верной.
*/


#include <avr/io.h>
#include "../os.h"
#include "eememory.h"
#include "share/asm-math.h"


#if defined( EE_Semaphore )


unsigned short
ee_ReadParam( unsigned short addr )
{
	// читает параметр по адресу addr из памяти EEPROM
	// возвращает прочитаное значение
	// определяем адрес верой копии
	if ( 0xFF != ReadEE(addr) ) addr += 2;
	addr += 1;
	return make_word( ReadEE(addr+1), ReadEE(addr) );
} // ee_ReadParam


unsigned char
ee_WriteParam( unsigned short addr, unsigned short val )
{
	// записывает значение val в параметр по адресу addr в память EEPROM
	// возвращает не 0, если запись прошла успешно
	unsigned char c = ReadEE( addr );
	unsigned short wa, ra, old;
	if ( 0xFF != c )
	{
		// верна копия 2; пишем на место копии 1
		wa = addr+1;
		ra = addr+3;
		c = 0xFF;
	} else {
		// верна копия 1; пишем на место копии 2
		wa = addr+3;
		ra = addr+1;
		c = 0;
	}

	old = make_word( ReadEE(ra+1), ReadEE(ra) );
	if ( old != val )
	{
		WriteEE( wa, val );		// сначала пишем младший байт
		WriteEE( wa+1, val >> 8 );	// пишем старший байт
		// выполняем контрольное чтение
		old = make_word( ReadEE(wa+1), ReadEE(wa) );
		if ( old != val ) return 0;	// записать не смогли
		WriteEE( addr, c );		// пишем флаг
	}
	return 1;
} // ee_WriteParam


#endif /* EE_Semaphore */


/* End of file  ee-param.c */
