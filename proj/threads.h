/* threads.h */

/* потоки и размеры стеков потоков */


/* стек прерываний, должно быть согласовано с Makefile'ом */
/*
#define ISR_Stack_Start	0x100
#define ISR_Stack_Size	0x100

#define ISR_Stack_End	(ISR_Stack_Start + ISR_Stack_Size - 1)
*/

#if __AVR_ARCH__ >= 100 /* __ATXMEGA__ */
#define ISR_Stack_End	0x20FF
#else
#define ISR_Stack_End	0x01FF
#endif


/* потоки (чем меньше номер, тем больше приоритет) */

#define I2C_THREAD	1
#define StackSize1	40

#define RS232_THREAD	2
#define StackSize3	60

#define MAIN_THREAD	3
#define StackSize2	60

#define NumThreads	3


#if 0

#define SEC_THREAD	4
#define	StackSize4	160

#undef NumThreads
#define NumThreads	4


#define LOAD_THREAD	5
#define StackSize5	190

#undef NumThreads
#define NumThreads	5


#if defined( IdleFunc )
#define IDLE_THREAD	6
#define StackSize6	32

#undef NumThreads
#define NumThreads	6
#endif /* IdleFunc */

#endif /* 0 */



/* End of file  threads.h */
