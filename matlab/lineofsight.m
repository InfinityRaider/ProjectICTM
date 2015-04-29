function [los_clear] = lineofsight(x,y,xdash,ydash,cspace)
%_______________________________________________________________________________________
% Function which checks the line of sight between two nodes (x,y) and (xdash,ydash).
% The output 'los_clear' is a boolean: false if line of sight is blocked by obstacle and 
% true if clear.
%
% 07/03/2012 - J.Whittington - University of Bath
% ref: Alex Nash, 2007, Line of Sight pseudo code
%_______________________________________________________________________________________
%_______________________________________________________________________________________

% Find the change in x and y between nodes
dx=xdash-x;
dy=ydash-y;
% Distance increment
f=0;
% Set output defaults to true
los_clear=1;

% Is the ydash lower than y? If it is, must use decrement
if dy<0
	dy=dy*(-1);
	sy=-1;
else
	sy=1;
end

% Is the xdash lower than x? It it is, must use decrement
if dx<0
	dx=dx*(-1);
	sx=-1;
else
	sx=1;
end

% Which delta is greater, x or y? Run on whichever is greatest
if dx>=dy
	while(x~=xdash && los_clear==1)
		f=f+dy;
		if f>=dx
			if cspace((x+((sx-1)/2)),(y+((sy-1)/2))) == 1 % Value of obstacle
				los_clear=0;
			end
			y=y+sy;
			f=f-dx;
		end
		if((f~=0)&&(cspace((x+((sx-1)/2)),(y+((sy-1)/2))) == 1))
				los_clear=0;
		end
		x=x+sx;
	end
else
	while (y~=ydash && los_clear==1)
		f=f+dx;
		if f>=dy
			if cspace((x+((sx-1)/2)),(y+((sy-1)/2)))== 1
				los_clear=0;
			end
			x=x+sx;
			f=f-dy;
		end
		
		if ((f~=0)&&(cspace((x+((sx-1)/2)),(y+((sy-1)/2))) == 1))
			los_clear = 0;
		end
		if ((dx==0) && (cspace(x,(y+((sy-1)/2)))==1) && (cspace((x-1),(y+(sy-1)/2)))==1)
			los_clear = 0;
		end
		y=y+sy;
	end
end

end 

		