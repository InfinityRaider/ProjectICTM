function [ image ] = filterRobot( image, robotPos, robotSize )
%Filters the robot out of an image and returns the image
%   image: logical n x m matrix
%   robotPox: vector with three elements: [x (pixels), y (pixels), rotation (degrees)]
%   robotSize: vector with two elements: [xSize, ySize]

imSize=size(image);
xMargin = 10;
yMargin = 10;

offsetX = -xMargin:(robotSize(1) + xMargin);
offsetY = -yMargin:(robotSize(2) + yMargin);

for i=1:1:length(offsetX)
    for j=1:1:length(offsetY)
        itX = offsetX(i);
        itY = offsetY(j);
        u1 = floor(robotPos(1)+( itX*cos(robotPos(3)*pi/180) + itY*sin(robotPos(3)*pi/180) ));
        u2 = ceil(robotPos(1)+( itX*cos(robotPos(3)*pi/180) + itY*sin(robotPos(3)*pi/180) ));
        if (u1<1)
            u1=1;
        else if u1>imSize(2)
                u1=imSize(2);
            end
        end
         if (u2<1)
            u2=1;
        else if u2>imSize(2)
                u2=imSize(2);
            end
        end
        
        v1 = floor(robotPos(2)+( -itX*sin(robotPos(3)*pi/180) + itY*cos(robotPos(3)*pi/180) ));
        v2 = ceil(robotPos(2)+( -itX*sin(robotPos(3)*pi/180) + itY*cos(robotPos(3)*pi/180) ));
        if (v1<1)
            v1=1;
        else if v1>imSize(1)
                v1=imSize(1);
            end
        end
         if (v2<1)
            v2=1;
        else if v2>imSize(1)
                v2=imSize(1);
            end
        end
        
        image(v1,u1) = 0;
        image(v1,u2) = 0;
        image(v2,u1) = 0;
        image(v2,u2) = 0;
    end
end


end

