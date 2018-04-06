
#include <MC9S12DP256.h>


#define SWITCH_DAT PTT
#define SWITCH_DIR DDRT

void init_Switch(void);

char *readSwitch(void);