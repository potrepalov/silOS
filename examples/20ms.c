/* share/avr/silOS/examples/20ms.c
 Copyright Potrepalov I.S.  potrepalov@list.ru

Пример вызова функции func() примерно через каждые 40 тиков таймера ОС, и точно
один раз каждые 40 тиков.  Т.е. между вызовами функции func() проходит примерно
40 тиков таймера операционной системы (но не меньше) и за 40000 тиков будет
1000 или 999 вызовов, а за 4000000 тиков будет 100000 или 99999 вызовов.

Функция func() должна выполняться намного быстрее, чем за 40 тиков таймера.

*/


#include <avr/io.h>
#include <avr/interrupt.h>

#include "os/os.h"

unsigned short Counter05ms;

THREAD( ticks, var ) {
	unsigned char next = (unsigned char) Counter05ms;

	do {

		func();

		{
			unsigned char tk;
			next += 40;
			cli();
			tk = next - (unsigned char) Counter05ms;
LOOP:				tk = Sleep( tk );
				if ( !tk ) goto END_LOOP;
				cli(); 
				tk = next - (unsigned char) Counter05ms;
				if ( tk && (tk < 40) ) goto LOOP;
				sei();
END_LOOP:			;
		}
	} while (1);
} // ticks


// End of file
