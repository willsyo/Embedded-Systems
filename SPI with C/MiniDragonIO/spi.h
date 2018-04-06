#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */
#include <MC9S12DP256.h>   

char spi_in;

void initSPI();

char getcSPI();

void getsSPI(char *ptr, int count);

void putcSPI(char cx);

void putsSPI(char *ptr);
