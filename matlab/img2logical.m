function [img2] = img2logical(img)
% Algortihm to convert an image into a logical matrix by recognizing
% objects

img_double=im2double(img);
Igray=rgb2gray(img_double);

m=3; n=3;
[~,noise]=wiener2(Igray,[m,n]);
J=wiener2(Igray,[m,n],noise);

img_edge=edge(J,'sobel');
img_edge=imdilate(img_edge,strel('square',2));
img2=imfill(img_edge,'holes');
img2=bwareaopen(img2,500,8);
end




