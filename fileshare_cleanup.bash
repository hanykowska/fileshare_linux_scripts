#!/bin/bash
# Maintenance script for cleaning up old files on fileshare
# Files in Medium Storage   of 1 year or older
# Files in Hot Storage      of 60 days or older
# Originally created by Hanna Nykowska @ The Information Lab

### HOW TO USE THIS SCRIPT ###
# find_and_delete_files_and_directories function finds any files and directories
# changed earlier than specified time ago. It first deletes the files and of the directories
# that are empty after removal of old files.
# The location to check, length of the period and the unit of the period can be passed as parameters
# 
# The script runs the above check for hot and medium storage, but could have more folders added.
# Each with its own time length constraints.


### VARIABLES SECTION
# set the variables to match your requirements

main_path="/mnt/owncloud/data"

# parent folders
medium_parent_folder="/til1/files/__Medium Storage (Data expires after 1 year)/"
hot_parent_folder="/til1/files/__Hot Storage (Data expires after 60 Days)/"

# time tresholds in days
medium_time=365
hot_time=60


### FIND THE FILES AND DIRECTORIES TO BE DELETED - FUNCTION DEFINITION
find_and_delete_files_and_directories() {
    parent_folder=$1
    time_length=$2
    time_frame=${3:-time}
    TIMESTAMP=`date '+%Y-%m-%d %H:%M:%S'`

    echo "${TIMESTAMP}" 'Cleaning up ' "${parent_folder}"

    # Find files older than time_length in time_frame units
    files=$(find "${parent_folder}" -type f -name '*.*' -c${time_frame} +"${time_length}")
    files_count=$(wc -l < <(echo "${files}")) #returns the number of lines, estimate of number of files
    files_word_count=$(wc -w < <(echo "${files}")) #returns the number of words, to estimate if there's at least one file

    # find directories older than X before removing old files
    old_directories=$(find "${parent_folder}" -type d -c${time_frame} +"${time_length}")
    directories_word_count=$(wc -w < <(echo "${old_directories}")) #returns the number of words, to estimate if there's at least one file

    # if there are any files to be deleted, clean them up and remove now empty directories
    # use word count > 0 to check if any files were actually found 
    # (if no files are found, there will be probably on new line character in the variable, but not a word)
    if [ "${files_word_count}" -eq 0 ]; then
        echo No old files found, skipping...
    else
        echo "${files_count}" old files found, deleting...
	
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


    # Check if there are any old directories
    if [ "${directories_word_count}" -eq 0 ]; then
        echo No old directories found, skipping...
    else
        echo "Old directories found, checking if they are empty..."

        # Check if the old directories are empty after removing the files
        # If so, remove them
        while read -r old_directory; do

            # If the directory to be checked is the same as parent folder, skip it
            if [ "$old_directory" == "${parent_folder}" ]; then
                echo "This is the parent folder, skipping..."
            else

                # Check if the directory is empty, then remove it
                found_directory=$(find "${old_directory}" -maxdepth 0 -empty)
                if [ "$old_directory" == "$found_directory" ]; then

                    echo "The directory " "${old_directory}" " is empty, removing..."
                    rm -d "${old_directory}"
                    echo "Directory removed"

                # If it's not empty, skip it
                else
                    echo "The directory " "${old_directory}" " is not empty, skipping..."
                fi
            fi

        done < <(tac <<< "${old_directories}") # feed the list of directories in reversed order
    fi
    
}


### RUN THE CLEAN UP
# medium to be deleted
find_and_delete_files_and_directories "${main_path}${medium_parent_folder}" "${medium_time}" "time"

# hot to be delete
find_and_delete_files_and_directories "${main_path}${hot_parent_folder}" "${hot_time}" "time"


### SCAN FILES ON FILESHARE TO UPDATE THE WEB BROWSER
# add files:scan 
echo "Running fileshare file:scan for hot storage..."
sudo -u www-data /usr/bin/php /var/www/owncloud/occ file:scan --path="${hot_parent_folder}" -q
echo "Done! file:scan finished with exit code " "$?"

echo "Running fileshare file:scan for medium storage..."
sudo -u www-data /usr/bin/php /var/www/owncloud/occ file:scan --path="${medium_parent_folder}" -q
echo "Done! file:scan finished with exit code " "$?"
