

function d = get_binocular_dilation( data )

    l_dil = flatten(data(:,8));
    r_dil = flatten(data(:,9));  
    
    d = (l_dil + r_dil) / 2;
    
end