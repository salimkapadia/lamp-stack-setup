#!/bin/bash

# @author: Salim Kapadia
# @dateCreated: 03/26/2012
# @version: 1.1
# @description: This program creates an svn repository.
#	
# @sources:
#	http://www.howtoforge.com/subversion-trac-virtual-hosts-on-ubuntu-server
#
# @How to Run:
#
#   sh <filename>
#   sh createSvnRepository [repositoryName]
#   ./createSvnRepository.sh [repositoryName]
#   ./createSvnRepository.sh projectTest
#

SCRIPTNAME=`basename $0`

    echo "----------------------------------" 1>&2
    echo "   Starting Svn repository setup " 1>&2
    echo "----------------------------------" 1>&2   

    # Check that the user that is running this script is root. 
    if [[ $EUID -ne 0 ]]; then
       echo "This script must be run as root" 1>&2
       echo "Use 'sudo ./$SCRIPTNAME' " 1>&2
 
       exit 1
    fi

    # Confirm that they passed in a user name. 
    if [ -z "$1" ]; then
        echo "You must enter a repository name when running this file." 1>&2
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

    if [ ! -d "$SVN_REPOSITORIES_PATH" ]; then
        echo "Svn base directory does not exists. Creating it now at: $SVN_REPOSITORIES_PATH ..." 1>&2
	mkdir $SVN_REPOSITORIES_PATH
    fi

    echo "----------------------------------" 1>&2
    echo "   Creating svn repository ..." 1>&2
    echo "----------------------------------" 1>&2

    if [ -d "$SVN_REPOSITORIES_PATH/$1" ]; then
        echo "A directory already exists at: $SVN_REPOSITORIES_PATH/$1 ..." 1>&2
    else
	 mkdir $SVN_REPOSITORIES_PATH/$1

	# Set the proper permissions
	 chmod 2770 $SVN_REPOSITORIES_PATH/$1

	# Set up the repository.
	 svnadmin create $SVN_REPOSITORIES_PATH/$1
    fi
	# Allow the group to write to the repository.
	chmod -R g+w $SVN_REPOSITORIES_PATH/$1

	 # Giving ownership of repositories to apache. 
        chown -R www-data:$USER_GROUP $SVN_REPOSITORIES_PATH

    echo "----------------------------------" 1>&2
    echo "   Restart of apache " 1>&2
    echo "----------------------------------" 1>&2
    # restart apache
        /etc/init.d/apache2 restart

    echo "----------------------------------" 1>&2
    echo "   Svn repository setup is complete.              " 1>&2
    echo "----------------------------------" 1>&2
