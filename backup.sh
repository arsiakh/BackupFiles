#!/bin/bash

# Arsia Khorramijam, November 30th 2024 
# This script automates the setup of a backup system using cron jobs. 
# It validates user input for a backup folder and input file, sets up a cron job for regular backups, 
# and optionally runs an initial backup and manages cron jobs. 
# The script includes error handling and provides usage and help commands for user assistance.
# Function to display usage instructions


###########################
# Usage Function 
# Globals: None
# Arguments: None
# Outputs: Prints usage instructions to stderr
# Returns: N/A
###########################
usage() {
    echo "Usage: ./backup.sh <backup folder or -na> <file with folders/files to backup> " >&2
}

###########################
# Help Function
# Globals: None
# Arguments: None
# Outputs: Prints detailed help information to stdout
# Returns: N/A
###########################
help() {
    echo "Backup Script Help:"
    echo "Usage: ./backup.sh <backup folder or -na> <input .txt file> "
    echo "Arguments:"
    echo "  <backup folder or -na>: Specify a absolute path to folder for backups or use '-na' to create a default 'BACKUP' folder."
    echo "  <input file>: Absolute path to a text file listing absolute path of folders/files to back up (one per line)."
    echo "  <time interval>: Specify backup frequency as:"
    echo "    d - daily, w - weekly, m - monthly, or a number (#min) for minutes."
    echo "Example:"
    echo "  ./backup.sh -na file_list.txt"
}

###########################
# Input Validation Function
# Globals: BACKUP, INPUTFILE
# Arguments: 
#   $1 - Backup folder or -na 
#   $2 - Input text file containing absolute paths to files/folders to backup
# Outputs: Error messages to stderr if validation fails
# Returns: Exits with 1 on failure, sets BACKUP and INPUTFILE environment variables on success
###########################
validate_inputs() {
    BACKUP=$1
    INPUTFILE=$2

    if [[ $BACKUP == "--help" ]]; then #user needs directions with help utility 
        help
        exit 0
    elif [[ $BACKUP != "-na" && ! -d $BACKUP ]]; then #condition that verifies user inputs a directory or -na if they want to create one
        echo "Error: Backup folder '$BACKUP' does not exist." >&2
        usage
        exit 1
    fi
    if [[ ! -f $INPUTFILE ]]; then
        echo "Error: Input file '$INPUTFILE' does not exist." >&2 #verifying inputfile is an actual file type
        usage
        exit 1
    fi
    if [[ ! -s $INPUTFILE ]]; then
        echo "Error: Input file '$INPUTFILE' is empty." >&2 #verifying the inputfile is not empty 
        exit 1
    fi
    if [[ $BACKUP == "-na" ]]; then #condition to create directory if user inputs -na
        mkdir -p ./BACKUP
        BACKUP=$(realpath ./BACKUP) #setting absolute path to BACKUP variable
    fi

    export BACKUP INPUTFILE
}

###########################
# Cron Job Setup Function
# Globals: BACKUP, INPUTFILE
# Arguments: 
#   $1 - Time interval for backups (e.g., d, w, m, or number of minutes)
# Outputs: Adds a cron job to the user's crontab
# Returns: Exits with 1 on invalid interval
###########################
set_cron_job() {
    local interval=$1
    local script_path=$(realpath backup2.sh) #finidng absolute path to backup2 which has the actual backup functionality

    if [[ $interval == "d" ]]; then
        cron_schedule="0 2 * * * $script_path $BACKUP $INPUTFILE" # Daily cron job
    elif [[ $interval == "w" ]]; then
        cron_schedule="0 2 * * 0 $script_path $BACKUP $INPUTFILE" # Weekly cron job
    elif [[ $interval == "m" ]]; then
        cron_schedule="0 2 1 * * $script_path $BACKUP $INPUTFILE" # Monthly cron job
    elif [[ $interval =~ ^[0-9]+$ ]]; then
        cron_schedule="*/$interval * * * * $script_path $BACKUP $INPUTFILE" # Interval in minutes
    else
        echo "Invalid interval. Use 'd', 'w', 'm', or a number (#) for minutes." >&2
        exit 1
    fi
    (crontab -l 2>/dev/null; echo "$cron_schedule") | crontab - #listing cron jobs, as well as the new schedule
    echo "Cron job set up to run at the specified interval."
}

###########################
# Main Function
# Globals: None
# Arguments: Passed from command-line input
# Outputs: Interacts with the user to validate inputs, set up cron jobs, and manage backups
# Returns: N/A
###########################
main() {
    validate_inputs "$1" "$2"

    echo "Set up a cron job for daily (d), weekly (w), monthly (m), or minute (#) intervals:"
    read -r interval
    set_cron_job "$interval" #capturing interval either day, week, month or minute 

    echo "Run the initial backup now? (y/n)"
    read -r response #reading the response 
    if [[ $response =~ ^[Yy]$ ]]; then #verifies response 
        ./backup2.sh "$BACKUP" "$INPUTFILE" #sends backup directory and input file to backup2 functionality 
    fi

    echo "Do you want to terminate all cron jobs? (y/n)"
    read -r terminate
    if [[ $terminate =~ ^[Yy]$ ]]; then
        crontab -r #removes all cron jobs
        echo "All cron jobs terminated."
    fi
}

main "$@"
