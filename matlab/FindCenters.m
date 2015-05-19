function position = FindCenters(filename, calibrate, doPlots)
close all
scene=imread(filename);
imshow(scene);

scene=rgb2hsv(scene);
if(calibrate)
    [Y1,X1]=ginput();
    [Y2,X2]=ginput();
    X1=round(X1);
    Y1=round(Y1);
    X2=round(X2);
    Y2=round(Y2);
    H1=scene(X1,Y1,1);
    S1=scene(X1,Y1,2);
    V1=scene(X1,Y1,3);
    H2=scene(X2,Y2,1);
    S2=scene(X2,Y2,2);
    V2=scene(X2,Y2,3);
else    
    H1=0.9322;
    S1=0.5029;
    V1=0.6706;
    H2=0.1255;
    S2=0.4326;
    V2=0.6980;

end
[SY,SX,NieNodig]=size(scene);
cx1=0;
cy1=0;
cx2=0;
cy2=0;
k=0;
l=0;
margeH=0.1;
margeS=0.2;
margeV=0.2;
for i=1:1:SY
    for j=1:1:SX
        if(scene(i,j,1)>H1-margeH && scene(i,j,1)<H1+margeH && scene(i,j,2)>S1-margeS && scene(i,j,2)<S1+margeS && scene(i,j,3)>V1-margeV && scene(i,j,3)<V1+margeV)
            if(doPlots)
                hold on
                plot(j,i,'x');
            end
            cx1=cx1+j;
            cy1=cy1+i;
            k=k+1;
        end
       
                
         if(scene(i,j,1)>H2-margeH && scene(i,j,1)<H2+margeH && scene(i,j,2)>S2-margeS && scene(i,j,2)<S2+margeS && scene(i,j,3)>V2-margeV && scene(i,j,3)<V2+margeV)
            if(doPlots)
             hold on
             plot(j,i,'x');
            end
             cx2=cx2+j;
            cy2=cy2+i;
            l=l+1;
         end
      
    end
end

    if(k>0)
            cx1=round(cx1/k);
            cy1=round(cy1/k);
    end
    if(l>0)
            cx2=round(cx2/l);
            cy2=round(cy2/l);
    end
    cx=(cx1+cx2)/2;
    cy=(cy1+cy2)/2;
    if(doPlots)
    hold on;
        plot(cx1,cy1,'r*');
        plot(cx2,cy2,'r*');
        plot(cx,cy,'x');
    end

if(cx1>cx2)
angle=mod(180+atand((cy2-cy1)/(cx2-cx1)),360);
else
angle=mod(atand((cy2-cy1)/(cx2-cx1)),360);
end
position = [cx,cy,angle];

end

