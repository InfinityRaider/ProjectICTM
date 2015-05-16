#include "stdio.h"
#include "myfunc.h"
#include "print.h"
#include "uart.h"
#include "srv.h"
#include "colors.h"
#include "string.h"
#include "time.h"
#include "stdlib.h"
#include "math.h"

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
	int num_rows,k, l;
    double orient,delta_orient,rot_speed,t_rot,t_trans;
    double x0,y0,x,y,dx,dy;
    float distance,distance1,lala;
    double PI=3.14159265;
    x0=0;
    y0=0;
    double orient0;
    orient0=0; // starting conditions still have to be properly intialized
    double D = 0.094; /*distance between wheels, has to be measured*/
    char ch;
    const float tol = 1.0e-7;  // 7 significant figures
    float xold, xnew;          // local variables
    int test;

	/*Read in coords, mat[d][0] contains x-coords, mat[d][1]	contains y-coords*/
    int i=0,j=0;
    double mat[100][2];
    double z;

//    UInt32* pathx;
//    UInt32* pathy;

    // Here we should store the path-coordinates

	//
	//    while((line=fgets(buffer,sizeof(buffer),fp))!=NULL)
	//    {
	//
	//        record = strtok(line,","); /*break up string, return first token */
	//        while(record != NULL)
	//        {
	//        printf("record : %s \n",record);  //here you can put the record into the array as per your requirement.
	//        mat[i][j++] = atof(record) ; /*Convert string to double, put in [i,j] then j+1*/
	//        record = strtok(NULL,",");
	//        }
	//     ++i ;
	//     j=0;
	//    }

	initRTC();
	camera_reset(160);
	init_uart1(57600);
	while(1){
		if(getsignal()){
			ch = getch();
			printf("Character on serial %c 1\r\n", ch );
			if(ch == 75)
				{return;}
			else{
				switch (ch) {

				case '1':

					x0=0;
				    y0=0;
				    orient0=0; // starting conditions still have to be properly intialized
				    D = 0.094; /*distance between wheels, measured*/

					/*Read in csv-file, mat[d][0] contains x-coords, mat[d][1]	contains y-coords*/

				    i=0;
				    j=0;
				    mat[0][0]=2;
				    mat[0][1]=13.2;

					num_rows = 1; // to be determined depends on how weread in coords
                    for(k=0;k<=num_rows-1;k++) {
                        x=mat[k][0];
                        y=mat[k][1];
                        test=0;
                        if ((y-13.2)<0.00001 && (y-13.2)>-0.00001){
                            test=1;
                        }
                        z=2.3;
                        printf("tekst");
                        printf("x =%lf, y=%lf  test=%d \n",x,y,test);
                        dx=x-x0;
                        dy=y-y0;
                        distance1=(float)(dx*dx+dy*dy);

                        if (distance1 <= 0.0)
                          return 0.0;             // covers -ve and zero case
                        else
                          {
                            xold = distance1;               // x as first approx
                            xnew = 0.5 * (xold + distance1 / xold); // better approx
                            while (fabs((xold-xnew)/xnew) > tol)
                              {
                                xold = xnew;
                                xnew = 0.5 * (xold + distance1 / xold);
                              }
                          }
                        distance=xnew;
                        printf("dx =%lf, dy=%lf \n",dx,dy);
	                    if(dx !=0){
	                            if(dx>0){
	                                orient=atan(dy/dx)*180.0/PI;
	                            }
	                            else {
	                                orient=atan(dy/dx)*180.0/PI+180.0;//necessary to get angles in left half plane
	                            }
	                    }
	                    else {
	                        if(dy>0){
	                        orient=90;
	                    	}
	                    	else{
	                    		orient=-90;
	                    	}

                        }
                    delta_orient=orient-orient0;//in degrees

                    t_rot=0.012*delta_orient+0.003;
                    t_trans=4.682*distance+0.025;
                    printf("tekst 2 distance: %lf,orient: %lf delta_orient:%lf \n t_rot: %lf t_trans: %lf \n\n",distance,orient,delta_orient,t_rot,t_trans);

                    if(delta_orient>180){
                            if(delta_orient>0){
                                delta_orient=delta_orient-360;
                            }
                            else{
                                delta_orient=delta_orient+360;
                            }
                   			}
                    if (delta_orient>0){
                                sendReceive(203,23,202,20);//turn counterclockwise
                                delay(t_rot);
                                sendReceive(201,0,202,0);//stop
                            }
                            else{
                                sendReceive(201, 23, 204, 20);//turn clockwise
                                delay(t_rot);
                                sendReceive(201,0,202,0);//stop

                            }
                    }
                    sendReceive(201, 23, 202, 20);//drive forward
                    delay(t_trans);
                    sendReceive(201, 0, 202, 0);//stop

                    orient0=orient;
                    x0=x;
                    y0=y;
				break;

				case '5':

					sendReceive(201, 23, 202, 20);
						/* 201: Right motor moves forward
						   202: Left motor moves forward
						   Forward= opposite the antenna
						   */
					break;

				case '6':

					sendReceive(201, 0, 202, 0);
					break;

				case '7':

					sendReceive(203, 22, 204, 20);
						/* 203: Right motor moves backward
							204: Left motor moves backward
							Backward= antenna - side
							*/
					break;

				case '8':

					sendReceive(201, 23, 204, 20);
						/* Rotate: left motor rotates backward; right one forward */
					break;


				case '9':

					sendReceive(203,23,202,20);
						/* Rotate: left motor rotates forward; right one backward */
					break;

				case 'a':
                  printf("Reading path");
                   l = readNumber();
                   printf("l = ",l);
				   followPath(l);
                   break;
				}

			}

		}
	} //end while
} //end  myfunc

int readNumber() {
    int nr = 0;
    char c = getch();
    while(c<=9) {
		printf("read", c);
        nr = c + 10*nr;
        c = getch();
    }
	printf("number", nr);
    return nr;
}

void followPath(int l) {
	int path[2][l];
	int i=0, x, y;
	//Get path
	while(i<l) {
		printf("iteration: ", i);
		x = readNumber();
		printf("x", x);
		y = readNumber();
		printf("y", y);
		path[0][i] = x;
		path[1][i] = y;
		i = i+1;
	}
	//logic to follow path
}

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
	else {
		return 1;
	}
}


    /* use GPIO H14 and H15 for 2-channel wheel encoder inputs -
    H14 (pin 31) is left motor, H15 (pin 32) is right motor */

void delay(double wt){
	int curTime = readRTC();
	int stopTime = curTime+ wt;

	while (readRTC()<stopTime){}

}

