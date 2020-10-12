#!/bin/bash
# Test script to check the looping through files works correctly
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

# time tresholds in days
medium_time=365
hot_time=60


### FIND THE FILES AND DIRECTORIES TO BE DELETED
find_and_list_files_and_directories() {
    parent_folder=$1
    time_frame=$2

    echo "$TIMESTAMP" "Cleaning up ${parent_folder}..."

    files=$(while IFS= read -r -d '' file; do
                printf '%s\n' "$file"
            done < <(find "${parent_folder}" -type f -mtime +"${time_frame}" -name '*.*' -print0))
    files_count=$(wc -l < <(echo "$files")) #returns the number of lines, equal to the number of files

    directories=$(while IFS= read -r -d '' directory; do
                    printf '%s\n' "$directory"
                done < <(find "${parent_folder}" -type d -mtime +"${time_frame}" -name '*.*' -print0))

    # if there are any files to be deleted, clean them up and remove now empty directories
    if [ $files_count -eq 0 ]; then
        echo "$TIMESTAMP" $files_count old files found, skipping...
    else
        echo "$TIMESTAMP" $files_count old files found, deleting...
        while read -r file; do
            echo "$file" ";;;"
        done < <(echo "$files" )
        
        while read -r directory; do
            echo "$directory" ";;;"
        done < <(echo "$directories")
    fi
}

# medium to be liste
find_and_list_files_and_directories $medium_parent_folder $medium_time

# hot to be listed
find_and_list_files_and_directories $hot_parent_folder $hot_time


# add files:scan 
#$(php )