/* share/avr/silOS/misc/ee-init.c */

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


#include "../os.h"


#if EE_Semaphore

INIT_SEMAPHORE( EE_Semaphore, 1 );

#endif /* EE_Semaphore */


/* End of file  ee-init.c */
