#include "myfunc.h"
#include "print.h"
#include "srv.h"
#include "colors.h"


#define bin 1



int run();


void myfunc(){
	unsigned char ch;
	int i;
	int a;
	int s=1;
	unsigned char ff;
	//init_uart1(57600); 
	if (!pwm1_init){
		initPWM();
		pwm1_init=1;
		pwm1_mode=PWM_PWM;
		

	}
	do{
		printf("1 - set PWM to 30,30\r\n");
		printf("2 - set PWM to 10,10\r\n");
		printf("s - stop\r\n");
				
		ch=getch();
		switch(ch){
		case '1':
			setPWM(30,30);	
			break;
		case '2':
			setPWM(10,10);
			break;
		case 's':
			s=0;
			break;
		}
	}while(s);
		
}

int run(){
	unsigned char ch;
	if(getsignal()){
		ch=getch();
		
		//printf("ch este %d\r\n", 10);
		
		switch(ch){
		case 's':
			return 0;
			break;
		}
	}
	else return 1;
}
