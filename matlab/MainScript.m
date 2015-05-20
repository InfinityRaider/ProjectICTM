function MainScript(imagename, filename, buildMap, doPlots)

%close all
%---------
%Constants
%---------
%Image name
Scene=imread(imagename);
if(doPlots)
    figure('Name','Initial photograph')
    imshow(Scene)
end

%Constants to filter robot out of image (T.B.D.)
RobotXcm=13.5;
RobotYcm=12;
%robotXSize = 800;
%robotYSize = 500;

%Object margin
margincm = max(RobotXcm,RobotYcm)/2+6;                                      %margin = half robot thickness + 2 cm

%----------------
%Image processing
%----------------
%Find robot
robotPos = FindCenters(imagename, false, doPlots);

%PixPerCm=sqrt((robotPos(4)-robotPos(1))^2+(robotPos(5)-robotPos(2))^2)/(PatternXcm)
PixPerCm=394/150;       %We measured this
robotXSize = round(RobotXcm*PixPerCm);
robotYSize = round(RobotYcm*PixPerCm);

scale=round(max(size(Scene))/200);

% Determine image to calculate path on
if(buildMap) 
    % Convert to logical map
    img2 = img2logical(Scene);                                        %Convert to logical (0: free space, 1: object)
    if(doPlots)
        figure('Name', 'Logical Map')
        imshow(img2)
    end
    % Filter the robot out of the image
    img2 = filterRobot(img2, robotPos, [robotXSize, robotYSize],robotXSize/2+10,robotYSize/2+10);     %Filter robot from image
    if(doPlots)
        figure('Name','Logical Map after robot filtering')
        imshow(img2)
    end
    % Add safety margins to objects
    margin=ceil(margincm*PixPerCm);
    img2 = addMargin(img2, margin);                                   %Add margin to the objects
    if(doPlots)
        figure('Name','Logical Map after added margins')
        imshow(img2)
    end
    % Rescale image to reduce path calculation time
    img3=imresize(img2,1/scale,'nearest');
    if(doPlots)
        figure('Name', 'Logical Map after rescaling')
        imshow(img3);
    end
    % Save the map to file so we don't have to recalculate it
    imwrite(img3, 'LogicalMap.png');
    PixPerCm2=PixPerCm*1/scale;

    SIZE1=size(Scene);
    SIZE2=size(img3);

    resrobotX=round(robotPos(1)/SIZE1(2)*SIZE2(2));
    resrobotY=round(robotPos(2)/SIZE1(1)*SIZE2(1));
else
    % Read the previously determined map from file
    img2 = imread('LogicalMap.png');
    figure('Name', 'Before filtering')
    imshow(img2)

    PixPerCm2=PixPerCm*1/scale;

    SIZE1=size(Scene);
    SIZE2=size(img2);

    resrobotX=round(robotPos(1)/SIZE1(2)*SIZE2(2));
    resrobotY=round(robotPos(2)/SIZE1(1)*SIZE2(1));
    
    resrobotXSize = round(robotXSize/SIZE1(2)*SIZE2(2));
    resrobotYSize = round(robotYSize/SIZE1(1)*SIZE2(1));
    
    img3 = filterRobot(img2, [resrobotX, resrobotY, robotPos(3)], [resrobotXSize, resrobotYSize], 3,3);
    figure('Name', 'After filtering')
    imshow(img3)
end

%--------------
%Determine path
%--------------
path = Smooth_AStar_Path(img3,[resrobotY,resrobotX]);                                  %Find path and smooth it (n x 2)
csvwrite(filename, path);%Writes path to a csv file

fid = fopen( 'scaling_and_orient.txt', 'wt' );
fprintf( fid, 'Pixels per centimeters =%f \nOrient= %f', PixPerCm2,robotPos(3));
fclose(fid);

end
