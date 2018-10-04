

function d = sort_data( data, mode )
    
    target_acc = '0';
    using_target_acc = true;
    if mode == "correct"
        target_acc = '1';
    elseif mode == "mistake"
        target_acc = '0';
    elseif mode == "either"
        using_target_acc = false;
    else
        error('Unhandled mode passed to sort_data');
    end
    
    % Filter only the correct or mistake rows and filter out any datapoints
    % where the participant didn't react in time (i.e. has an RT of '0'):
    if using_target_acc
        data = data( strcmp(data(:,14), target_acc), :);
    end
    data = data(~strcmp(data(:,15), '0'), :);
    
    % Special stuff for only if we're doing alternate sorting for the
    % pre-stimulus category:
    global PRESTIM_SPAN;
    if PRESTIM_SPAN > 0
        [pre1, data] = filter_prestim_data( data );
        %pre1 = d(1);
        %data = d(2);
    else
        pre1 = [];
    end
    
    % Categorize the data into our four categories:
    stim  = data(contains(data(:,17), 'Stimulus'), :);
    wait  = data(contains(data(:,17), 'Wait1'), :);
    blank = data(contains(data(:,17), 'Blank'), :);
    pre2  = data(~(contains(data(:,17), 'Stimulus') | ...
                   contains(data(:,17), 'Wait1') | ...
                   contains(data(:,17), 'Blank')), :);
    
    % Special stuff for only if we're doing alternate sorting for the
    % pre-stimulus category:
    [nrows1, nrows2] = size(pre1);
    if nrows1 > 0
        [nrows2, ncols2] = size(pre2);
        if nrows2 > 0
            pre1(end:end-1+nrows2,:) = pre2;
        end
        pre = pre1;
    else
        pre = pre2;
    end
    
               
    d = { stim, wait, blank, pre };
    
end
