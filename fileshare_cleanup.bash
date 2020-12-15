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
hot_parent_folder="/mnt/owncloud/data/til1/files/__Hot Storage (Data expires after 60 Days)/"
hania_test="/mnt/owncloud/data/til1/files/__Hot Storage (Data expires after 60 Days)/Hania-test/"

# time tresholds in days
medium_time=365
hot_time=60
hania_time=20


### FIND THE FILES AND DIRECTORIES TO BE DELETED
find_and_delete_files_and_directories() {
    parent_folder=$1
    time_frame=$2

    echo "${TIMESTAMP}" 'Cleaning up ' "${parent_folder}" '...'

    files=$(while IFS= read -r -d '' file; do
                printf '%s\n' "${file}"
            done < <(find "${parent_folder}" -type f -name '*.*' -cmin +"${time_frame}" -print0))
    files_count=$(wc -l < <(echo "${files}")) #returns the number of lines, equal to the number of files

    

    # if there are any files to be deleted, clean them up and remove now empty directories
    if [ "${files_count}" -eq 0 ]; then
        echo "${TIMESTAMP}" "${files_count}" old files found, skipping...
    else
        echo "${TIMESTAMP}" "${files_count}" old files found, deleting...
        echo "${files}"
	echo "............."
	
        while read -r file; do
            echo "${file}"
            echo "............"
	    /usr/local/bin/aws s3 cp "${file}" s3://fileshare-owncloud-hot/
	    echo "aws command done ............"
	    echo "${file}"
            # check if the file has been copied over, or if the command was successful,
            # only then remove the file
            if [ "$?" = 0 ]; then
                rm -f "$file"
            else
            # otherwise exit the script
                echo "aws s3 cp command unsuccessful. Stopping"
                exit 1
            fi
            
            # $(rm -f "$file")
        done < <(echo "${files}" )

        # find directories older than X and empty after removing old files
        directories=$(while IFS= read -r -d '' directory; do
                    printf '%s\n' "${directory}"
                done < <(find "${parent_folder}" -type d -empty -cmin +"${time_frame}" -print0))
        
        while read -r directory; do
            echo "${directory}"
            rm -d "${directory}"
	    echo "Directory removed....."
        done < <(echo "${directories}")
    fi
}

# medium to be deleted
#find_and_delete_files_and_directories $medium_parent_folder $medium_time

# hot to be delete
# find_and_delete_files_and_directories "$hot_parent_folder" "$hot_time"

# test
find_and_delete_files_and_directories "${hania_test}" "${hania_time}"

# add files:scan 
# use verbose for developement TODO - remove verbose once done
sudo -u www-data /usr/bin/php /var/www/owncloud/occ file:scan --path="/til1/files/__Hot Storage (Data expires after 60 Days)" -q
