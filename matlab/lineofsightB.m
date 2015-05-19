function [los_clear] = lineofsightB(x,y,xdash,ydash,cspace)
%vergelijking rechte: y=y0+(x-x0)*(ydash-y0)/(xdash-x0)
% Geeft 'true' terug wanneer er geen obstakel van cspace ligt op rechte
% lijn die met bovenstaande vergelijking gedefinieerd is.

inc=0.004;
xlist=x+inc:inc:xdash;
ylist=y+(xlist-x).*(ydash-y)/(xdash-x);
los_clear=1;
S=size(cspace);
if(xdash==S(1)-20 && ydash==S(1)-20)
    round(xlist);
    round(ylist);
end
length(xlist);
for i=1:1:length(xlist)
    yi=round(ylist(i));
    xi=round(xlist(i));
   
    if(cspace(yi,xi)==1)
        los_clear=0;
        break
    end
end

    
    