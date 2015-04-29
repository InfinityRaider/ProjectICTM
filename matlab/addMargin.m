function [map] = addMargin(map, margin)
%Adds margin to a logical map containing objects
    % 0 = free space
    % 1 = object
    
mapSize = size(map)
inObject = map(1, 1) == 1;

% add margin vertically
u = 1;
while u <= mapSize(1)
    v = 1;
    while v <= mapSize(2)
        value = map(u, v);
        %We are inside an object currently and we detect an edge
        if inObject && value==0
            % add margin to the bottom
            for i = 0:margin
                if v+i<=mapSize(2)
                    map(u, v+i) = 1;
                end
            end
            %set inObject to false because we are no longer inside an
            %object and set v to the correct value
            v = min(v + i, mapSize(2));            
            inObject = false;
            
        %We are not inside an object and we detect an edge    
        else if ~inObject && value==1
            % add margin to the top
            for j = 0:margin
                if v-j-1>0
                    map(u, v-j-1) = 1;
                end
            end
            %Set inObject to true
            inObject = true;
            end            
        end  
        v=v+1;
    end
    u=u+1;
end

% add margin horizontally
inObject = map(1, 1) == 1;
v = 1;
while v <= mapSize(2)
    u = 1;
    while u <= mapSize(1)
        value = map(u, v);
        %We are inside an object currently and we detect an edge
        if inObject && value==0
            % add margin to the right
            for i = 0:margin
                if u+i<=mapSize(1)
                    map(u+i, v) = 1;
                end
            end
            %set inObject to false because we are no longer inside an
            %object and set v to the correct value
            u = min(u + i, mapSize(1));            
            inObject = false;
            
        %We are not inside an object and we detect an edge    
        else if ~inObject && value==1
            % add margin to the top
            for j = 0:margin
                if u-j-1>0
                    map(u-j-1, v) = 1;
                end
            end
            %Set inObject to true
            inObject = true;
            end            
        end  
        u=u+1;
    end
    v=v+1;
end



end

