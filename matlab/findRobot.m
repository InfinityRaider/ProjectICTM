function [robotPos] = findRobot (image, robot)

figBox=robot;
figBox=rgb2gray(figBox);
figScene=image;
figScene=rgb2gray(figScene);

[tform,ip1,ip2,tmatrix]=Robot_Recognition(figBox,figScene);

[X0,Y0]=transformPointsForward(tform,0,0);
[X1,Y1]=transformPointsForward(tform,1,0);
SIZE=size(figBox);
[X2,Y2]=transformPointsForward(tform,SIZE(2),0);                  %Transform center of the arrow
[Xc,Yc]=transformPointsForward(tform,SIZE(2)/2,SIZE(1)/2);
dx=X1-X0;
dy=Y0-Y1;

if(dx<0)
angle=mod(180+atand((Y0-Y1)/(X1-X0)),360);
else
angle=mod(atand((Y0-Y1)/(X1-X0)),360);
end
angle;
translation=[X0,Y0];
robotPos = [X0, Y0, angle, X2, Y2,Xc,Yc]
hold on 
plot(X0,Y0,'r*')


% figBox=robot;
% figBox=rgb2gray(figBox);
% figScene=image;
% figScene=rgb2gray(figScene);
% figure(6)
% imshow(figScene)
% 
% [tform,ip1,ip2,tmatrix]=Robot_Recognition(figBox,figScene);
% % I think that, in theory, the orientation of the robot could be found by
% % using the OutputLimits-function performed on tform, but I'm not sure.
% 
% %I've adapted the functions so that the transformation matrix can be
% %returned, however due to scaling it is not possible to use this directly
% %to find the angle
% % A1 = asin(tmatrix(1,2))*180/pi;
% % A2 = acos(tmatrix(1,1))*180/pi;
% % tmatrix
% % 
% % if(A2<0)
% %     angle=180-A1
% % else
% %     angle=A2
% % end
% 
% 
% %By applying the transformation to a vector along the x-axis starting in
% %the origin we can deduce the translation and the rotation
% %BEWARE I think matlab uses the y-awis pointing downwards with the
% %transformations
% 
% [X0,Y0]=transformPointsForward(tform,0,0);
% [X1,Y1]=transformPointsForward(tform,1,0);
% dx=X1-X0;
% dy=Y0-Y1;
% 
% if(dx<0)
% angle=mod(180+atand((Y0-Y1)/(X1-X0)),360);
% else
% angle=mod(atand((Y0-Y1)/(X1-X0)),360);
% end
% angle;
% translation=[X0,Y0];
% robotPos = [X0, Y0, angle]
% end