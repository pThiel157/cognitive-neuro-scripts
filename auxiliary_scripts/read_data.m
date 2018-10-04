% Reads the pupil data from a given path and turns it into a matlab cell array

function d = read_data( path )

    content = fileread( path );
    lines = regexp(content, '\n', 'split');
    % Get rid of header row:
    lines(1) = [];
    
    d = regexp(lines, '\t', 'split');
    
    %disp(d(1:8));
    d{end} = [];
    d = reshape(d,[numel(d) 1]);
    
    % So far we have a cell array of cell arrays, so we need to
    % concatenate them into one big 2D cell array:
    d = vertcat(d{:});
        
    % For debugging purposes:
    %cellplot(d(1:8,:));
end