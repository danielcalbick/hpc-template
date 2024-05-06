function obj_out = analysis_pipeline_sub_function_1(input1, input2, varargin)
%{
Example of the first step in the pipeline which takes 2 necessary inputs
and some optional inputs and outputs a structure that will contain the
analysis object loaded with the run_parameters and the run_parameters
themselves.

Inputs:

input1 = integer number for how many data points
input2 = standard deviation for the normal distribution in x

    (optional input-pairs) 
        "printstuff" , true/false :: do you want to print a description to
            the command line
        "input", obj :: a loaded input structure (perhaps if you want to rerun the
            analysis with the same structure and parameters
        "save", path (str) :: a string that tells the function where to
            save the structure. If you input this path it assumes you want to
            save it.

Outputs:
obj_out = the analysis object

%}

%%
[input_data,  printStuff, save_path] = parse_args_in(vars);

% Set the fields of analysis object based on the inputs input1 and input2
if ~isempty(input_data),run_params = input_data;
else,run_params = get_run_paramters(input1,input2); end

% Create the analysis object (located in ../objects/analysis_object1.m
obj_out.obj  = analysis_object1();

xdata = run_params.xdata;
ydata = run_params.ydata;

[xdata_norm,ydata_norm] = dependency_script_1(xdata,ydata);

obj_out.run_params = run_params;
obj_out.xdata_norm = xdata_norm;
obj_out.ydata_norm = ydata_norm;

% If printstuff was flagged print some stuff to the command window
% True by default, set in parse_args_in()
if printStuff, print_stuff(obj_out); end

if ~isempty(save_path), save(save_path,"obj_out","-v7.3"); end


end

%% Internal Helper Functions
function [input_data, printStuff,save_path] = parse_args_in(vars)

% Set defaults
    printStuff  = true;
    input_data  = [];
    save_path   = [];
    
    % Go through the optional inputs
    if ~isempty(vars)
    
        args = reshape(vars,2,[]);
    
        for i = 1:size(args,2)
            switch lower(args{1,i})
                case "printstuff"
                    disp('Running pRNN through trials')
                    printStuff = args{2,i};
                case "input"
                    input_data = args{2,i};
                case "save"
                    save_path  = args{2,i};
            end
    
        end
        
    end

end

function run_params = get_run_paramters(input1,input2)

run_params.input1  = input1;
run_params.input2  = input2;
run_params.xdata   = randn(input1,1)*input2;
run_params.ydata   = rand(input1,1);

end


function print_stuff(obj_out)

disp(struct2table(obj_out))


end












