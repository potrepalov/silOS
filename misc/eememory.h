/* share/avr/silOS/misc/eememory.h */

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


#ifndef OS_OS_EEMEMORY_H_INCLUDED
#define OS_OS_EEMEMORY_H_INCLUDED


#include "../os.h"


#if defined( EE_Semaphore )


unsigned char ReadEE( unsigned short int addr );
void WriteEE( unsigned short int addr, unsigned char byte );
unsigned char isEEfree( void );


typedef struct EE_Param_t_TAG {
	unsigned char flag;
	unsigned short v1, v2;
} EE_Param_t;

unsigned short ee_ReadParam( unsigned short addr );
unsigned char ee_WriteParam( unsigned short addr, unsigned short val );


#define isEEfree( )  (0 != OS_Semaphores[EE_Semaphore-1])


#else /* EE_Semaphore */


#define ReadEE( ... )	Semaphore_Up( EE_Semaphore )
#define WriteEE( ... )	Semaphore_Up( EE_Semaphore )
#define isEEfree( ... )	Semaphore_Up( EE_Semaphore )


#endif /* EE_Semaphore */


#endif /* OS_OS_EEMEMORY_H_INCLUDED */


/* End of file  eememory.h */
