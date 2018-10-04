% Turns a given column of cells into a standard array
   
function d = flatten( column )

d = vertcat(column{:});
    
end