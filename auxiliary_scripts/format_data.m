% Format and interpolate the pupil data found at a given path

function d = format_data( path )

    fprintf(['Formatting pupil data from "' path '" ... ']);
    data_matrix = read_data( path );
    % Change relevant fields from strings to doubles:
    data_matrix(:,3) = cellfun(@str2double, data_matrix(:,3), 'UniformOutput', false);    % Data ID
    data_matrix(:,5) = cellfun(@str2double, data_matrix(:,5), 'UniformOutput', false);    % <temp>
    data_matrix(:,8) = cellfun(@str2double, data_matrix(:,8), 'UniformOutput', false);    % Left eye dil
    data_matrix(:,9) = cellfun(@str2double, data_matrix(:,9), 'UniformOutput', false);    % Right eye dil
    data_matrix(:,11) = cellfun(@str2double, data_matrix(:,11), 'UniformOutput', false);  % Trial ID
    fprintf('Done!\n');
    fprintf('Interpolating data... ');
    data_matrix = interpolate_data( data_matrix );
    fprintf('Done!\n');
    
    d = data_matrix;

end

function d = interpolate_data( data )

    data = interpolate_col( data, 8 );
    data = interpolate_col( data, 9 );
    
    % Filter out all rows with '-1' or NaN in a dilation field (e.g. the
    % ones we skipped during interpolation):
    data = data( ~((flatten(data(:,8)) == -1) | ...
                   (flatten(data(:,9)) == -1) | ...
                    isnan(flatten(data(:,8))) | ...
                    isnan(flatten(data(:,9)))), :);
    d = data;
    
end
function d = interpolate_col( data, col )

    % Import the globals we'll be needing:
    global MAX_INTERP_SPAN;
    global INTERP_MODE;
    
    % We have to flatten the column first to turn it into a regular array:
    x = flatten(data(:,col));
    
    % Following adapted from: https://www.mathworks.com/matlabcentral/answers/87165-how-to-i-interpolate-only-if-5-or-less-missing-data-next-to-each-other
    [b, n]       = RunLength(x == -1);
    shortNeg1    = RunLength(b & (n < MAX_INTERP_SPAN), n);
    x(shortNeg1) = interp1(find(~shortNeg1), x(~shortNeg1), find(shortNeg1), INTERP_MODE);
    data(:,col) = num2cell(x);
    
    d = data;
    
end