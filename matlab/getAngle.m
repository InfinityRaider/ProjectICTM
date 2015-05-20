function angle = getAngle(imagename)
%GETANGLE Summary of this function goes here
%   Detailed explanation goes here
robotPos = FindCenters(imagename, false, false);
angle = robotPos(3);

end

