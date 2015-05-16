function MainScript(imagename, filename)
close all
%---------
%Constants
%---------
%Image name
Scene=imread(imagename);


%Constants to filter robot out of image (T.B.D.)
PatternXcm=13;
PatternYcm=10;
RobotXcm=13.5;
RobotYcm=11;
%robotXSize = 800;
%robotYSize = 500;

%Object margin
margincm = max(RobotXcm,RobotYcm)/2+1;                                      %margin = half robot thickness + 2 cm

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
plot(robotPos(6),robotPos(7),'Bo')

PixPerCm=sqrt((robotPos(4)-robotPos(1))^2+(robotPos(5)-robotPos(2))^2)/(PatternXcm);
robotXSize = round(RobotXcm*PixPerCm)
robotYSize = round(RobotYcm*PixPerCm)




img2 = img2logical(Scene);                                        %Convert to logical (0: free space, 1: object)
figure(3)
imshow(img2)
hold on
plot(robotPos(1),robotPos(2),'*')
img2 = filterRobot(img2, robotPos, [robotXSize, robotYSize],robotXSize/2,robotYSize/2);     %Filter robot from image
figure(4)
imshow(img2)

margin=ceil(margincm*PixPerCm);
img2 = addMargin(img2, margin);                                   %Add margin to the objects
figure(5)
imshow(img2)
size(img2)
scale=round(max(size(img2))/200);
img3=imresize(img2,1/scale,'nearest');
figure(6)
imshow(img3);

SIZE1=size(img2);
SIZE2=size(img3);

resrobotX=round(robotPos(6)/SIZE1(2)*SIZE2(2));
resrobotY=round(robotPos(7)/SIZE1(1)*SIZE2(1));

PixPerCm2=PixPerCm*1/scale

%--------------
%Determine path
%--------------
figure
path = Smooth_AStar_Path(img3,[resrobotY,resrobotX]);                                  %Find path and smooth it (n x 2)
csvwrite(filename, path);%Writes path to a csv file

fid = fopen( 'scaling_and_orient.txt', 'wt' );
fprintf( fid, 'Pixels per centimeters =%f \nOrient= %f', PixPerCm2,robotPos(3));
fclose(fid)

end
