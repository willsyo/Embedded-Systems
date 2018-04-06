#include <hidef.h>      /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */
#include <MC9S12DP256.h>   

extern void near ic2isr(void);
extern void near ic3isr(void);
extern void near tovisr(void);
extern void near oc1ISR(void);

#pragma CODE_SEG __NEAR_SEG NON_BANKED
#pragma CODE_SEG DEFAULT               // Change code section to DEFAULT.
typedef void (*near tIsrFunc)(void);
const tIsrFunc _vect[] @0xFFEA = {
    	ic2isr
};
const tIsrFunc _vect1[] @0xFFE8 = {
    	ic3isr
};
const tIsrFunc _vect2[] @0xFFEC = {
      oc1ISR
};
const tIsrFunc _vect3[] @0xFFDE = {
    	tovisr
};
