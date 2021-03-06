function [Smooth_path]=Smooth_AStar_Path(Topmap,Start)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A* ALGORITHM Demo
% Interactive A* search demo
% 04-26-2005
%   Copyright 2009-2010 The MathWorks, Inc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


imagesc(Topmap)
colormap(flipud(gray))
%set(gca,'XTick',0:1:Mapsize,'Ytick',0:1:Mapsize);



%%%%%%%%%%%%%%%%%%%%

Size_Map=size(Topmap);
MapsizeX=Size_Map(2);
MapsizeY=Size_Map(1);
%DEFINE THE 2-D MAP ARRAY
MAX_X=MapsizeX;
MAX_Y=MapsizeY;
MAX_VAL=MapsizeX;
%This array stores the coordinates of the map and the 
%Objects in each coordinate
MAP=Topmap;

% Obtain Obstacle, Target and Robot Position
% Initialize the MAP with input values
% Target = -1,Space=0, Obstacle=1,Robot=2

axis([1 MAX_X+1 1 MAX_Y+1])
grid on;
hold on;

xStart=Start(2);
yStart=Start(1);

xTarget=MapsizeX-20;
yTarget=20;

MAP(xTarget,yTarget)=-1;%Initialize MAP with location of the target
plot(xTarget,yTarget,'gd');
text(xTarget+1,yTarget,'Target');



MAP(xStart,yStart)=2;
 plot(xStart,yStart,'bo');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LISTS USED FOR ALGORITHM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%OPEN LIST STRUCTURE
%--------------------------------------------------------------------------
%IS ON LIST 1/0 |X val |Y val |Parent X val |Parent Y val |g(n) |h(n)|f(n)|
%--------------------------------------------------------------------------
OPEN=zeros(MAX_X*MAX_Y,8); % Verzameling van variabele knopen - MAAR NIET ALLE KNOPEN WORDEN ONMIDDELLIJK TOEGEVOEGD! Pas wanneer je een knoop tegenkomt, voeg je die toe
CLOSED=zeros(MAX_X*MAX_Y,2);% Verzameling van permanente knopen



%CLOSED LIST STRUCTURE
%--------------
%X val | Y val |
%--------------
% CLOSED=zeros(MAX_VAL,2);


%Put all obstacles on the Closed list
k=1;%Dummy counter
for i=1:MAX_Y
    for j=1:MAX_X
        if(MAP(i,j) == 1)
            CLOSED(k,2)=i; %Noteer y-coordinaat obstakel
            CLOSED(k,1)=j; %Noteer x-coordinaat obstakel
            k=k+1;
        end
    end
end

CLOSED_COUNT=size(CLOSED,1);%Zet Closed_Count = aantal rijen in matrix CLOSED
%set the starting node as the first node
xNode=xStart;
yNode=yStart;
OPEN_COUNT=1;
path_cost=0;%Nog geen pad dus huidige kost is 0
goal_distance=distance(xNode,yNode,xTarget,yTarget); % conservatieve schatting van beschouwd punt naar target
OPEN(OPEN_COUNT,:)=insert_open(xNode,yNode,xNode,yNode,path_cost,goal_distance,goal_distance);%plaats op rij met alle nodige parameters, zie function insert_open
OPEN(OPEN_COUNT,1)=0; % Neem het van de lijst - parameter om een knoop niet te hoeven verwijderen uit OPEN wanneer je het overzet naar CLOSED
CLOSED_COUNT=CLOSED_COUNT+1;%Wordt gebruikt op de startknoop toe te voegen aan de CLOSED lijst
CLOSED(CLOSED_COUNT,1)=xNode;
CLOSED(CLOSED_COUNT,2)=yNode;
NoPath=1;%Parameter die wijzigt wanneer er geen pad bestaat naar het einddoel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START ALGORITHM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while((xNode ~= xTarget || yNode ~= yTarget) && NoPath == 1)
%  plot(xNode+.5,yNode+.5,'go');
 exp_array=expand_array(xNode,yNode,path_cost,xTarget,yTarget,CLOSED,MAX_X,MAX_Y);%Maak een lijst van successor nodes en hun eigenschappen
 exp_count=size(exp_array,1);%Aantal successor nodes 
 %UPDATE LIST OPEN WITH THE SUCCESSOR NODES
 %OPEN LIST FORMAT
 %--------------------------------------------------------------------------
 %IS ON LIST 1/0 |X val |Y val |Parent X val |Parent Y val |g(n) |h(n)|f(n)|
 %--------------------------------------------------------------------------
 %EXPANDED ARRAY FORMAT
 %--------------------------------
 %|X val |Y val ||g(n) |h(n)|f(n)|
 %--------------------------------
 for i=1:exp_count %Doorloop de lijst van succesors
    flag=0;
    for j=1:OPEN_COUNT %Doorloop de Open-lijst
        if(exp_array(i,1) == OPEN(j,2) && exp_array(i,2) == OPEN(j,3) )%Als de succesorknoop al op de openlijst staat
            OPEN(j,8)=min(OPEN(j,8),exp_array(i,5)); %#ok<*SAGROW> %Update de kostfunctie f(n) naar deze met de lagere waarde
            if OPEN(j,8)== exp_array(i,5)%Als de gevonden optie efficienter was 
                %UPDATE PARENTS,gn,hn
                OPEN(j,4)=xNode;%Wijzig xParent want degene die we nu gevonden hebben is beter
                OPEN(j,5)=yNode;%idem voor y
                OPEN(j,6)=exp_array(i,3);%g(n) aanpassen
                OPEN(j,7)=exp_array(i,4);%h(n) aanpassen
            end;%End of minimum fn check
            flag=1;
        end;%End of node check
