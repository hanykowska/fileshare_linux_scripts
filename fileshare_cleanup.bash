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

main_path="/mnt/owncloud/data"

# parent folders
medium_parent_folder="/til1/files/__Medium Storage (Data expires after 1 year)/"
hot_parent_folder="/til1/files/__Hot Storage (Data expires after 60 Days)/"
hania_test="/til1/files/__Hot Storage (Data expires after 60 Days)/Hania-test/"

# time tresholds in days
medium_time=365
hot_time=60
hania_time=5


### FIND THE FILES AND DIRECTORIES TO BE DELETED
find_and_delete_files_and_directories() {
    parent_folder=$1
    time_frame=$2

    echo "${TIMESTAMP}" 'Cleaning up ' "${parent_folder}" '...'

    files=$(while IFS= read -r -d '' file; do
                printf '%s\n' "${file}"
            done < <(find "${parent_folder}" -type f -name '*.*' -cmin +"${time_frame}" -print0))

    files_count=$(wc -l < <(echo "${files}")) #returns the number of lines, estimate of number of files
    files_word_count=$(wc -w < <(echo "${files}")) #returns the number of words, to estimate if there's at least one file

    # find directories older than X before removing old files
    old_directories=$(while IFS= read -r -d '' directory; do
                printf '%s\n' "${directory}"
            done < <(find "${parent_folder}" -type d -cmin +"${time_frame}" -print0))

    # if there are any files to be deleted, clean them up and remove now empty directories
    # use word count > 0 to check if any files were actually found 
    # (if no files are found, there will be probably on new line character in the variable, but not a word)
    if [ "${files_word_count}" -eq 0 ]; then
        echo "${TIMESTAMP}" 0 old files found, skipping...
    else
        echo "${TIMESTAMP}" "${files_count}" old files found, deleting...
        echo "${files}"
	
        while read -r file; do
	        /usr/local/bin/aws s3 cp "${file}" s3://fileshare-owncloud-hot/
	    
            # check if the file has been copied over, or if the command was successful,
            # only then remove the file
            if [ "$?" = 0 ]; then
                echo "aws command successful. Removing the file..."
                rm -f "$file"    
            else
            # otherwise exit the script
                echo "aws s3 cp command unsuccessful. Stopping..."
                exit 1
            fi
            
        done < <(echo "${files}" )

    fi

    # Check if the old directories are empty after removing the files
    # If so, remove them
    while read -r old_directory; do

        echo "old directory: ${old_directory}"
        found_directory=$(find "${old_directory}" -maxdepth 0 -empty)
        echo "empty directory: $found_directory"

        if [ "$old_directory" == "$found_directory" ]; then
            echo "The directory " "${old_directory}" " is empty, removing..."
            rm -d "${old_directory}"
            echo "Directory removed"
        else
            echo "The directory " "${old_directory}" " is not empty, skipping..."
        fi

    done < <(echo "${old_directories}")
    
}

# medium to be deleted
#find_and_delete_files_and_directories $medium_parent_folder $medium_time

# hot to be delete
# find_and_delete_files_and_directories "$hot_parent_folder" "$hot_time"

# test
find_and_delete_files_and_directories "${main_path}${hania_test}" "${hania_time}"

# add files:scan 
# use verbose for developement TODO - remove verbose once done
echo "Running fileshare file:scan..."
sudo -u www-data /usr/bin/php /var/www/owncloud/occ file:scan --path="${hot_parent_folder}" -q

echo "Done! file:scan finished with exit code " "$?"
