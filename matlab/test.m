theta = 320;
tform = affine2d([cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1]);
[X0,Y0]=transformPointsForward(tform,0,0)
[X1,Y1]=transformPointsForward(tform,1,0)
dx=X1-X0;
dy=Y0-Y1;

if(dx<0)
angle=mod(180+atand((Y0-Y1)/(X1-X0)),360);
else
angle=mod(atand((Y0-Y1)/(X1-X0)),360);
end
angle