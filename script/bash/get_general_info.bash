#!/bin/bash
# ########################################################
#  Name:        get_general_info.bash
#  Version:     0.1
#  Author:      Pavol Kluka
#  Create Date: 2024/06/25
#  Platforms:   Linux
# ########################################################

# FUNCTION TO CHECK IF DECLARED VARIABLES ARE EMPTY
function check_empty_variables() {
    # List all the variables declared in the script
    local VARS="$( set -o posix; set | grep -E 'SCRIPT_.*=|^BIN_.*=|^DATE_.*=|^DIR_.*=' | cut -d'=' -f1 )"

    for VAR in $VARS
    do
        local VALUE="${!VAR}"

        if [ -z "$VALUE" ]
        then
            if [[ $VAR == *"SCRIPT_"* ]]
            then
                echo "Script variable $VAR is empty."
                exit 1
	    elif [[ $VAR == *"BIN_"* ]]
            then
	        echo "Missing tool: $VAR."
                exit 1
            elif [[ $VAR == *"DATE_"* ]]
	    then
		echo "Date variable $VAR is empty."
                exit 1
            elif [[ $VAR == *"DIR_"* ]]
            then
                echo "Directory variable $VAR is empty."
                exit 1
            else
                echo "Even the doe is completely clueless about what's going on."
                exit 1
            fi
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

# FUNCTION TO FORMAT THE COUNTER WITH LEADING ZEROS
function format_counter() {
    NUMBER=$1
    if [[ $NUMBER -lt 10 ]]
    then
        echo "00$NUMBER"
    elif [[ $NUMBER -lt 100 ]]
    then
        echo "0$NUMBER"
    else
        echo "$NUMBER"
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
SCRIPT_ARG_FILE="$( echo $SCRIPT_ARG | awk -F '/' '{ print $NF }' )"

# BIN VARIABLES
BIN_CAT="$( which cat )"
BIN_GREP="$( which grep )"
BIN_AWK="$( which awk )"
BIN_SED="$( which sed )"
BIN_TEE="$( which tee )"
BIN_MKDIR="$( which mkdir )"
BIN_CP="$( which cp )"
BIN_RM="$( which rm )"
BIN_MALWOVERVIEW="$( which malwoverview.py )"
BIN_OLEDUMP="$( which oledump.py )"
BIN_ZIPDUMP="$( which zipdump.py )"
BIN_EXIFTOOL="$( which exiftool )"
BIN_MKTEMP="$( which mktemp )"

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

# COUNTER FOR OUTPUT FILES
COUNTER=1

# 001 HASH
echo -e "\nHash:"
for SUM in md5sum sha1sum sha256sum
do
    $SUM --tag $PATH_FILE
done | $BIN_TEE $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-hash.txt

COUNTER=$((COUNTER+1))

# 002 EXIFTOOL
echo -e "\nExiftool:"
$BIN_EXIFTOOL $PATH_FILE | $BIN_TEE $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-exiftool.txt
COUNTER=$((COUNTER+1))

# 003 MALWOVERVIEW
SCRIPT_ARG_FILE_HASH=$( $BIN_GREP 'SHA256' $DIR_OUTPUT/*-hash.txt | $BIN_GREP -oP '[a-fA-F0-9]{64}$' )
echo -e "\nMalwoverview: Virustotal"
FILE_TEMP=$( $BIN_MKTEMP )
$BIN_MALWOVERVIEW -v 8 -V $SCRIPT_ARG_FILE_HASH |  $BIN_TEE $FILE_TEMP
$BIN_CAT $FILE_TEMP | $BIN_SED -e "s/\x1B[^m]*m//g" | $BIN_TEE $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-virustotal.txt
$BIN_RM -rf $FILE_TEMP
COUNTER=$((COUNTER+1))
echo -e "\nMalwoverview: Tria.ge"
FILE_TEMP=$( $BIN_MKTEMP )
$BIN_MALWOVERVIEW -x 1 -X $SCRIPT_ARG_FILE_HASH | $BIN_TEE $FILE_TEMP
$BIN_CAT $FILE_TEMP | $BIN_SED -e "s/\x1B[^m]*m//g" | $BIN_TEE $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-triage.txt
$BIN_RM -rf $FILE_TEMP
COUNTER=$((COUNTER+1))
echo -e "\nMalwoverview: AlienVault"
FILE_TEMP=$( $BIN_MKTEMP )
$BIN_MALWOVERVIEW -n 4 -N $SCRIPT_ARG_FILE_HASH -o 0 | $BIN_TEE $FILE_TEMP
$BIN_CAT $FILE_TEMP | $BIN_SED -e "s/\x1B[^m]*m//g" | $BIN_TEE $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-alientvault.txt
$BIN_RM -rf $FILE_TEMP
COUNTER=$((COUNTER+1))
FILE_TEMP=$( $BIN_MKTEMP )
$BIN_MALWOVERVIEW -b 1 -B $SCRIPT_ARG_FILE_HASH | $BIN_TEE $FILE_TEMP
$BIN_CAT $FILE_TEMP | $BIN_SED -e "s/\x1B[^m]*m//g" | $BIN_TEE $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-alienvault-bazaar.txt
$BIN_RM -rf $FILE_TEMP
COUNTER=$((COUNTER+1))

exit 0
