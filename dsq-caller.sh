#!/bin/bash

# This script is used to submit jobs to the cluster using the dSQ job scheduler.

# Set default values for dsq job submissions
time="1-00:00:00"
partition="day"
CPUS_PER_TASK="13"

job_file_trigger=0

# Parse the command line arguments
while (( "$#" )); do
  case "$1" in 
    # Set optional non-default time for the job
    --time|-t) 
        shift ; time=$1 ;;
    # Set optional non-default partition for the job
    --partition|-p) 
        shift ; partition=$1 ;;
    # Set optional non-default number of cpus per task
    --cpus|-c)
        shift ; CPUS_PER_TASK=$1 ;;
    # Set optional non-default memory allocation for the job
    --mem|-m)
    shift ; mem=${1}g ;;
    *)
        if [ $job_file_trigger -eq 0 ]; then
            jobfile_name=$1
            job_file_trigger=1
            if [ -z "$jobfile_name" ]; then
                echo "Usage: dsq-caller.sh <jobfile_name> <flags>"
                exit 1
            fi
        else
            echo "Error: Invalid argument $1" >&2 ; exit 1
        fi
        ;;
  esac
  shift
done

# If memory is not set, calculate it based on the number of cpus per task
# to maximize the number of concurrent tasks and memory usage per task
if [ -z "$mem" ]; then
    # Constants (Our personal Cluser settings)
    TOTAL_CPUS_PER_USER=128
    TOTAL_USER_MEMORY_GB=1280

    # Calculate maximum number of concurrent tasks
    MAX_TASKS=$(($TOTAL_CPUS_PER_USER / $CPUS_PER_TASK))

    # Calculate memory per task and floor the result
    TOTAL_PAR_CPUS=$(echo "scale=2; $MAX_TASKS*$CPUS_PER_TASK " | bc)
    MEMORY_PER_TASK=$(echo "scale=2; $TOTAL_USER_MEMORY_GB / $TOTAL_PAR_CPUS" | bc)
    FLOORED_MEMORY_PER_TASK=$(echo "($MEMORY_PER_TASK)/1" | bc)

    # Store the floored memory amount into a variable
    MEMORY_ALLOCATION=${FLOORED_MEMORY_PER_TASK}g

    else 
        # If memory is set, use the set value
        MEMORY_ALLOCATION=${mem}
fi

# Load the dSQ module (dead simple queue)
module load dSQ

# Submit the job to the cluster
dsq --job-file $jobfile_name --nodes=1 --tasks=$CPUS_PER_TASK --cpus-per-task=1 --mem-per-cpu=$MEMORY_ALLOCATION  --partition=$partition -t $time --submit 

# NOTE: --submit flag is used to submit the job to the cluster, if you want to test the job file without submitting it, you can remove the --submit flag
# which will create a sbatch file that you can inspect before submitting it to the cluster, via sbatch <dsq_sbatch_jobfile_name.sh>