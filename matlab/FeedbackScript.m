function[]=FeedbackScript()
close all
%---------
%Constants
%---------

%Path filename
filename = 'path.csv';

%Image name
Scene=imread('foto.jpg');
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
resrobot=[resrobotX,resrobotY];

% End of the image processing
% Compare the robot position to the desired path
Or_path=csvread('path.csv');
size_path=size(Or_path);
length_path=size_path(1);
ON_PATH=0;
for i=1:1:length_path
    if (Or_path(i,1)==resrobotX)&&(Or_path(i,2)==resrobotY)
    ON_PATH=1;
    Point_on_path=i;
    end
end

new_path=zeros(length_path,2);
if(ON_PATH==1)
     % If the robot is on the original path, nothing has to happen.
     new_path=Or_path(Point_on_path:length_path,:);
     
else
    % Else, perform the following code.
    
    % Find the point P* closest to the robot. Later, we will send the robot
    % back to a point of the path which is between P* and the target
     
    distance=inf;
    P_star=0;
    for i=1:1:length_path
        if distance >= sqrt((resrobotX-Or_path(i,1))^2 + (resrobotY-Or_path(i,2))^2)
        distance=sqrt((resrobotX-Or_path(i,1))^2 + (resrobotY-Or_path(i,2))^2);
        P_star=i;
        end
    end
    % Only part of the path after closest point is kept.
    old_path=Or_path(P_star:length_path,:);
    size_path=size(old_path);
    length_path=size_path(1);
   
    % We will send the robot to the next point in the path, if there's no
    % obstacle in between robot position and next point. Otherwise, go back
    % to the closest point in the path (it's assumed the robot comes from
    % this point, so we won't check if there is an obstacle between the
    % robot position and the closest point. Also, if the robot diverges
    % from the path and into the margin zone around an obstacle, it will
    % always return to the point closest to the path for safety reasons
    % (which is also why we do not check for obstacles between robot
    % position and closest point)
    
    if(length_path<2)
        new_path=[resrobotX,resrobotY;old_path(1,1),old_path(1,2)];
        % This case is to make sure old_path(2,:) exists in next statement
    else if(lineofsightB(resrobotX,resrobotY,old_path(2,1),old_path(2,2),img2))
        new_path=old_path(2:length_path,:);
        new_path=[resrobot;old_path]; % add initial position to the path
        else
        new_path=[resrobot;old_path];
        end
    end   
end
csvwrite(filename,new_path);
end

