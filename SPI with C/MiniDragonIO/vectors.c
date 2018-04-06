#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */
#include <MC9S12DP256.h> 

extern void near rtiISR(void);
#pragma CODE_SEG __NEAR_SEG NON_BANKED
#pragma CODE_SEG DEFAULT // Change code section to
                         //DEFAULT.
typedef void (*near tIsrFunc)(void);
const tIsrFunc _vect[] @0xFFF0 = {
  rtiISR
};