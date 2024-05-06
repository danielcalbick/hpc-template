function object_out = analysis_pipeline_sub_function_2(analysis_object,varargin)
%{

analysis_pipeline_sub_function_2.m 

This function runs some parallel process on the input arguments and outputs
the processed results in a new object back to the main pipeline function.


%}
    [printStuff] = parse_args_in(varargin);
    
    % Set some internal parameter
    param = 20;

    object_out = run_analysis_function(analysis_object,param,printStuff);



end

function obj2 = run_analysis_function(analysis_object,param,printStuff)

% Initial setup
xdata  = analysis_object.xdata_norm;
ydata  = analysis_object.ydata_norm;

% Prepare for parallel execution
ntrials  = numel(xdata);
noutputs = 3;
futures  = parallel.FevalFuture.empty(0, ntrials);
pool     = gcp('nocreate'); if isempty(pool),pool = parpool;end

% Dispatch trials to workers
for i = 1:ntrials
    
    % inputs for this "trial" we are running in parallel
    inputs = {
        xdata(i), ydata(i),...
        param
        };

    % send information to preallocate for worker
    futures(i) = parfeval(pool, @parallel_function_helper, noutputs, ...
        inputs);

    % NOTE: % @parallel_function_helper is the handle to the function we
    % want parallelized; if you are familiar with parfor loops, this is what
    % would go inside that loop, however with this setup we are doing all of
    % the backend set up and allocation ahead of time making the transfer
    % of infermation from the parallel pool back to the local workspace
    % MUCH more efficient. This allows for loops that are **even faster**
    % than parfor loops.
end

% If you want to debug the function (say because something is going wrong when
% parallelizing the function) set the if argument to 1. This will run one 
% instance of the helper function and then you can set a debug point and 
% it will stop there. 
% It will also have the effect of printing the actual error and line 
% number so you know what to look for.
if 0, parallel_function_helper(inputs); end


% Initialize containers
[output1_cell, output2_cell] = deal(cell(ntrials, 1));

% This is the actual parallelized loop which will run the function on 
% each worker in the background in parallel and collect results
for i = 1:ntrials
    % If printstuff was triggered print progress to the command window
    if printStuff,disp([num2str(i) '/' num2str(ntrials)]),end
    
    % completedIdx tells us which trial finished 
    % cross_correlation is the 1st output of our helper function
    % stats is the 2nd output of our helper function
    [completedIdx, cross_correlation , stats] = fetchNext(futures);

    % Save the outputs for this trial in a cell array that we will access
    % once this parallel loop is finished
    output1_cell{completedIdx}  = cross_correlation;
    output2_cell{completedIdx}  = stats;

    
end

% Clear the workers' workspace to avoid memory issues
parfevalOnAll(pool,@clear,0,"all");

% Do some post-parallel processing on the output data
vars  = {'fit_params' 'gof' 'xdata' 'ydata' 'yfit' 'r2' 'rmse'};
stats = cell2table(output2_cell,'VariableNames',vars);

% Package the results into another object (see ../objects/analysis_object_2.m)
obj2 = analysis_object_2();

obj2.cross_correlation  = cat(2,output1_cell{:});
obj2.stats              = stats;
obj2.xdata              = xdata;
obj2.ydata              = ydata;


end

%% Helper Functions

function printStuff = parse_args_in(args)

% Defaults
printStuff = true;

if ~isempty(args)

    % just says you can give the function a flag explicitley or you can put
    % a true or false flag for vararg i

    % This is wayyyy overkill for this toy template script but it gives you
    % 
    if numel(args) == 1,printStuff = args{1};
    else
    
        args = reshape(args,2,[]);

        for i = 1:size(args,2)
            switch lower(args{1,i})
                case {'printstuff' , 'print' , 'p'}
                    printStuff = args{2,i};
            end

        end

    end

    
    
end

end

function [cross_correlation , stats] = parallel_function_helper(inputs)
%% unpack inputs for this trial

[xdata, ydata, param] = inputs{:};


%% Do some analysis on individual trials

cross_correlation = xcorr(xdata,ydata);


% Set Equation
tanhEqn = fittype('a*tanh( (1/b)*x +c) + d');

opts  = fitoptions(tanhEqn);

opts.Lower      = [0    1     -20   -1 ];
opts.Upper      = [1   100     20    1 ];
opts.StartPoint = [.1   69    param   0.4 ];

% Fit
[fit_mdl, gof_mdl] = fit(xdata,cross_correlation,tanhEqn,opts);

stats = {
    fit_mdl, gof_mdl,xdata , fit_mdl(xdata) , gof_mdl.rsquare , gof_mdl.rmse
    };





end




