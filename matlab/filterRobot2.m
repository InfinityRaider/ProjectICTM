function [ image ] = filterRobot2( image, robotPos, robotSize )
%Filters the robot out of an image and returns the image
%   image: logical n x m matrix
%   robotPox: vector with three elements: [x (pixels), y (pixels), rotation (degrees)]
%   robotSize: vector with two elements: [xSize, ySize]

imSize=size(image);
xMargin = 4;
yMargin = 4;
angle=robotPos(3);

Cornerx1=(robotPos(1));
Cornery1=(robotPos(2));

Cornerx2=(Cornerx1+robotSize(1)*cos(angle*180/pi));
Cornery2=(Cornerx2+robotSize(1)*sin(angle*180/pi));

Cornerx3=(Cornerx1+robotSize(2)*sin(angle*180/pi));
Cornery3=(Cornerx2+robotSize(2)*cos(angle*180/pi));

Cornerx4=(Cornerx1+sqrt(robotSize(1)^2+robotSize(2)^2)*cos(angle*180/pi));
Cornery4=(Cornerx2+sqrt(robotSize(1)^2+robotSize(2)^2)*sin(angle*180/pi));

offsetX = -xMargin:(robotSize(1) + xMargin);
offsetY = -yMargin:(robotSize(2) + yMargin);

for i=1:1:length(offsetX)
    for j=1:1:length(offsetY)
        itX = offsetX(i);
        itY = offsetY(j);
        u = floor(robotPos(1)+( itX*cos(robotPos(3)*pi/180) + itY*sin(robotPos(3)*pi/180) ));
        if (u<1)
            u=1;
        else if u>imSize(1)
                u=imSize(1);
            end
        end
        
        v = floor(robotPos(2)+( -itX*sin(robotPos(3)*pi/180) + itY*cos(robotPos(3)*pi/180) ));
        if (v<1)
            v=1;
        else if v>imSize(2)
                v=imSize(2);
            end
        end
        
        image(v,u) = 0;
    end
end


end

