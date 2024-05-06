function main_function_v3(load_id, runid, data_path, create_new_data,save_path)
%{ 
main_function_v3.m

Example of the main pipeline function which will also have parallel
features that utilize the number of CPU cores we alloted in our sbatch call
from the user node.

Inputs:

load_id         = identifier for this specific run call
runid           = identifier for the overall sbatch or dSQ run
create_new_data = True/False trigger to load saved data or to create a new dataset
save_path       = String     if loaded save the created dataset as this string 
data_path       = if we are  loading existing data where is it

%}

%% Load Dependencies

% How we have set up our directory output is that our main scripts are
% being run in [project_dir_on_cluster]/scripts/process/ which is where
% this script is and thus where the current working directory is pointed
% after calling this function from the command line.

% So, ../../ is the project directory from which all are other scripts,
% data, directories, etc. live
rootpath = '../../';

% We need matlab to be able to call all of these scripts so I want to add
% everything within the scope of our project directory to the path of the
% current running matlab instance. 
addpath(genpath(rootpath))

% NOTE: be careful because if you name two scripts the same name, e.g.
% foo.m, and they both live in different subdirectories within this scope
% then one of them will get run but you wont have direct control over which
% one, its probably just the first one that matlab has within it's path.
% This has many solutions but I suggest just avoiding naming two files the
% same name within the scope of the project.

%% Add everything to path and start parallel pool

% Sometimes I like to add a bit of variablity because if the cluster is
% super fast matlab is running on the nodes pretty much in lock-step with
% eachother at this point and however the backend of matlab asigns its
% naming convention for the parallel pools worker's it does so in the
% shared matlab application directory NOT ON THE COMPUTE NODE. This means
% that two processes could create parallel pools with the same name and
% thius corrupt/overwrite one another. This just adds jitter to that so
% when matlab is creating those temporary directories for each pool they do
% not effect eachother across the running nodes
rng('shuffle')
pause(rand(1)*2)

% Start the parallel pool with the maximum number of workers that we have
% alloted for this job
parpool(feature('NumCores'))

%% This is where I set parameters for the run


% I am leaving this  as I find it very useful. When I am triaging the
% pipeline locally, live_trig is true if I use the "Run Section" button so
% that things that I want to be triggered locally during debugging or
% whatever will happen but not if the script is being fully executed during
% the actual analysis runs
live_trig = contains(mfilename,'LiveEditorEvaluationHelper');


n_data_points  = 40;  % number of data_points
sigma          = 0.2; % standard devation used to make the data

if ~exist("save_path","var"), save_path = []; end

% If we are creating new trials use these parameters
input1    = n_data_points;
input2    = sigma;

if live_trig % if we are running this live
    
    
    if create_new_data % if we want to create a new data set

        % Call pipeline subfunction to parse and create the analysis object
        % we will pass around, save it if requested
        analysis_object1 = analysis_pipeline_sub_function_1(input1,input2,save_path); 

    else % we want to load an existing dataset

        % Get the path for the data directory
        data_path = fullfile(rootpath, "data/");

        % Get all .mat files within that directory
        fids  = dir(fullfile(data_path,"*.mat"));

        % Identify the file we want to load
        load_id     = 1;
        load_path   = fullfile(data_path,fids(load_id).name);

        % Load information about the matfile
        mfile  = matfile(load_path);

        % load the structure or substructure into memory
        sub_struct = mfile.("substruct_field_name");

        analysis_object1 = sub_struct(load_id,1);
        
    end

    % Set things that would normally be input into this main function
    load_id = 1;
    runid   = dicomuid;
    
