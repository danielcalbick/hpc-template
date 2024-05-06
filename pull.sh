#!/bin/zsh

# This script is used to pull the output of the jobs from the cluster to the local machine.
# It uses rsync to copy the files from the cluster

# Replace the username, cluster ip, and the path to your own.
USER=dc938
CLUSTER_IP=misha.ycrc.yale.edu
CLUSTER_PATH=/gpfs/radev/project/yildirim/dc938/hpc-template/hpc-outputs

caffeinate rsync -avhP \
    --exclude='.*' \
    --exclude='dir_name/' \
    --exclude='file_name.txt' \
    $USER@$CLUSTER_IP:$CLUSTER_PATH .

# caffeinate is used to prevent the computer from sleeping while the files are being copied.
# -acvhP are flags for rsync to archive, compress, verbose, human-readable, and show progress.

# The exclude lines (--exclude='...') tell rsync what not to copy over, here,
# --exclude='.*' says don't copy hidden directories or files
# --exclude='dir_name/' says don't copy the directory named dir_name
# --exclude='file_name.txt' says don't copy the file named file_name.txt