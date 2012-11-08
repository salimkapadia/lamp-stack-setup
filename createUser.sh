#!/bin/bash

# @author: Salim Kapadia
# @description - 
#	This program setups a user account that is passed in via 
#       command line argument 1 and sets default password to what 
#	is specified in the configuration file. 
#
# @How to Run:
#   ./createUser.sh [userName]
#   ./createUser.sh salim
#

# @TODO: determine if the bashrc_profile needs to be copied over for user creation. 
#
# 

SCRIPTNAME=`basename $0`

    echo "----------------------------------" 1>&2
    echo "   Starting user setup " 1>&2
    echo "----------------------------------" 1>&2   


    # Check that the user that is running this script is root. 
    if [[ $EUID -ne 0 ]]; then
       echo "This script must be run as root" 1>&2
       echo "Use 'sudo ./$SCRIPTNAME' " 1>&2
 
       exit 1
    fi

    # Confirm that they passed in a user name. 
    if [ -z "$1" ]; then
        echo "You must enter a username when running this file." 1>&2
        exit 1
    fi

    if [ ! -f configuration.cfg ]; then
       echo "The configuration file is not present." 1>&2
       exit 1
    fi

    # load configuration file
    source configuration.cfg

    USER_HOME_DIRECTORY="$USER_HOME_DIRECTORY_PATH/$1"
    if [ -d "$USER_HOME_DIRECTORY" ]; then
        echo "That directory path already exists: $USER_HOME_DIRECTORY"  1>&2
        exit 1    
    fi


    # Generate encrypted password to be stored.    
    PASSWORD=$(perl -e 'print crypt($ARGV[0], "password")' "$USER_DEFAULT_PASSWORD!")
    
    # Create a user directory
    useradd -d $USER_HOME_DIRECTORY -m $1 -p $PASSWORD -g $USER_GROUP -s $USER_DEFAULT_SHELL

    echo "----------------------------------" 1>&2
    echo "   Creating default directories   " 1>&2
    echo "----------------------------------" 1>&2   

    mkdir -p $USER_HOME_DIRECTORY/$USER_PROJECT_DIRECTORY/trunk
    mkdir -p $USER_HOME_DIRECTORY/logs 
    
    touch $USER_HOME_DIRECTORY/logs/access.log
    touch $USER_HOME_DIRECTORY/logs/error.log
    
    chmod 777 -R $USER_HOME_DIRECTORY/logs

    mkdir -p $USER_HOME_DIRECTORY/sandbox/library
    

    touch $USER_HOME_DIRECTORY/.bash_profile
    echo "ZEND_TOOL_INCLUDE_PATH=$ZEND_PATH" >> $USER_HOME_DIRECTORY/.bash_profile
    echo "export ZEND_TOOL_INCLUDE_PATH" >> $USER_HOME_DIRECTORY/.bash_profile

    chown $1:$USER_GROUP -R $USER_HOME_DIRECTORY

    echo "----------------------------------" 1>&2
    echo "   User setup complete" 1>&2
    echo "----------------------------------" 1>&2   
   
 exit 1

