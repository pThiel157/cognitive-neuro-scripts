

function d = get_avg_dilation( data )

    % Average left and right together, then take the mean of the entire
    % matrix:
    dil = get_binocular_dilation( data );
    d = mean(dil);
    
end