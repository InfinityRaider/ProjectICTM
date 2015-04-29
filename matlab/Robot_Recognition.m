function [tform, rob_Inpoints, map_Inpoints,tmatrix  ] = Robot_Recognition( im_robot,im_map )
%ROBOT_RECOGNITION : search for an object in an image
% Enter im_robot, the image of the robot which we need to search for in
% the camera input image im_map. Make sure both images are in grayscale!
% The function gives back the position of the feature
% points of the robot that were found in the image. 
% More info:http://nl.mathworks.com/help/vision/examples/object-detection-in-a-cluttered-scene-using-point-feature-matching.html

% Detect feature points in both images
rob_points=detectSURFFeatures(im_robot)
map_points=detectSURFFeatures(im_map)

figure;
hold on;
imshow(im_robot);
plot(selectStrongest(rob_points,100));
hold off;

figure;
hold on;
imshow(im_map);
plot(selectStrongest(map_points,100));
hold off;

[rob_feat,rob_points]=extractFeatures(im_robot,rob_points);
[map_feat,map_points]=extractFeatures(im_map,map_points);

pair_feat=matchFeatures(rob_feat,map_feat);
rob_matchPoints=rob_points(pair_feat(:,1),:);
map_matchPoints=map_points(pair_feat(:,2),:);

[tform, rob_Inpoints, map_Inpoints,~,tmatrix]=estimateGeometricTransformB(rob_matchPoints,map_matchPoints,'affine');



end

