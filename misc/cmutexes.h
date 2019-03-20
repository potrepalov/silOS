/* share/avr/silOS/misc/cmutexes.h */
/* Copyright Potrepalov I.S.  potrepalov@list.ru */

/*
 "Вложенные" мьютексы (мьютексы со счетчиками)

 Один и тот же мьютекс функцией CMutex_Get можно захватывать несколько раз,
 такой мьютекс будет освобождён после соответствующего количества вызовов
 функции CMutex_Release

 Нельзя смешивать функции Mutex_... и CMutex_... для работы с одним и тем же
 мьютексом

 Если определён макрос NumCMutexes (количество мьютексов со счетчиками),
 то только мьютексы с номерами меньше чем NumCMutexes могут использоваться
 как мьютексы со счетчиками
*/


#include "../os.h"


#if OS_VERSION > 100

#define CMutex_Owner		Mutex_Owner
#define CMutex_Get		Mutex_Get
#define CMutex_GetWithTimeout	Mutex_GetWithTimeout
#define CMutex_TryGet		Mutex_TryGet
#define CMutex_Release		Mutex_Release

#else /* OS_VERSION */


#ifndef NumCMutexes
#define NumCMutexes	NumMutexes
#endif

#if NumCMutexes > NumMutexes
#error NumCMutexes must be less than or equal to NumMutexes
#endif


#if NumCMutexes


#define CMutex_Owner	Mutex_Owner

RegType CMutex_Get( Mutex mut );
RegType CMutex_GetWithTimeout( Mutex mut, SleepTime ticks );
RegType CMutex_TryGet( Mutex mut );
void CMutex_Release( Mutex mut );


#endif /* NumCMutexes */


#endif /* OS_VERSION */


/* End of file  cmutexes.h */
