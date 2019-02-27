#!/bin/bash

# Script requires cutycapt and xvfb.

# delete existing files older than 5 minutes & with name .cutycapt. in it
# value 0 disables feature
EXPIRES=5

# ---------------------------------------------------------------------------

INPUT_FILE=""
OUT_DIR=""

# this function will validate command line arguments
# there should be total of two arguments
# usage: tavianz.sh <input-file> <output-directory>
function argument_validation(){
if [ "$#" -gt 2 ]; then
    echo "un-necessary arguments provided, exiting"
    echo "usage: " $0 "<input-file> <output-directory>"
    exit
elif [ "$#" -lt 2 ]; then
    echo "in-sufficient arguments provided, exiting"
    echo "usage: " $0 "<input-file> <output-directory>"
    exit
fi
}

# this function validate the existence of input file
# the input file should be a text file e.g example.txt
function input_file_existence_validation(){
    flag=0
    if [ -e "$INPUT_FILE" ] && [ -f "$INPUT_FILE" ]; then
       # filename=$(basename -- $INPUT_FILE)
       # ext="${filename##*.}"
       # if [ $ext = "txt" ]; then
            flag=1
       # fi
    fi
    if [ $flag -eq 1 ]; then
        echo "input file is valid"
    else
        echo "input file is invalid, exiting..."
        exit
    fi
}

# this function validate the existence of output directory
# if the directory do not exists, it will create the directory
function output_file_existence_validation(){
    if [ -e "$OUT_DIR" ] && [ -d "$OUT_DIR" ]; then
        echo "output directory exists..."
    else
        echo "output directory do not exists, creating..."
        $(mkdir -p "$OUT_DIR")
        echo $OUT_DIR "is created"
    fi
}

# functions which will eventually execute the main function
# reads input file line by line
# separate values from line
# check network connectivity and execute the operation
function execute(){

    re='^[0-9]+$'
    while IFS='' read -r line || [[ -n "$line" ]]; do
        res=$(echo $line | sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d')
        if [ ${#res} -gt 0 ]; then
            filename=$(cut -d',' -f1 <<< $res)
		filename=$(echo $filename) # removes leading and trailing white spaces
            ext=$(cut -d',' -f2 <<< $res)
		ext=$(echo $ext)
            ext="${ext,,}"
            dur=$(cut -d',' -f3 <<< $res)
		dur=$(echo $dur)
            url=$(cut -d',' -f4 <<< $res)
		url=$(echo $url)
            if ! [[ $dur =~ $re ]]; then
                echo "wrong duration " $dur
                echo "ignoring file-name: " $filename " extension: " $ext " duration: " $dur " url: " $url
            elif ! [ $ext = "png" ] && ! [ $ext = "jpg" ] && ! [ $ext = "bmp" ] && ! [ $ext = "tif" ]; then
                echo "image format not supported " $ext
                echo "ignoring file-name: " $filename " extension: " $ext " duration: " $dur " url: " $url
            else
                cTesting=${url#"https://"}
                cTesting=${cTesting#"http://"}
                if nc -z -w 10 $cTesting 80 443 >/dev/null; then
                    echo "processing file-name: " $filename " extension: " $ext " duration: " $dur " url: " $url
                    xvfb-run --server-args="-screen 0, 1920x1080x24" cutycapt --min-width=1920 --min-height=1080 --url="$url" --out="${OUT_DIR}/$filename.cutycapt.$dur.$ext"
                else
                    echo "connection is down!"
                    echo "ignoring file-name: " $filename " extension: " $ext " duration: " $dur " url: " $url
                fi
            fi
        fi
    done < "$INPUT_FILE"

    # deleting existing files with duration greater than EXPIRES minutes & with string .cutycapt. in it
    if [ $EXPIRES -qt 0 ]; then
    	echo "removing files older than $EXPIRES minutes"
    	find "$OUT_DIR" -maxdepth 1 -mmin +${EXPIRES} -type f -name '*.cutycapt.*' -delete
    fi	
}

#calling argument validation
argument_validation "$@"

INPUT_FILE=$1
OUT_DIR=$2

# validating input and output file
input_file_existence_validation
output_file_existence_validation

echo "input file path: $INPUT_FILE"
echo "output directory path: $OUT_DIR"

# executing the main operation
execute
