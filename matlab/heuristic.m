function [ HN ] = heuristic( xNode,yNode,xGoal,yGoal)
%Snellere heuristiek gebaseerd op "gaming source"
%D=1
%D2=sqrt(2)*D
dx=abs(xNode-xGoal);
dy=abs(yNode-yGoal);
HN = dx+dy+(sqrt(2)-2)*min(dx,dy);

% Dezelfde gaming source zegt dat het mogelijk is om 'gelijke stand' tussen
% kortste paden te verbreken door herschaling van de geschatte kost h(n).
% De site stelt voor om HN lichtjes naar omhoog te schalen (niet te veel,
% want h(n) mag de echte kost niet overschatten!).

scale=0;
HN=HN*(1+scale);

end

