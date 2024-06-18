#!/bin/sh
# script for assignment 1
# Author: Jilay Pandya

#$1: filesdir: path to a directory on the filesystem
#$2: searchstr: text string to search within these files
# return with 1 and print statements if any of the parameters above were not specified

if [ -n "$1" ] && [ -n "$2" ]
    then
        if [ -d "$1" ] 
            then
                echo "$1 directory found"
                
                file_list=$(find "$1"/* -type f)
                number_of_files=$(echo "$file_list" | wc -l)
                # using awk to do pattern matching with grep and adding the second field to get the total count
                count=$( grep -c -r "$2" "$1" | awk -F: '{sum += $2} END {print sum}') 

                echo "The number of files are ${number_of_files} and the number of matching lines are ${count}"

            else
                echo "$1 does not exist"
                return 1
        fi
    else
        if [ -z "$1" ]
            then
                echo "filesdir not specified"
        fi

        if [ -z "$2" ]
            then
                echo "searchstr not specified"
        fi
    
        return 1
fi
