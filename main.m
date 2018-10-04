% Run this file to start the script

global count1;
global count2;
global count3;
global count4;
global rejected;



%########## Beginning stuff: ##########%
% Add path to our dependencies:
addpath('auxiliary_scripts/RunLength_2017_04_08/');
addpath('auxiliary_scripts/');

% Get user input for a variety of script options:
set_options();

fprintf('\n\n######## Begin: ########\n');
% Open/create our results file and write in a header:
fID = fopen('results.csv','w');
fprintf(fID, "ID,Stimulus_correct,Wait_correct,Blank_correct,Pre-Stim_correct,Stimulus_mistake,Wait_mistake,Blank_mistake,Pre-Stim_mistake\n");

%  Get the files we want:
files = get_pupildata_files();


% If requested, get the EEG files:
global PROCESSING_EEG_DATA;
if PROCESSING_EEG_DATA
    EEG_files = get_EEG_files();
end



%########## Loop through the files we collected: ##########%
for file = files'
    
    count1 = 0;
    count2 = 0;
    count3 = 0;
    count4 = 0;
    rejected = 0;
    
    % Concat the folder with the file name:
    path = ['pupil_data/' file.name];

    % Read in and format the data:
    data = format_data( path );
    
    trials = split_by_trials(data);
    temp = trials{20};
    % Plot the data:
    %plot(flatten(temp(:,5)), get_binocular_dilation(temp))
    
    % Get the averaged eye-tracking data:
    averages = get_CM_SWBP_data( data );
    
    % Get the participant ID:
    ID = get_participant_ID( path );
    
    % Write the data into the file referred to by fID:
    write_results( fID, ID, averages );

    % If requested, update the EEG records with some stats from the pupil data:
    if PROCESSING_EEG_DATA
        EEG_file = get_corresponding_EEG_file( EEG_files, file );
        if isstruct(EEG_file)
            EEG_path = ['EEG tagging files/' EEG_file.name] ;
            updated_EEG_record = get_updated_EEG_record( trials, EEG_path );
            
            % Write the updated EEG data to a file in the output folder
            % (also create the folder if it's not there):
            EEG_fID = fopen(['EEG output files/NSF1c_sub' num2str(ID) '.csv'],'w');
            if EEG_fID == -1
                mkdir("EEG output files");
                EEG_fID = fopen(['EEG output files/NSF1c_sub' num2str(ID) '.csv'],'w');
            end
            write_EEG_data( EEG_fID, updated_EEG_record );
            
        else
            fprintf("WARNING: EEG data file missing for subject number %i. Skipping and proceeding.\n", file.subject_num);
        end
    end
    
    disp_averages( averages );
    
end
    
% End by closing our results file:
fclose(fID);
fprintf('######## Finished! ########\n');




function write_results( fID, participant_ID, averages )
    
    fprintf(fID, "%f,%f,%f,%f,%f,%f,%f,%f,%f\n", participant_ID, averages);
    
end
function write_EEG_data( fID, data )

    fprintf(fID, "%s\n", data.textdata{1});
    for i = 1:length(data.data)
        %fprintf(fID, " %i      %i  %i    %i   %f %f\n", data.data(i, :));
        fprintf(fID, "%i,%i,%i,%i,%f,%f\n", data.data(i, :));
    end

    fclose(fID);
    
end
function d = get_participant_ID( path )

    fID = fopen( path );
    % The first call to fgetl gives us the header line:
    header = fgetl( fID );
    % The second call gives us the line with the data we want:
    second_line = fgetl( fID );
    % Split the line with tabs as the delimiter:
    nums = regexp( second_line, '\t', 'split' );
    % Get the ID (the first item in the row):
    ID = nums(1);
    % Convert from a string to a number:
    d = str2double( ID );
    
end
function set_options() 

    fprintf("\n\n######## OPTIONS: ########\n");
    fprintf("(Press return to use default values)\n");
    %fprintf("NOTE: Use caution when using interpolation modes that fit functions to their input data (such as spline or cubic).\n");
    %fprintf("Using these modes on large spans of missing values may result in unreasonable (e.g. negative) outputs.\n\n");
    
    global PRESTIM_SPAN;
    x = input(strcat('\n==== Pre-stimulus Span: ====\n', ...
                     '(Number of datapoints before each stimulus period to be counted in the pre-stimulus category. Press return to use standard sorting)\n', ...
                     'WARNING: Selecting too large a pre-stimulus span may result in all datapoints within some categories being sorted as\n', ...
                     'pre-stimulus, resulting in "NaN" outputs.\n', ...
                     '> \'), 's');
    try
        x = str2double(x);
    catch
        fprintf("Warning: non-numeric input given, defaulting to 0");
    end
    if isnumeric(x) && x >= 0
        PRESTIM_SPAN = x;
    else
        fprintf("Defaulting to 0\n");
        PRESTIM_SPAN = 0;
    end

    global INTERP_MODE;
    x = input(strcat('\n==== Interpolation Mode: ====\n', ...
                     '(linear, spline, nearest, next, previous, pchip, cubic, or makima)\n', ...
                     'NOTE: Use caution when using interpolation modes that fit functions to their input data (such as spline or cubic).\n', ...
                     'Using these modes on large spans of missing values may result in unreasonable (e.g. negative) outputs.\n', ...
                     '> \'), 's');
    if (x == "linear"   || x == "spline" || x == "nearest" || x == "next" || ...
        x == "previous" || x == "pchip"  || x == "makima"  || x == "cubic")
        INTERP_MODE = x;
    else
        fprintf('Defaulting to "linear"\n');
        INTERP_MODE = "linear";
    end
    
    global MAX_INTERP_SPAN;
    x = input('\n==== Maximum Interpolation Span: ====\n> ', 's');
    try
        x = str2double(x);
    catch
        fprintf("Warning: non-numeric input given, defaulting to 0");
    end
    if isnumeric(x) && x >= 0
        MAX_INTERP_SPAN = x;
    else
        fprintf("Defaulting to 0\n");
        MAX_INTERP_SPAN = 0;
    end
    
    global PROCESSING_EEG_DATA;
    x = input(strcat('\n==== Link with EEG Data? y/n ====\n', ...
                     '> \'), 's');
    if strcmpi(x, "y")
        PROCESSING_EEG_DATA = true;
    elseif strcmpi(x, "n")
        PROCESSING_EEG_DATA = false;
    else
        fprintf("Defaulting to 'n'\n");
        PROCESSING_EEG_DATA = false;
    end
    
    % ######## EEG LINKING OPTIONS: ########
    global NUM_TRIAL_BINS;
    global TRIAL_CORRECTNESS;
    global TRIAL_WAIT_DATA_MINIMUM;
    if PROCESSING_EEG_DATA
        x = input(strcat('\n==== Number of Trial "Bins" (for EEG linking): ====\n', ...
                         '> \'), 's');
        try
            x = str2double(x);
        catch
            fprintf("Warning: non-numeric input given, defaulting to 0");
        end
        if isnumeric(x) && x >= 0
            NUM_TRIAL_BINS = x;
        else
            fprintf("Defaulting to 4\n");
            NUM_TRIAL_BINS = 4;
        end
        
        x = input(strcat('\n==== Desired Trial Correctness: ====\n', ...
                         '("correct", "mistake", or "either")\n', ...
                         '> \'), 's');
        if strcmpi(x, "correct")
            TRIAL_CORRECTNESS = "correct";
        elseif strcmpi(x, "mistake")
            TRIAL_CORRECTNESS = "mistake";
        elseif strcmpi(x, "either")
            TRIAL_CORRECTNESS = "either";
        else
            fprintf('Defaulting to "either"\n');
            TRIAL_CORRECTNESS = "either";
        end
        
        x = input(strcat('\n==== Minimum "Wait" Datapoints per Trial (for EEG linking): ====\n', ...
                         '(Number of wait-period pupil datapoints required for a trial to be considered during EEG linking)\n', ...
                         '> \'), 's');
        try
            x = str2double(x);
        catch
            fprintf("Warning: non-numeric input given, defaulting to 0");
        end
        if isnumeric(x) && x >= 0
            TRIAL_WAIT_DATA_MINIMUM = x;
        else
            fprintf("Defaulting to 1\n");
            TRIAL_WAIT_DATA_MINIMUM = 1;
        end
    end
    % ######################################
    
    global START_FILE;
    x = input('\n==== Start File: ====\n(e.g. "1")\n> ', 's');
    try
        x = str2double(x);
    catch
        fprintf("Warning: non-numeric input given, defaulting to 0");
    end
    if isnumeric(x) && x >= 0
        START_FILE = x;
    else
        fprintf("Defaulting to 0\n");
        START_FILE = 0;
    end
    
    global END_FILE;
    x = input('\n==== End File: ====\n(e.g. "62")\n> ', 's');
    try
        x = str2double(x);
    catch
        fprintf("Warning: non-numeric input given, defaulting to 0");
    end
    if isnumeric(x) && x >= 0
        END_FILE = x;
    else
        fprintf("Defaulting to Infinity (running on all files after the given start file)\n");
        END_FILE = Inf;
    end

end
function d = get_pupildata_files()

    % Get all the files in the folder
    files = dir('pupil_data/*.gazedata');

    names = arrayfun(@(x)( x.name ), files, 'UniformOutput', false);

    % Get the subject number from each filename (the number between the two '-'
    % characters):
    nums = regexp(names, strcat('-[0-9]*-'), 'match');
    nums = flatten(nums);

    % Get just the subject num for each regex match:
    nums  = cellfun(@(x)( str2double( x(2:(end-1)) ) ), nums);

    % Sort the files so we traverse them in a sensible order:
    [nums,sort_index] = sortrows(nums);
    files = files(sort_index);
    
    % Save the subject number information in a new field for each file:
    for i = 1:numel(files)
        files(i).subject_num = nums(i);
    end

    % Get the indices of the files within the desired range, and then filter
    % only those files from 'files':
    global START_FILE;
    global END_FILE;
    ind   = arrayfun(@(x)( x >= START_FILE & x <= END_FILE ), nums);
    files = files(ind);
    
    d = files;
    
end
function d = get_EEG_files()

    files = dir('EEG tagging files/*.ev2');

    names = arrayfun(@(x)( x.name ), files, 'UniformOutput', false);

    % Get the subject number from each filename (the number between "sub" and "."):
    nums = regexp(names, strcat('sub[0-9]*\.'), 'match');
    nums = flatten(nums);
    
    % Get just the subject num for each regex match:
    nums  = cellfun(@(x)( str2double( x(4:(end-1)) ) ), nums);
    
    % Sort the files so we traverse them in a sensible order:
    [nums,sort_index] = sortrows(nums);
    files = files(sort_index);
    
    
    % Save the subject number information in a new field for each file:
    for i = 1:numel(files)
        files(i).subject_num = nums(i);
    end
    
    % Get the indices of the files within the desired range, and then filter
    % only those files from 'files':
    global START_FILE;
    global END_FILE;
    ind   = arrayfun(@(x)( x >= START_FILE & x <= END_FILE ), nums);
    files = files(ind);
        
    d = files;
    
end
function d = get_corresponding_EEG_file( EEG_files, file )

    match = NaN;
    for EEG_file = EEG_files'
        if EEG_file.subject_num == file.subject_num
            match = EEG_file;
        end
    end
        
    d = match;
    
end
function disp_averages( averages )

    avg_dilation_SWBP_Correct = averages(1:4);
    avg_dilation_SWBP_Mistake = averages(4:8);
    
    fprintf('\n');
    fprintf('=== Avg dilation during Stimulus: ===\n');
    fprintf('Correct: %f\n', avg_dilation_SWBP_Correct(1));
    fprintf('Mistake: %f\n', avg_dilation_SWBP_Mistake(1));
    fprintf('=== Avg dilation during Wait: ===\n');
    fprintf('Correct: %f\n', avg_dilation_SWBP_Correct(2));
    fprintf('Mistake: %f\n', avg_dilation_SWBP_Mistake(2));
    fprintf('=== Avg dilation during Blank: ===\n');
    fprintf('Correct: %f\n', avg_dilation_SWBP_Correct(3));
    fprintf('Mistake: %f\n', avg_dilation_SWBP_Mistake(3));
    fprintf('=== Avg dilation during Pre-stimulus: ===\n');
    fprintf('Correct: %f\n', avg_dilation_SWBP_Correct(4));
    fprintf('Mistake: %f\n\n', avg_dilation_SWBP_Mistake(4));
    
end
