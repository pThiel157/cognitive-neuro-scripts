

function d = get_CM_SWBP_data( data )
    
    fprintf('Sorting data... ');
    sorted_data_SWBP_Correct = sort_data( data, 'correct' );
    sorted_data_SWBP_Mistake = sort_data( data, 'mistake' );
    fprintf('Done!\n');
    fprintf('Averaging data... ');
    avg_dilation_SWBP_Correct = get_SWBP_avg_dilation( sorted_data_SWBP_Correct );
    avg_dilation_SWBP_Mistake = get_SWBP_avg_dilation( sorted_data_SWBP_Mistake );
    fprintf('Done!\n');
   
    d = [ avg_dilation_SWBP_Correct, avg_dilation_SWBP_Mistake ];
    
end

function [p, d] = filter_prestim_data( data )

    global PRESTIM_SPAN;
    
    [numrows,numcols]=size(data);
    pre = cell(numrows,numcols);
    in_stim = false;
    i = numrows - 1;
    while i >= 1
                
        if ~contains(data(i, 17), 'Stimulus')
            if in_stim
                % The next x are sorted as pre-stim and removed from data:
                if i - PRESTIM_SPAN >= 1
                    pre(i - PRESTIM_SPAN : i, :) = data(i - PRESTIM_SPAN : i, :);
                    %data(i - PRESTIM_SPAN : i, :) = [];
                end
                
                i = i - PRESTIM_SPAN;
            end
            
            in_stim = false;
        else
            in_stim = true;
        end
        
        i = i - 1;
    end
    
    non_pre = cellfun('isempty', pre);
%     try
    non_pre_rows = non_pre(:,1);
%     catch
%         non_pre_rows = 
%     end
    % Get rid of the rows we sorted into pre:
    data = data(non_pre_rows,:);
    % Get rid of empty rows (get only the pre rows):
    pre = pre(~non_pre_rows,:);
    % Sort by target_acc:
    
    p = pre;
    d = data;
    
end
function d = get_SWBP_avg_dilation( datas )

    f = @(x) get_avg_dilation(x);
    d = cellfun(f, datas);
    
end
