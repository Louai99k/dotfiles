#!/bin/env bash

set -e

BASE_PATH="/home/luay/me/childcare/_childcare/database-docker/pgadmin/storage/admin_admin.com"

while getopts "d" opt; do
  case $opt in
    d)
      rm "$BASE_PATH"/master_dump_*
      ;;
    \?)
      echo "Invalid option"
      exit 1
      ;;
  esac
done

FILE_NAME=$(date +"%Y%m%d")

aws s3 cp \
  s3://mdc-db-dumps/ \
  "$BASE_PATH"/ \
  --recursive \
  --exclude "*" \
  --include "*master_dump_$FILE_NAME*"
