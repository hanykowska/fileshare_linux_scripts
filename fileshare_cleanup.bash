#!/bin/bash
# Maintenance script for cleaning up old files on fileshare
# Files in Medium Storage   of 1 year or older
# Files in Hot Storage      of 60 days or older
# Originally created by Hanna Nykowska @ The Information Lab

### HOW TO USE THIS SCRIPT ###
#
#
#


### VARIABLES SECTION
# set the variables to match your requirements

TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`

# parent folders
medium_parent_folder="/mnt/owncloud/data/til1/files/__Medium Storage (Data expires after 1 year)/"
hot_parent_folder="/mnt/owncloud/data/til1/files/__Hot Storage (Data expires after 60 days)/"

# time tresholds
medium_time=365
hot_time=60


### FIND THE FILES AND DIRECTORIES TO BE DELETED
find_and_delete_files_and_directories() {
    parent_folder=$1
    time_frame=$2

    echo $TIMESTAMP 'Cleaning up ${parent_folder}...'

    files=$(find "$parent_folder" -type f -mtime +${time_frame})
    files_count=$(wc ) #figure out how to get the word count from a variable
    directories=$(find "$parent_folder" -type d -mtime +${time_frame})

    # TODO fix this 
    if [ $files_count -eq 0 ]; then
        echo $TIMESTAMP $files_count old files found, skipping...
    else
        echo $TIMESTAMP $files_count old files found, deleting...
        for file in $files
            do
                $(aws s3 mv "$file" s3://fileshare-owncloud-hot/)
            done
            
        for directory in $directories
            do
                $(rmdir $directory --ignore-fail-on-non-empty)
            done
    fi
}

# medium to be deleted
find_and_delete_files_and_directories medium_parent_folder medium_time

# hot to be delete
find_and_delete_files_and_directories hot_parent_folder hot_time
