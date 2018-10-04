% Categorizes a given unsorted pupildata matrix by its trials

function d = split_by_trials( data )
    
    temp = data(:,11);
    
    [~,~,X] = unique(flatten(temp));
    d = accumarray(X,1:size(data,1),[],@(r){data(r,:)});
    
end