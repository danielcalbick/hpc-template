#!/bin/zsh

# This script is used to sync your local directory with the cluster.
# It uses rsync to copy the files from this directory to your project directory on the cluster

# Replace the username, cluster ip, and the path to your own.
USER=dc938
CLUSTER_IP=misha.ycrc.yale.edu
CLUSTER_PROJECT_PATH=/gpfs/radev/project/yildirim/dc938/hpc-template

caffeinate rsync -acvhP \
 --exclude='hpc-outputs/'\
 --exclude='.*'\
 --exclude='figures/*' \
 --exclude='archive/'\
 --exclude={'pull.sh','sync.sh'} \
. $CLUSTER_IP@$CLUSTER_IP:$CLUSTER_PROJECT_PATH


# Anatomy of the rsync command:
# caffeinate rsync -avh --progress \ 
#               caffeinate is used to prevent the computer from sleeping while the files are being copied
#               -acvhP are flags for rsync to archive, compress, verbose, human-readable, and show progress.
#  --exclude='dir_name/' says don't copy the directory named dir_name
#  --exclude='.*' says don't copy hidden directories or files
#  --exclude='figures/*' says don't copy the files in the figures directory
#  --exclude={'pull.sh','sync.sh'} says don't copy the files named pull.sh and sync.sh
#
# the last two arguments are the source and destination directories respectively.
# . $CLUSTER_IP@$CLUSTER_IP:$CLUSTER_PROJECT_PATH 