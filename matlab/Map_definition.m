clc;clear all;

%Size of map
Mapsize=50;
Topmap = zeros(Mapsize);

%Obstacle corners(upper left)/width(square obstacles)
Obstaclesx=[5,25,10,40,32,40,4];
Obstaclesy=[3,25,40,10,37,35,4];
Obstaclesw=[3,5,6,8,5,6,1];


%Add obstacles
for i=1:1:length(Obstaclesx)
    for j=0:1:Obstaclesw(i)-1
        for k=0:1:Obstaclesw(i)-1
        Topmap(Obstaclesy(i)+j,Obstaclesx(i)+k)=1;
        end
    end
end

Smooth_AStar_Path(Topmap,[17,13]);