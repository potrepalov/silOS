/* share/avr/silos/proj/main.c */


/* файл-заготовка */


#include <avr/io.h>
#include <avr/interrupt.h>
#include "silOS/os.h"


// инициализацию железа желательно выполнить как можно раньше
__attribute__ ((used))
__attribute__ ((section(".init2")))
__attribute__ ((naked))
static void Ports_Init( void );



static void
Ports_Init( void )
{
	// инициализация портов ввода/выводи и некоторых аппаратных модулей
	// микроконтроллера (например, интерфейса к внешней памяти);
	// выполняется ещё до инициализации статических
	// и глобальных переменных

	return;
} // Ports_Init


static void
OS_Timer_Init( void )
{
	// инициализация аппаратного таймера, используемого для генерации
	// тиков системного таймера операционной системы

#if __AVR_ARCH__ >= 100 /* __ATXMEGA__ */

	// запускает таймер операционной системы (TCC0)
	// режим работы таймера: Normal
	// предделитель: 1
	// предел счёта: Fosc/TicksPerSecond - 1
	// разрешаем прерывания по переполнению таймера

	TCC0.CTRLB = TC_WGMODE_NORMAL_gc;
	TCC0.CTRLC = 0;
	TCC0.CTRLD = TC_EVACT_OFF_gc | TC_EVSEL_OFF_gc;
	TCC0.CTRLE = 0;
	TCC0.INTCTRLA = TC_ERRINTLVL_OFF_gc | TC_OVFINTLVL_LO_gc;
	TCC0.INTCTRLB = TC_CCDINTLVL_OFF_gc
		| TC_CCCINTLVL_OFF_gc
		| TC_CCBINTLVL_OFF_gc
		| TC_CCAINTLVL_OFF_gc;
	TCC0.INTFLAGS = TC0_OVFIF_bm;

	TCC0.PER = (((unsigned long)Fosc) / TicksPerSecond) - 1;

	TCC0.CTRLA = TC_CLKSEL_DIV1_gc;

#else /* !__ATXMEGA__ */

	// здесь используем таймер 0

	// Timer0: OS timer
	// Mode: CTC (Clear Timer on Compare)
	// Prescaler: 256 (Fosc/256)
	OCR0 = ((unsigned long)Fosc)/(256ul*TicksPerSecond) - 1;
	TCCR0 = (1 << WGM01) | (1 << CS02) | (1 << CS01) | (0 << CS00);
	TIMSK = (1 << OCIE0);
	TIFR = (1 << OCF0);

#endif /* !__ATXMEGA__ */

} // OS_Timer_Init


NORETURN int
main( void )
{
	OS_Timer_Init();
	OS_Init();
	sei();

	while (1)
	{
		Sleep(10);
	}
} // main


/* End of file  main.c */