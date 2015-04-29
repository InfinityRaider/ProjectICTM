
#include "myfunc.h"
#include "print.h"
#include "uart.h"
#include "srv.h"
#include "colors.h"
#include "string.h"
#include "time.h"

/* Motor globals */
int lspeed, rspeed, lcount, rcount, lspeed2, rspeed2, base_speed, base_speed2, err1;
int pwm1_mode, pwm2_mode, pwm1_init, pwm2_init, xwd_init;
int encoder_flag;



//unsigned char str={0 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0 1 0 0 0 1 1 1 0};
unsigned char sLch, sRch;

float ref_Ang = WIDTH / 2; // reference for lateral control - in the middle of the picture
float ang = WIDTH / 2; // measured position on the X axis

int V_l = 0, V_r = 0;
int noBlobs;

void myfunc() {
	int i;
	unsigned char ch;
	unsigned char wt;
	unsigned int curTime;			
	unsigned int stopTime;
	initRTC();
	camera_reset(160);
	init_uart1(57600);
	while(1){
		if(getsignal()){
			ch = getch();
			printf("Character on serial %c 1\r\n", ch );
			if(ch == 75)
				return;
			else{				
				switch (ch) {
				
				case'4':
				
					/*if(getsignal()){
					wt = getch();
					printf("read wait time of", wt );
					if(ch == 75)
					return;
					else{	*/			
					
					
					wt =500;
					int wtn = wt - '0'; /* this converts wt which is a character to a number*/
					
					
					curTime = readRTC();					
					stopTime = curTime+ wt;
					
					while (readRTC()<stopTime){
					sendReceive(201, 20, 202, 20);
					}
					
					sendReceive(201, 0, 202, 0);
					
				/*}		*/		
				
				break;			
				
				case '5':
					sendReceive(201, 20, 202, 20); 
						/* 201: Left motor moves forward
						   202: Right motor moves forward
						   Forward= opposite the antenna
						   */
					break;
				case '6':
					
					sendReceive(201, 0, 202, 0);
					break;
				case '7':
					
					sendReceive(203, 25, 204, 25);
						/* 203: Left motor moves backward
							204: Right motor moves backward
							Backward= antenna - side
							*/
					break;
				case '8':
					
					sendReceive(201, 20, 204, 20);
					
					break;	

				}

			}

		}
	} //end while
} //end  myfunc



void sendReceive(unsigned char directionL, int ref_speedL, unsigned char directionR, int ref_speedR ){

	int i=0;
	int wait=0;
	unsigned char header_com=210; 

	int time=readRTC();
	uart1SendChar(header_com);
	uart1SendChar(directionL);
	uart1SendChar((unsigned char)ref_speedL);

	//printf("I send1  %c %c \r\n", ref_speedL, directionL);

	while(!uart1Signal()){
		sLch = 0;
		//printf(" i'm busy ");
		wait++;
		if (wait>1000) 
		{break;	
		//goto et;
		}
	}
	if(uart1Signal()){
		sLch = uart1GetCh();

		if (i==0)
		{//printf("I receive left speed: \r\n");
			//printf(" %d %d ",time,  sLch*2);
			delayMS(2);
		}
	}

	uart1SendChar(header_com);
	uart1SendChar(directionR);
	uart1SendChar(( unsigned char) ref_speedR);

	//printf("I send2 %c %c \r\n", ref_speedR, directionR);

	wait=0;
	while(!uart1Signal()){
		sRch = 0;
		//printf(" i'm busy right");
		wait++;
		if (wait>1000) 
		{break;	
		//goto et;
		}
	}
	if(uart1Signal()){
		sRch = uart1GetCh();

		if (i==0)
		{//printf("I receive right speed: \r\n");
			//printf("  %d  \r\n",  sRch*2);
			delayMS(2);
		}
	}

}


int getUserInput(){
	char ch;
	if(getsignal()){
		ch=getch();
		if(ch==75){ // stops for "p"
			//setPWM(0,0);
			return 0;
		}
		if(ch==73)	// send image for "I"
		{
			send_frame();
			return 1;
		}	
	}
	return 1;
}
/* use GPIO H14 and H15 for 2-channel wheel encoder inputs -
    H14 (pin 31) is left motor, H15 (pin 32) is right motor */
