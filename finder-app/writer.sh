#!/bin/sh
# script for assignment 1
# Author: Jilay Pandya

if [ -n "$1" ] && [ -n "$2" ]
    then
        mkdir -p "$(dirname "$1")" && touch "$1"
        echo "$2" > "$1"
    else
        if [ -z "$1" ]
            then
                echo "writefile not specified"
        fi

        if [ -z "$2" ]
            then
                echo "writestr not specified"
        fi
    
        exit 1
fi
