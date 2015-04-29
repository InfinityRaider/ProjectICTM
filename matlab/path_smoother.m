function [path_smooth]= path_smoother(path,cspace)
%___________________________________________________________________________
% Function which uses the line of sight function to create any-angle paths 
% from a node to node generated path.
%
% 01/03/2012 - J. Whittington - University of Bath
%___________________________________________________________________________
%___________________________________________________________________________

% New smoothed path row Inc
k=1;
% Start at the very beginning
path_smooth(k,:)=path(size(path,1),1:2);

% Move along path
for i=size(path,1):-1:2
	% Once the line of sight becomes blocked
	if (lineofsightB(path_smooth(k,1),path_smooth(k,2),path(i-1,1),path(i-1,2),cspace)==0)
    k=k+1; %move to next row of new path
	path_smooth(k,:)=path(i,1:2); % and add the last clear sighted node to array
	end
end
%hiervoor

% Add final point
k=k+1;
path_smooth(k,:)=path(1,1:2);

end 