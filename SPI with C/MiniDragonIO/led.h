
#include <MC9S12DP256.h>


#define LED_DAT PTM
#define LED_DIR DDRM

const char hex_values[16] = {'1', '2', '3', 'A', '4', '5', '6', 'B', '7', '8', '9', 'C', '*', '0', '#', 'D'};

void init_LED(void);

void writeNumLED(const char num);