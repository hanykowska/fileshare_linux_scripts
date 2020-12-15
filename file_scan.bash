#!/bin/bash

/usr/bin/php /var/www/owncloud/occ files:scan --path="/til1/files/__Hot Storage (Data expires after 60 Days)" -vv
if [ "$?" = "10" ]; then
  echo "File scan was successful"
else
  echo "File scan unsuccessful"
  exit 1
fi

echo "This is the end of the script"
