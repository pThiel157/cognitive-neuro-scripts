

function d = get_updated_EEG_record( trials, EEG_path )

    global rejected;

    fprintf("Updating EEG records... ");
    
%     trials = split_by_trials( data );

    % Get only "mistake" trials or "correct" trials (or both) depending on
    % user options:
    global TRIAL_CORRECTNESS;
    sorted_trials = cellfun(@(t) sort_data(t,TRIAL_CORRECTNESS), trials, 'UniformOutput', false);

    % Get just the 'wait' period from each trial:
    trial_wait_data = cellfun(@(t) t{2}, sorted_trials, 'UniformOutput', false);
    
    % Sort the trials based on dilation
    trial_wait_dils = cellfun(@(t) get_avg_dilation(t), trial_wait_data);

    [~,I] = sort(trial_wait_dils);
    
    sorted_trials = trial_wait_data(I);
    
    % Get rid of all the trials with too little wait-period data:
    global TRIAL_WAIT_DATA_MINIMUM;
    sorted_trials = sorted_trials(cellfun(@(c) size(c, 1) >= TRIAL_WAIT_DATA_MINIMUM, sorted_trials));
        
    % Make an array representing the edge indices of our bins:
    num_trials = size(sorted_trials, 1);
    global NUM_TRIAL_BINS;
    edges = 0:(1 / NUM_TRIAL_BINS):1;
    edges = arrayfun(@(x) x * num_trials, edges);
    
    EEG_data = importdata( EEG_path );
    
    % Get rid of anything that doesn't correspond to trial data:
    % (Note: we're running this 6 times because it fixes some bugs.
    %  It's clearly a hack, but it's our hack)
    EEG_data = clean_EEG_data(clean_EEG_data(clean_EEG_data(clean_EEG_data(clean_EEG_data(clean_EEG_data( EEG_data ))))));
    
%     % For debugging:
%     disp("size of EEG_data:")
%     disp(size(EEG_data.data))
        
    % Loop through the sorted trials, calculating their categories and
    % writing them into the output data:
    for i = 1:num_trials
       trial = sorted_trials{i};
       trial_id = trial(1,11);
       
       field_1 = EEG_data.data(trial_id{1} * 2 - 1, 2);
       field_2 = EEG_data.data(trial_id{1} * 2    , 2);
       
       % Check if field 1 is valid:
       field_1_isValid = field_1 == 1 || ...
                         field_1 == 2 || ...
                         field_1 == 3;
       
       % Check if field 2 is valid:
       field_2_isValid = field_2 == 21 || ...
                         field_2 == 22 || ...
                         field_2 == 23 || ...
                         field_2 == 31 || ...
                         field_2 == 32 || ...
                         field_2 == 33;
       
       % Only update the EEG data if the existing EEG data for the trial
       % is valid:
       if field_1_isValid && field_2_isValid
           category = categorize_trial( edges, i );
           EEG_data.data(trial_id{1} * 2, 2) = category;
       else
           rejected = rejected + 1;
       end
    end
            
    fprintf("Done!\n");
    
    global count1;
    global count2;
    global count3;
    global count4;
    disp("Count 1:")
    disp(count1)
    disp("Count 2:")
    disp(count2)
    disp("Count 3:")
    disp(count3)
    disp("Count 4:")
    disp(count4)
    disp("Rejected:")
    disp(rejected)
    
    d = EEG_data;

end

function d = categorize_trial( edges, index )

    bin_index = discretize(index, edges);

    d = 100 + bin_index;
    
    global count1;
    global count2;
    global count3;
    global count4;
    if d == 101
        count1 = count1 + 1;
    elseif d == 102
        count2 = count2 + 1;
    elseif d == 103
        count3 = count3 + 1;
    elseif d == 104
        count4 = count4 + 1;
    end
    
end
function d = clean_EEG_data( EEG_data )

    data = EEG_data.data;
    
    % Find and mark of all the "10000X" entries and the entries immediately
    % before each:
    deadspots = data(:,2) >= 100000;
    deadspots2 = deadspots;
    deadspots2(1) = [];
    deadspots2 = [deadspots2; false];
    
    data(deadspots,  2) = -1;
    data(deadspots2, 2) = -1;
    
    % Delete all the rows we marked:
    data(data(:,2) == -1, :) = [];
    
    % Go through the data and find any duplicate single / double digits
    % occurring right after each other, deleting the second instance in
    % each case:
    i = 1;
    while i < length(data)
        entry1 = data(i,     2);
        entry2 = data(i + 1, 2);
        
        if (entry1 < 10 && entry2 < 10) || (entry1 >= 10 && entry2 >= 10)
            data(i+1, 2) = -1;
            i = i + 1;
        end
        
        i = i + 1;
    end
    data(data(:,2) == -1, :) = [];
    data(data(:,2) == -2, :) = [];
    
    % Remove the first entry if its a large number
    if data(1, 2) >= 10
        data(1, :) = [];
    end

    EEG_data.data = data;
    d = EEG_data;

end
