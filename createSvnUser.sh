#!/bin/bash

# @author: Salim Kapadia
# @description: This program creates an svn user on the server.

#
# @How to Run:
#
#   sh <filename>
#   sh createSvnUser.sh
#   ./createSvnUser.sh [userName]
#   ./createSvnUser.sh salim
#
#	@TODO: add autogenerate password for svn setup. 
#

SCRIPTNAME=`basename $0`

    echo "----------------------------------" 1>&2
    echo "   Starting Svn User setup " 1>&2
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

    echo "----------------------------------" 1>&2
    echo "   Loading configuration file " 1>&2
    echo "----------------------------------" 1>&2
    # load configuration file
        source configuration.cfg

    USER_HOME_DIRECTORY="$USER_HOME_DIRECTORY_PATH/$1"
    if [ ! -d "$USER_HOME_DIRECTORY" ]; then
        echo "You are attempting to create an svn user that is not a user on this machine. It is recommended that you use the same username for both svn and this server."  1>&2
        exit 1
    fi

    echo "----------------------------------" 1>&2
    echo "   Creating svn user ... be prepared to type in a password" 1>&2
    echo "----------------------------------" 1>&2

    if [ ! -f "$SVN_AUTH_FILE_PATH" ]; then
        touch $SVN_AUTH_FILE_PATH
    fi
        htpasswd -d $SVN_AUTH_FILE_PATH $1	

    echo "----------------------------------" 1>&2
    echo "   restart of apache " 1>&2
    echo "----------------------------------" 1>&2
    # restart apache
        /etc/init.d/apache2 restart

    echo "----------------------------------" 1>&2
    echo "   Svn user setup is complete.              " 1>&2
    echo "----------------------------------" 1>&2
