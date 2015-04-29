function FeedbackScript
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
    end
end

if(ON_PATH==0)
    % If the robot is on the original path, nothing has to happen.
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
    path=Or_path(P_star:length_path,:);
    P_star=1;
    size_path=size(path);
    length_path=size_path(1);
    % The robot searches for the point of the path on the intersection with
    % a straight line from the actual position to the target point. If such
    % a point exists and the straight line from the actual position to the
    % intersecting point is free of obstacles, the robot will follow that
    % path. If no such point exists of if there's an obstacle in the way,
    % then the robot returns to the aforementiod P*, the closest point of
    % the original path.
    
    deriv1=(Or_path(length_path,2)-resrobotY)/(Or_path(length_path,2)-resrobotY);        % derivative of the straight line from initial position to end
    for i=2:1:length_path-1
        deriv2=(path(i+1,2)-path(i,2))/(path(i+1,1)-path(i,1));                          % derivative of the line between two adjacent points of the path
        intersectX=(path(i,2)-resrobotY+deriv1*resrobotX-path(i,1)*deriv2)/(deriv1-deriv2);
        clearPath=lineofsightB(resrobotX,resrobotY,path(i,1),path(i,2),img2);
        
        % If the program has found an intersection between the two adjacent
        % path points and the path is clear between the actual robot
        % position and the point i and we haven't yet found a point that
        % matched these conditions (P_star is still 1): than...
        if (intersectX<=path(i+1,1))&&(intersectX>=path(i,1))&&(P_star==1)&&(clearPath==1)
            P_star=i;
        end
    end
    old_path=path(P_star:length_path,:); % part of the old path that has to be kept for further tracking
    new_path=[resrobot;old_path]; % add initial position to the path
    csvwrite(filename,new_path);
    
   


    end
end

