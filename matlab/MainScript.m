function MainScript(imagename, filename)
close all
%---------
%Constants
%---------

%Image name
Scene=imread(imagename);
%Object margin
margin = 10;

%Constants to filter robot out of image (T.B.D.)
ArrowXcm=17;
ArrowYcm=13;
RobotXcm=20;
RobotYcm=16;
%robotXSize = 800;
%robotYSize = 500;
robotImg =imread('pattern.png');



%----------------
%Image processing
%----------------
% img=imread(Scene);                                              %Read image
% img=imresize(Scene,0.1);                                        %Resize image
% figure(5)
% imshow(img)
robotPos = findRobot(Scene,robotImg);                             %Find robot
robotPos = round(robotPos);
hold on
plot(robotPos(1),robotPos(2),'*')
plot(robotPos(4),robotPos(5),'R*')

PixPerCm=sqrt((robotPos(4)-robotPos(1))^2+(robotPos(5)-robotPos(2))^2)/ArrowXcm;
robotXSize = round(RobotXcm*PixPerCm);
robotYSize = round(RobotYcm*PixPerCm);



img2 = img2logical(Scene);                                        %Convert to logical (0: free space, 1: object)
figure(5)
imshow(img2)
hold on
plot(robotPos(1),robotPos(2),'*')
img2 = filterRobot(img2, robotPos, [robotXSize, robotYSize]);     %Filter robot from image
figure(6)


imshow(img2)
img2 = addMargin(img2, margin);                                   %Add margin to the objects
figure(3)
imshow(img2)
size(img2)
scale=round(max(size(img2))/200);
img3=imresize(img2,1/scale,'nearest');
figure(4)
imshow(img3);

SIZE1=size(img2);
SIZE2=size(img3);

resrobotX=round(robotPos(1)/SIZE1(2)*SIZE2(2));
resrobotY=round(robotPos(2)/SIZE1(1)*SIZE2(1));



%--------------
%Determine path
%--------------
figure
path = Smooth_AStar_Path(img3,[resrobotY,resrobotX]);                                  %Find path and smooth it (n x 2)
csvwrite(filename, path);                                                 %Writes path to a csv file

end
