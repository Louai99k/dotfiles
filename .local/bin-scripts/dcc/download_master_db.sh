#!/bin/env bash

set -e

BASE_PATH="/home/luay/me/childcare/_childcare/database-docker/pgadmin/storage/admin_admin.com"
FILE_NAME=""

while getopts "df:" opt; do
  case $opt in
    d)
      rm "$BASE_PATH"/master_dump_*
      ;;
    f)
      FILE_NAME="$OPTARG"
      ;;
    \?)
      echo "Invalid option"
      exit 1
      ;;
  esac
done

if [[ -z "$FILE_NAME" ]]; then
  FILE_NAME=$(date +"%Y%m%d")
fi


aws s3 cp \
  s3://mdc-db-dumps/ \
  "$BASE_PATH"/ \
  --recursive \
  --exclude "*" \
  --include "*master_dump_$FILE_NAME*"
