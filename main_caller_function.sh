#!/bin/bash

netid=$1
runid=$2
connectivity=$3

script_dir=scripts/process

cd $script_dir

module load MATLAB/2023a
matlab -nosplash -nodisplay -r "train_and_run_rnn_worldmodels( $netid , '$runid' , '$connectivity'); exit;"

