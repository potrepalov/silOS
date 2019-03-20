/* config.h */

/* константы проекта: частота тактирования, названия входов/выходов и т.п. */


#ifndef CONFIG_H_INCLUDED
#define CONFIG_H_INCLUDED


#define Fosc		14745600
#define Ftimer		Fosc	/* частота тактирования таймера тиков */
#define TicksPerSecond	4000	/* кол-во тиков в секунду */

#include "registers.h"
#include "os-config.h"



#define NOINIT     	__attribute__ ((section(".noinit")))
#define NORETURN   	__attribute__ ((noreturn))
#define USED       	__attribute__ ((used))
#define OS_INIT_SEC	__attribute__ ((section(".init5")))
#define NAKED      	__attribute__ ((naked))
#define OS_TASK    	__attribute__ ((OS_task))


#endif /* CONFIG_H_INCLUDED */


/* End of file  config.h */
