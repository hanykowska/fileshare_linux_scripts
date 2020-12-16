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
hania_time=60


### FIND THE FILES AND DIRECTORIES TO BE DELETED
find_and_delete_files_and_directories() {
    parent_folder=$1
    time_frame=$2

    echo "${TIMESTAMP}" 'Cleaning up ' "${parent_folder}" '...'

    files=$(while IFS= read -r -d '' file; do
                printf '%s\n' "${file}"
            done < <(find "${parent_folder}" -type f -name '*.*' -cmin +"${time_frame}" -print0))
    echo "original files list:"
    echo "${files}"

    files_count=$(wc -l < <(echo "${files}")) #returns the number of lines, estimate of number of files
    files_word_count=$(wc -w < <(echo "${files}")) #returns the number of words, to estimate if there's at least one file

    

    # if there are any files to be deleted, clean them up and remove now empty directories
    # use word count > 0 to check if any files were actually found 
    # (if no files are found, there will be probably on new line character in the variable)
    if [ "${files_word_count}" -eq 0 ]; then
        echo "${TIMESTAMP}" 0 old files found, skipping...
    else
        echo "${TIMESTAMP}" "${files_count}" old files found, deleting...
        echo "${files}"
	echo "............."
	
        while read -r file; do
            echo "${file}"
            echo "............"
	    #/usr/local/bin/aws s3 cp "${file}" s3://fileshare-owncloud-hot/
	    #echo "aws command done ............"
	    echo "${file}"
            # check if the file has been copied over, or if the command was successful,
            # only then remove the file
            if [ "$?" = 0 ]; then
                echo "aws command successful"
                #rm -f "$file"    
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

        directories_word_count=$(wc -w < <(echo "${directories}"))
        if [ "${directories_word_count}" -eq 0 ]; then
            echo "${TIMESTAMP}" 0 old empty directories found, skipping...
        else
            echo "${TIMESTAMP}" some old empty directories found, deleting...

            while read -r directory; do
                echo "${directory}"
                #rm -d "${directory}"
            #echo "Directory removed....."
            done < <(echo "${directories}")
        fi
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