%         if flag == 1
%             break;
    end;%End of j for
    if flag == 0 %Als de knoop niet op de openlijst stond voeg hem dan toe
        OPEN_COUNT = OPEN_COUNT+1;%Open lijst is langer geworden
        OPEN(OPEN_COUNT,:)=insert_open(exp_array(i,1),exp_array(i,2),xNode,yNode,exp_array(i,3),exp_array(i,4),exp_array(i,5));
     end;%End of insert new element into the OPEN list
 end;%End of i for
 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %END OF WHILE LOOP
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %Find out the node with the smallest fn 
  index_min_node = min_fn(OPEN,OPEN_COUNT,xTarget,yTarget);
  if (index_min_node ~= -1) %Als min_fn -1 terug geeft dan is er geen verder pad meer mogelijk langs hier  
   %Set xNode and yNode to the node with minimum fn
   xNode=OPEN(index_min_node,2);
   yNode=OPEN(index_min_node,3);
   path_cost=OPEN(index_min_node,6);%Update the cost of reaching the parent node
  %Move the Node to list CLOSED
  CLOSED_COUNT=CLOSED_COUNT+1;%Closed lijst wordt 1 langer
  CLOSED(CLOSED_COUNT,1)=xNode;
  CLOSED(CLOSED_COUNT,2)=yNode;
  OPEN(index_min_node,1)=0;%Haal de gekozen knoop van de OPEN lijst
  else
      %No path exists to the Target!!
      NoPath=0;%Exits the loop!
  end;%End of index_min_node check
  
end;%End of While Loop
%Once algorithm has run The optimal path is generated by starting of at the
%last node(if it is the target node) and then identifying its parent node
%until it reaches the start node.This is the optimal path
i=size(CLOSED,1);
Optimal_path=[];
xval=CLOSED(i,1);%Xwaarde van de laatste knoop toegevoegd aan CLOSED(einddoel)
yval=CLOSED(i,2);%Idem voor Y
i=1;
Optimal_path(i,1)=xval;
Optimal_path(i,2)=yval;
i=i+1;%Om straks direct de "volgende" knoop toe te voegen

if ( (xval == xTarget) && (yval == yTarget))%Als het einddoel bereikt werd
   inode=0;
   %Traverse OPEN and determine the parent nodes
   %Zoek de eindknoop in de OPEN-lijst
   parent_x=OPEN(node_index(OPEN,xval,yval),4);%node_index returns the index of the node, 4 en 5 bevatten X en Y-coordinaten van de parent van de knoop met node_index
   parent_y=OPEN(node_index(OPEN,xval,yval),5);
   
   %i heeft hier de waarde 2
   while( parent_x ~= xStart || parent_y ~= yStart)%Zolang we niet terug zijn in het startpunt
           Optimal_path(i,1) = parent_x;
           Optimal_path(i,2) = parent_y;
           %Get the grandparents:-)
           inode=node_index(OPEN,parent_x,parent_y);%Zoek de de knoop die momenteel in parent zit op in de lijst om zijn parents te vinden
           parent_x=OPEN(inode,4);%node_index returns the index of the node
           parent_y=OPEN(inode,5);
           i=i+1;
    end;
 j=size(Optimal_path,1);
 %Plot the Optimal Path!
 p=plot(Optimal_path(j,1),Optimal_path(j,2),'bo');
 j=j-1;
 for i=j:-1:1
  set(p,'XData',Optimal_path(i,1),'YData',Optimal_path(i,2));
 drawnow ;
 end;
 plot(Optimal_path(:,1),Optimal_path(:,2));
else
 pause(1);
 h=msgbox('Sorry, No path exists to the Target!','warn');
 uiwait(h,5);
end

%hierna
Optimal_path;
Smooth_path=smoothPathXavier(Optimal_path,Topmap);
plot(Smooth_path(:,1),Smooth_path(:,2),'red');


 %plot(OPEN(:,2),OPEN(:,3),'g*');
% plot(CLOSED(:,1),CLOSED(:,2),'y*');


end





