
#include <hidef.h>      /* common defines and macros */
#include <math.h>
#include "derivative.h"      /* derivative-specific definitions */

#include "motor.h"

void init_motor(){

  DDRB = 0x03;    //PORTB as outputs  
  PORTB = 0x01;   // Enables the motor to spin clockwise
    
  PWMPRCLK = 1; 	
	PWMCLK = 0;   	//ClockA, channel 0
	PWMPOL = 1;   	//high and low polarity
	PWMCAE = 0;   	//Left aligned
	PWMCTL = 0x0C;	//8-bit channel and PWM freeze during wait                                        
	PWMPER0 = 132;	//PWM_Period Freq
  PWMDTY0 = 0;    //Duty Cycle at 0 to begin
  PWME = 0x01; 	  //Enable PWM0
  PWMCNT0 = 0x00; //start the PWMCount with 0 value
}

void set_motor_speed(int speed){

  PWMDTY0 = ((speed + 1)*12); // Adjust duty cycle  
}

void change_motor_direction(int dir){

  if (dir == 1){ 
    PORTB = 0x01; //turn on for clockwise direction
  } else {
    PORTB =0x02;  //turn on for CCW
  }
}

void stop_motor(){

  PORTB = 0x00; //stop the motor
}