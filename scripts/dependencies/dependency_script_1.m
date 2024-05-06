function [output1,output2] = dependency_script_1(input1,input2)

%{
Example of an external dependency that you may have downloaded or that your
code base needs.

this takes two arguments, input1 and input2, does a simple normalization
and then returns the normalized inputs as outputs 1&2.
%}

mxx = max([input1(:) input2(:)]);
mnn = min([input1(:) input2(:)]);

input1  = input1 - mnn;
output1 = input1/mxx;

input2  = input2 - mnn;
output2 = input2/mxx;


end

