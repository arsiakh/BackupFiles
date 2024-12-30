#!/bin/bash

# Arsia Khorramijam, November 30th 2024 
# This script performs the actual backup functionality for files and directories specified in an input file.
# It verifies the validity of each item in the input file, copies it to the specified backup folder, 
# and clears the input file upon successful completion. 
# The script includes error handling for invalid items and empty lines in the input file.


###########################
# Backup Function
# Globals: None
# Arguments: 
#   $1 - Path to the backup folder
#   $2 - Path to the input file containing files/folders to back up
# Outputs: 
#   - Logs each copy operation to stdout
#   - Warnings for invalid or non-existent items in the input file
#   - Success or error messages upon completion
# Returns: Exits with 1 on error, 0 on success
###########################
backup() {
    local BACKUP=$1
    local INPUTFILE=$2

    # Ensure the backup folder exists
    if [[ ! -d "$BACKUP" ]]; then #verifies BACKUP directory user entered is of directory type 
        echo "Error: Backup folder '$BACKUP' does not exist. Creating it now."
    fi

    # Read the input file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do #sets internal field seperator to be empty to ensure it reads entire lines even seperated by spaces, -n ensures each line is read even lines w/p "\n" item
        if [[ -n "$line" ]]; then # Ensure we don't skip empty lines or lines with only spaces
            if [[ -d "$line" || -f "$line" ]]; then #verifies the inputted file / directory is of correct type
                echo "Copying $line to $BACKUP"
                cp -r "$line" "$BACKUP" #copies file to correct location
            else
                echo "Warning: $line does not exist or is invalid. Skipping."
            fi
        fi
    done < "$INPUTFILE" #ensures inputfile.txt is recieved as standard input 

    # Clear the input file after successful processing
    if [[ $? -eq 0 ]]; then 
        echo "All files copied successfully. Clearing input file."
        : > "$INPUTFILE" #clears inputfile so no copies will be made in the future
        
    else
        echo "Error occurred during file copying. Input file not cleared."
        exit 1
    fi
}

backup "$1" "$2"
