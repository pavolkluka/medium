#!/bin/bash
# ########################################################
#  Name:        get_general_info.bash
#  Version:     0.1
#  Author:      Pavol Kluka
#  Date:        2024/06/25
#  Platforms:   Linux
# ########################################################

# Function to check if declared variables are empty
function check_empty_variables() {
    # List all the variables declared in the script
    local VARS="$( set -o posix; set | grep -E 'SCRIPT_.*=|^BIN_.*=|^DATE_.*=|^DIR_.*=' | cut -d'=' -f1 )"

    for VAR in $VARS
    do
        # Use indirect expansion to get the value of the variable
        local VALUE="${!VAR}"

        if [ -z "$VALUE" ]
        then
            echo "Variable '$VAR' is empty."
            exit 1
        fi
    done
}

# CHECK IF EXIST WORK FOLDER
function check_working_directory() {
	ARG1="$1"
	if [ -d "$ARG1" ]
	then
		echo "Folder $ARG1 exist."
	else
		echo "Folder $ARG1 doesn't exist. Folder was created."
		mkdir -p $ARG1 > /dev/null
	fi
}

# CHECK IF THE SCRIPT RECEIVED AN ARGUMENT
if [ $# -eq 0 ]
then
    echo "Usage: $0 filename"
    exit 1
fi

# SCRIPT VARIABLES
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_ARG="$1"

# BIN VARIABLES
BIN_CAT="$( which cat )"
BIN_GREP="$( which grep )"
BIN_TEE="$( which tee )"
BIN_MKDIR="$( which mkdir )"
BIN_CP="$( which cp )"
BIN_MALW="$( which malwoverview.py )"
BIN_OLEDUMP="$( which oledump.py )"
BIN_ZIPDUMP="$( which zipdump.py )"
BIN_EXIFTOOL="$( which exiftool )"

# DATE VARIABLES
DATE_SHORT="$( date +"%Y-%m-%d" )"
DATE_LONG="$( date +"%Y-%m-%d %H:%M" )"

# CHECK IF THE FILE EXISTS
if [ ! -e "$SCRIPT_ARG" ]
then
    echo "File does not exist."
    exit 1
fi

# PATH VARIABLES
PATH_FILE="$( readlink -f "$SCRIPT_ARG" )"
PATH_DIR="$( dirname $PATH_FILE | sed -E 's?/artifacts|/malicious|/output??g' )"

# DIR VARIABLES
DIR_ARTIFACTS="$PATH_DIR/artifacts"
DIR_MALICIOUS="$PATH_DIR/malicious"
DIR_OUTPUT="$PATH_DIR/output"

# CHECK DECLARED SCRIPT VARIABLES
check_empty_variables

# CHECK WORKING DIRECTORIES
check_working_directory $DIR_ARTIFACTS
check_working_directory $DIR_MALICIOUS
check_working_directory $DIR_OUTPUT

exit 0
