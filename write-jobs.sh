#!/bin/bash

# This script is used to create jobs for the cluster.

# Create a unique identificaltion for this run with the date and a random uuid.
uid=$(date +%d-%b-%Y_)$(cat /proc/sys/kernel/random/uuid)

# Save the unique identifier to a temporary file so, if we want to run the same job again or 
# delete the creation of the output directories (because lets say there was an error) we can 
# do so.
echo "$uid" > ".tmp_last_job_id"


# Set the default values for the caller function and the jobfile name.
caller_function=main_caller_function.sh
jobfile_name=jobs.txt # default jobfile name
while (( "$#" )); do
  case "$1" in
    -j)
     shift ; jobfile_name=$1 ; shift ;;
    *) break ;;
  esac
done

# Include the arguments needed for the caller function.
SUBMISSION_ARGUMENT_1=$1
SUBMISSION_ARGUMENT_2=$2

# Remove the jobfile if it exists.
if [ -f "$jobfile_name" ]; then rm $jobfile_name; fi

runid=$uid

# Create the job text file by looping through the number of jobs.
# Here, the number of jobs reflects the number of unique inputs to the caller function.
# This can be seen in the "$i" variable in the loop below that we are writing as the 
# first argument to the caller function. So, if we have 10 unique inputs to the caller
# the job file will have 10 lines, each line being a call to the caller function and when dSQ 
# runs the job file, it will run the caller function with the unique input, which will be used 
# in the main python/matlab/R script that we want to run in parallel.
for i in $(seq 1 $nmodels); do
    echo "sh $caller_function $i $runid $SUBMISSION_ARGUMENT_1 $SUBMISSION_ARGUMENT_2" >> $jobfile_name
done

# Create the output directories for this run.
# This sturucture will be bespoke to the project and the output that we want to save.
# Here we will use an example where one  argument is the condition and we want to save the
# output of the run for each parallel process in a folder named after the condition and the runid.

# NOTE, above in the for loop we are passing the runid as the second argument to the caller function
# so that our parallel processes can save their output in the correct unique folder.

# For this example, we will create a folder for the condition in SUBMISSION_ARGUMENT_1,
# the unique runid, and then two subfolders taged with the second submission argument.

mkdir "hpc-outputs/$SUBMISSION_ARGUMENT_1/$runid"
mkdir "hpc-outputs/$SUBMISSION_ARGUMENT_1/$runid/$SUBMISSION_ARGUMENT_2-analysis"
mkdir "hpc-outputs/$SUBMISSION_ARGUMENT_1/$runid/$SUBMISSION_ARGUMENT_2-save-structures"
