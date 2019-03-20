/* os-config.h */


#ifndef OS_CONFIG_H_INCLUDED
#define OS_CONFIG_H_INCLUDED


#define BIG_SLEEP		0

#define NO_PREPARE_IN_ISR	0
#define NO_KILL_IN_ISR		0
#define NO_RELEASE_IN_ISR	0

#define IDLE_INTERVALS	2
//#define IdleFunc


#include "threads.h"
#include "mutexes.h"
#include "signals.h"
#include "events.h"
#include "semaphores.h"
#include "timers.h"


#define NO_OS_INIT	0
#define NO_STOP		0
#define NO_THREAD_KILL	0


#if defined( __ASSEMBLER__ )
#else /* __ASSEMBLER__ */


#include <stdint.h>

typedef uint16_t OS_Timer_t;
extern volatile unsigned short TicksCounter;

typedef uint8_t	RegType;
#define RegType_MAX	UINT8_MAX


#endif /* __ASSEMBLER__ */


#endif /* OS_CONFIG_H_INCLUDED */


/* wordset:os */

/* End of file  os-config.h */
