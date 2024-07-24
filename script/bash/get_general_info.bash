#!/bin/bash
# ########################################################
#  Name:        get_general_info.bash
#  Version:     0.1
#  Author:      Pavol Kluka
#  Date:        2024/06/25
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
                echo "[ERROR] Script variable $VAR is empty."
                exit 1
	    elif [[ $VAR == *"BIN_"* ]]
            then
	        echo "[ERROR] Missing tool: $VAR."
                exit 1
            elif [[ $VAR == *"DATE_"* ]]
	    then
		echo "[ERROR] Date variable $VAR is empty."
                exit 1
            elif [[ $VAR == *"DIR_"* ]]
            then
                echo "[ERROR] Directory variable $VAR is empty."
                exit 1
            else
                echo "[FATAL] Even the doe is completely clueless about what's going on."
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
		echo "[INFO] Folder $ARG1 exist."
	else
		echo "[INFO] Folder $ARG1 doesn't exist. Folder was created."
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

# PRINT USAGE INSTRUCTIONS
function script_usage() {
    echo "Usage: $0 -i <input_file>"
    echo "       $0 --input-file <input_file>"
    echo "  -i, --input-file   Specify the input file."
    exit 1
}

# CHECK IF THE SCRIPT RECEIVED AN ARGUMENT
if [ "$#" -eq 0 ]
then
    script_usage
    exit 1
fi

# SCRIPT VARIABLES
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# BIN VARIABLES
BIN_CAT="$( which cat )"
BIN_GREP="$( which grep )"
BIN_AWK="$( which awk )"
BIN_SED="$( which sed )"
BIN_TEE="$( which tee )"
BIN_MKDIR="$( which mkdir )"
BIN_CP="$( which cp )"
BIN_RM="$( which rm )"
BIN_LS="$( which ls )"
BIN_SORT="$( which sort )"
BIN_TAIL="$( which tail )"
BIN_WC="$( which wc )"
BIN_TR="$( which tr )"
BIN_MALWOVERVIEW="$( which malwoverview.py )"
BIN_OLEDUMP="$( which oledump.py )"
BIN_ZIPDUMP="$( which zipdump.py )"
BIN_EXIFTOOL="$( which exiftool )"
BIN_MKTEMP="$( which mktemp )"
BIN_PORTEX="$( which portex )"
BIN_STRINGS="$( which strings )"

# DATE VARIABLES
DATE_SHORT="$( date +"%Y-%m-%d" )"
DATE_LONG="$( date +"%Y-%m-%d %H:%M" )"

# PARSE COMMAND LINE ARGUMENT
while [[ "$#" -gt 0 ]]
do
    case $1 in
        -i|--input-file)
            SCRIPT_ARG="$2"
            SCRIPT_ARG_FILE="$( echo $SCRIPT_ARG | awk -F '/' '{ print $NF }' )"
            shift 2
            ;;
        *)
            script_usage
            ;;
    esac
done

# CHECK IF THE INPUT FILE IS SET
if [ -z "$SCRIPT_ARG" ]; then
    script_usage
fi

# CHECK IF THE FILE EXISTS
if [ ! -e "$SCRIPT_ARG" ]
then
    echo "[ERROR] File does not exist."
    script_usage
    exit 1
fi

# PATH VARIABLES
PATH_FILE="$( readlink -f "$SCRIPT_ARG" )"
PATH_DIR="$( dirname $PATH_FILE | sed -E 's?/artifacts|/malicious|/output??g' )"
PATH_ANALYSIS_DIR="$( pwd )"

# DIR VARIABLES
DIR_ARTIFACTS="$PATH_ANALYSIS_DIR/artifacts"
DIR_MALICIOUS="$PATH_ANALYSIS_DIR/malicious"
DIR_OUTPUT="$PATH_ANALYSIS_DIR/output"

# CHECK DECLARED SCRIPT VARIABLES
check_empty_variables

# CHECK WORKING DIRECTORIES
check_working_directory $DIR_ARTIFACTS
check_working_directory $DIR_MALICIOUS
check_working_directory $DIR_OUTPUT

# COUNTER FOR OUTPUT FILES
# ls output/|sort|tail -1|grep -oP '^[0-9]{3}'|tr -d '0'
if [ -z "$( $BIN_LS $DIR_OUTPUT )" ]
then
    echo "[INFO] Counter for output files is 1."
    COUNTER=1
else
    TEMP_COUNTER=$( $BIN_LS $DIR_OUTPUT | $BIN_SORT | $BIN_TAIL -1 | $BIN_GREP -oP '^[0-9]{3}' | $BIN_SED 's/^0*//' )
    COUNTER=$((TEMP_COUNTER+1))
    echo "[INFO] Counter for output files is $COUNTER."
fi

# 001 HASH
echo -e "\n[INFO] Get Hash:"
for SUM in md5sum sha1sum sha256sum
do
    $SUM --tag $PATH_FILE
done > $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-hash.txt
echo "[INFO] Hash of the file $SCRIPT_ARG_FILE is saved to the output file: $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-hash.txt"
COUNTER=$((COUNTER+1))