else % we are running a full run

    % we have the inputs as they we passed from outside the function (say
    % from the sbatch file on the cluster user node

    if create_new_data     
        % Call pipeline subfunction to parse and create the analysis object
        % we will pass around, save it if requested
        analysis_object1 = analysis_pipeline_sub_function_1(input1,input2,save_path);   
    else
        fids  = dir(fullfile(data_path,"*.mat"));
        load_path = fullfile(data_path,fids(load_id).name);
        mfile     = matfile(load_path);
        analysis_object1  = mfile.analysis_object(load_id,1);
    end
    
end



%% Run Second Pipeline Node

% This step in the pipeline will utilize the parallel cores by running the
% data on all the different workers
analysis_object2 = ...
    analysis_pipeline_sub_function_2(analysis_object1, 'print', true);

%% Set up the save paths for the whole run

save_path = fullfile(rootpath, 'hpc-outputs' , load_path , runid);

save_path_analysis = fullfile(save_path,'analysis');
save_path_structs  = fullfile(save_path,"save-structures");

objid = string(java.util.UUID.randomUUID.toString);

fileid        = strjoin(['foo-obj-id', load_id, objid],'_');
fid_structure = strcat(save_path_analysis,'/',fileid, '.mat');

fileid    = strjoin(['foo-analysis-id', load_id, objid],'_');
fid_stats = strcat(save_path_structs,'/',fileid, '.mat');

%% Save one output object

if 0, save_struct = reduce_memory_size(analysis_object2); 
else, save_struct = format_object_to_table(analysis_object2); end

save(fid_structure , "runid" , "load_id" , "objid", "save_struct")

%% Save the other output object

analysis_table = format_object_to_table(analysis_object2);
stats_out      = format_stats_structure(prnn_out,analysis);

% Example of saving two workspace variables to one structure that can be
% loaded independently via load(foo.mat, "saved_variable_name1", "saved_variable_name2",...)
% or will give you quicker information about the internal .mat structures
% if you use: fileinfo = matfile(foo.mat);
% You could then load it via: saved_variable_name1 = fileinfo.saved_variable_name1;

save(fid_stats , "runid", "load_id", "objid", "analysis_table" , "stats_out")

%% log 

% If this is the first run of the batch analysis then write a text file
% that has all of the parameters that were used in this run
if load_id == 1, log_parameters(analysis_object1, run_params, save_path); end

end 


%% Support Functions

function [network_structures,map_data] = reduce_memory_size(prnn_out)
%%


maps = prnn_out.decoding_maps;

rm_fields = { 'train_prediction','valid_prediction','valid_error','train_error','compilation_error','plot'};
map_data  = structfun(@single,rmfield(maps,rm_fields),uniformoutput=false);

train1 = prnn_out.trainned_rnn;
valid1 = prnn_out.validation_rnn1;
valid2 = prnn_out.validation_rnn2;


basernn = train1.progrnn.basernn;
prnn    = train1.progrnn.prnn;
prnn.W  = train1.progrnn.basernn.W;

network_structures = prnnvars_out;

network_structures.prnn               = prnn;
network_structures.basernn            = basernn;
network_structures.board_params       = prnn_out.board_params;
network_structures.decoding_maps      = map_data;
network_structures.training_data      = train1.data;
network_structures.validation_data    = valid1.data;
network_structures.input_data.train   = train1.input_data;
network_structures.input_data.valid_predecoding  = valid1.input_data;
network_structures.input_data.valid_postdecoding = cellfun(@(s) s.input_data,valid2,uniformoutput=false);


end

function [network_outputs, decoding_outputs, stats_out]  = gather_stats(prnn_out,analysis)
%%
    
    rnn_valid1 = prnn_out.validation_rnn1;
    rnn_valid2 = prnn_out.validation_rnn2;

    network_outputs = network_outputs_pong();
    network_outputs.rnn_trained.data   = cellfun(@(r) r.network_outputs(),rnn_valid2,uniformoutput=false); 
    network_outputs.rnn_untrained.data = rnn_valid1.network_outputs();
    network_outputs.board_params  = prnn_out.board_params;

       
    %%

    maps = prnn_out.decoding_maps;

    decoding_outputs = decoding_outputs_pong;

    decoding_outputs.avg_train_error       = mean(maps.train_error,3);
    decoding_outputs.avg_valid_error       = mean(maps.valid_error,3);
    decoding_outputs.avg_valid_correlation = maps.valid_correlation;
    decoding_outputs.avg_valid_cor_mse_sum = maps.valid_cor_mse_sum;
    decoding_outputs.t_decode              = maps.t_decode    ;
    decoding_outputs.t_validation          = maps.t_validation;
    decoding_outputs.best_map              = maps.best_mapping;
    decoding_outputs.best_map_index        = maps.best_map_index;


    

    %%

    stats_out = statistic_outputs_pong();

    stats_out.brain_rsa                = analysis.brain_rsa;
    stats_out.correlation_stats        = analysis.correlation_stats;
    stats_out.game_stats_rand_training = analysis.game_stats_rand_training;
    stats_out.game_stats_rand_training = analysis.game_stats_rand_valid;
    stats_out.game_stats_rand_training = analysis.game_stats_pred_valid;




end


function log_parameters(nneurons, connectivity, ntrials, board_params,save_path)
%%   
% Open a file to write
    logfid = fullfile(save_path,'parameter_log.txt');
    fileID = fopen(logfid, 'w');

    % Check if the file was opened successfully
    if fileID == -1
        error('Failed to open file.');
    end

    % Write the simple variables
    fprintf(fileID, ['Date: ' char(datetime('now')) '\n\n']);
    fprintf(fileID, 'Number of neurons: %d\n', nneurons);
    fprintf(fileID, 'Connectivity: %s\n', connectivity);
    fprintf(fileID, 'Number of training trials: %d\n\n', ntrials);

    % Write the board_params structure
    fprintf(fileID, 'Board Parameters:\n\n');
    fieldNames = fieldnames(board_params);
    for i = 1:length(fieldNames)
        fieldName = fieldNames{i};
        fieldValue = board_params.(fieldName);

        % Handle different types of field values
        if isnumeric(fieldValue)
            if numel(fieldValue) == 1
                % Scalar numeric values
                fprintf(fileID, '   %s: %.4f\n', fieldName, fieldValue);
            else
                % Array values, write as a comma-separated list
                fprintf(fileID, '   %s: [', fieldName);
                fprintf(fileID, '%.4f, ', fieldValue(1:end-1));
                fprintf(fileID, '%.4f]\n', fieldValue(end));
            end
        elseif ischar(fieldValue)
            % String values
            fprintf(fileID, '   %s: %s\n', fieldName, fieldValue);
        else
            % For other types, just use a generic output
            fprintf(fileID, '   %s: %s\n', fieldName, mat2str(fieldValue));
        end
    end

    % Close the file
    fclose(fileID);
end








