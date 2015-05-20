function [ canSee ] = hasLineOfSight(A,B,map)
canSee = true;
deltaX = B(1) - A(1);
deltaY = B(2) - A(2);
direction = max(abs(deltaX),abs(deltaY));
iterator = 1;
object = 1;
%Use the direction with the largest resolution, difference might be
%negative, so we use the absolute value
if(direction == abs(deltaX))
    xCoords = min(A(1),B(1)):1:max(A(1),B(1));
    while(iterator<=size(xCoords,2))
        xCoord = xCoords(iterator);
        yCoord1 = floor(A(2) + (deltaY/deltaX)*(xCoord-A(1)));
        yCoord2 = ceil(A(2) + (deltaY/deltaX)*(xCoord-A(1)));
        if(map(yCoord1, xCoord) == object || map(yCoord2, xCoord) == object)
        	canSee = false;
            	 break;
        end
        iterator = iterator+1;
    end
else
    yCoords = min(A(2),B(2)):1:max(A(2),B(2));
    while(iterator<=size(yCoords,2))
        yCoord = yCoords(iterator);
        xCoord1 = floor(A(1) + (deltaX/deltaY)*(yCoord-A(2)));
        xCoord2 = ceil(A(1) + (deltaX/deltaY)*(yCoord-A(2)));
        if(map(yCoord, xCoord1)== object || map(yCoord, xCoord2)== object)
        	canSee = false;
        	break;
        end
        iterator = iterator+1;
    end
end
end

