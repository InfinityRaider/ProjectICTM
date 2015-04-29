function [img2] = img2logical(img)
% Algortihm to convert an image into a logical matrix by recognizing
% objects

%figure(1)
%imshow(img)

img_double=im2double(img);
Igray=rgb2gray(img_double);
%figure(2)
%imshow(Igray)

m=3; n=3;
[~,noise]=wiener2(Igray,[m,n]);
J=wiener2(Igray,[m,n],noise);
%figure(3)
%imshow(J)

img_edge=edge(J);
img_edge=imdilate(img_edge,strel('square',2));
img2=imfill(img_edge,'holes');
img2=bwareaopen(img2,500,8);
%figure(4)
%imshow(img2)
end