# 002 EXIFTOOL
echo -e "\n[INFO] Exiftool:"
$BIN_EXIFTOOL $PATH_FILE > $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-exiftool.txt
echo "[INFO] Output from Exiftool of the file $SCRIPT_ARG_FILE is saved to the output file: $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-exiftool.txt"
COUNTER=$((COUNTER+1))

# 003 MALWOVERVIEW
SCRIPT_ARG_FILE_HASH=$( $BIN_GREP 'SHA256' $DIR_OUTPUT/*-$SCRIPT_ARG_FILE-hash.txt | $BIN_GREP -oP '[a-fA-F0-9]{64}$' )
echo -e "\n[INFO] Malwoverview: Virustotal"
FILE_TEMP=$( $BIN_MKTEMP )
$BIN_MALWOVERVIEW -v 8 -V $SCRIPT_ARG_FILE_HASH > $FILE_TEMP
$BIN_CAT $FILE_TEMP | $BIN_SED -e "s/\x1B[^m]*m//g" > $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-virustotal.txt
echo "[INFO] Output from Malwoverview (Virustotal) is saved to the output file: $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-virustotal.txt"
$BIN_RM -rf $FILE_TEMP
COUNTER=$((COUNTER+1))
echo -e "\n[INFO] Malwoverview: Tria.ge"
FILE_TEMP=$( $BIN_MKTEMP )
$BIN_MALWOVERVIEW -x 1 -X $SCRIPT_ARG_FILE_HASH > $FILE_TEMP
$BIN_CAT $FILE_TEMP | $BIN_SED -e "s/\x1B[^m]*m//g" > $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-triage.txt
echo "[INFO] Output from Malwoverview (Tria.ge) is saved to the output file: $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-triage.txt"
$BIN_RM -rf $FILE_TEMP
TEMP_TRIAGE_ID="$($BIN_GREP -oP 'id:\s+\K[0-9a-zA-Z-]+' $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-triage.txt )"
COUNTER=$((COUNTER+1))
FILE_TEMP=$( $BIN_MKTEMP )
if [ -n "$TEMP_TRIAGE_ID" ]
then
    COUNT_TEMP=1
    while IFS= read -r ID
    do
        malwoverview.py -x 2 -X $ID > $FILE_TEMP
        $BIN_CAT $FILE_TEMP | $BIN_SED -e "s/\x1B[^m]*m//g" > $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-triage-$ID.txt
        echo "[INFO] Report from Malwoverview (Tria.ge) for ID: $ID is saved to the output file: $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-triage-$ID.txt"
        COUNTER=$((COUNTER+1))
        malwoverview.py -x 7 -X $ID > $FILE_TEMP
        $BIN_CAT $FILE_TEMP | $BIN_SED -e "s/\x1B[^m]*m//g" > $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-triage-$ID-dynamic.txt
        echo "[INFO] Dynamic Report from Malwoverview (Tria.ge) for ID: $ID is saved to the output file: $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-triage-$ID-dynamic.txt"
        COUNTER=$((COUNTER+1))
        COUNT_TEMP=$((COUNT_TEMP+1))
    done <<< "$TEMP_TRIAGE_ID"
else
    echo "[INFO] No reports found for the file: $SCRIPT_ARG_FILE in tria.ge."
fi
$BIN_RM -rf $FILE_TEMP
echo -e "\n[INFO] Malwoverview: AlienVault"
FILE_TEMP=$( $BIN_MKTEMP )
$BIN_MALWOVERVIEW -n 4 -N $SCRIPT_ARG_FILE_HASH -o 0 > $FILE_TEMP
$BIN_CAT $FILE_TEMP | $BIN_SED -e "s/\x1B[^m]*m//g" > $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-alientvault.txt
echo "[INFO] Output from Malwoverview (AlienVault) is saved to the output file: $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-alientvault.txt"
$BIN_RM -rf $FILE_TEMP
COUNTER=$((COUNTER+1))
FILE_TEMP=$( $BIN_MKTEMP )
$BIN_MALWOVERVIEW -b 1 -B $SCRIPT_ARG_FILE_HASH > $FILE_TEMP
$BIN_CAT $FILE_TEMP | $BIN_SED -e "s/\x1B[^m]*m//g" > $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-alienvault-bazaar.txt
echo "[INFO] Output from Malwoverview (AlientVault: Malware Bazaar) is saved to the output file: $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-malw-alienvault-bazaar.txt"
$BIN_RM -rf $FILE_TEMP
COUNTER=$((COUNTER+1))

# 004 PORTEXANALYZER
echo -e "\n[INFO] PortEx Analyzer:"
$BIN_PORTEX -o $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-portex.txt $PATH_FILE
echo "[INFO] Output from PortEx Analyzer of the file $SCRIPT_ARG_FILE is saved to the output file: $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-portex.txt"
COUNTER=$((COUNTER+1))

# 005 STRINGS
echo -e "\n[INFO] strings:"
$BIN_STRINGS $PATH_FILE > $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-strings.txt
echo "[INFO] Output from PortEx Analyzer of the file $SCRIPT_ARG_FILE is saved to the output file: $DIR_OUTPUT/$( format_counter $COUNTER )-$SCRIPT_ARG_FILE-portex.txt"
COUNTER=$((COUNTER+1))

exit 0
