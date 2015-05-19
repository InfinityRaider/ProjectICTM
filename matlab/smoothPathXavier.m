function [eventual_path] = smoothPathXavier(startPath, image)

length = size(startPath,1);
path = zeros(length,2);
path(1,:) = startPath(1,:);
i = 2;
prevPoint = 1;
while(i<=length) 
   if(hasLineOfSight(path(prevPoint,:), startPath(i,:), image))
      i = i+1;
   else
      path(prevPoint+1,:) = startPath(i-1,:);
      prevPoint = prevPoint + 1;
      i = i+1;
   end
end
%add final point
path(prevPoint+1,:) = startPath(length,:);
%shrink path to necessary length
j = 1;
while(j<=length)
    if(path(j,1)==0 && path(j,2)==0)
        path = path(1:j-1,:);
        break;
    end
    j = j+1;
end
%invert path
path_length = size(path,1);
eventual_path = zeros(path_length,2);
k = 1;
while(k<=path_length)
    eventual_path(k,:) = path(path_length+1-k,:);
    k = k+1;
end
end

