function [ imgout ] = RemoveNoise( img )
m=3; n=3;
[~,noise]=wiener2(img,[m,n]);
imgout=wiener2(img,[m,n],noise);


end

