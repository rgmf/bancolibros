#!/bin/bash

COUNT=10

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ORIGIN_DIR="$DIR/backend/bl-mariadbdata"
BACKUP_DIR="$DIR/backup"
DEST_DIR="$BACKUP_DIR/bl-mariadbdata_$(date +%Y%m%d)"

cp -rf "$ORIGIN_DIR" "$DEST_DIR"

num_copies=$(ls -1d "$BACKUP_DIR"/bl-mariadbdata_* | wc -l)
if [ "$num_copies" -ge "$COUNT" ]; then
    oldest_copy=$(ls -1rd "$BACKUP_DIR"/bl-mariadbdata_* | tail -n 1)
    rm -rf "$oldest_copy"
fi
