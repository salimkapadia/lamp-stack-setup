#!/bin/bash

# @author: Salim Kapadia
# @description: This program setups svn.
# @sources:
#	http://rbgeek.wordpress.com/2012/05/01/svn-server-on-ubuntu-12-04-lts-with-web-access/
#	http://www.howtoforge.com/subversion-trac-virtual-hosts-on-ubuntu-server	
#
# @How to Run:
#
#   sh <filename>
#   sh setupSvn.sh
#
#

SCRIPTNAME=`basename $0`

    echo "----------------------------------" 1>&2
    echo "   Starting Svn setup " 1>&2
    echo "----------------------------------" 1>&2   

    # Check that the user that is running this script is root. 
    if [[ $EUID -ne 0 ]]; then
       echo "This script must be run as root" 1>&2
       echo "Use 'sudo ./$SCRIPTNAME' " 1>&2
       exit 1
    fi

    if [ ! -f configuration.cfg ]; then
       echo "The configuration file is not present." 1>&2
       exit 1
    fi

    if [ ! -f dav_svn.conf.template ]; then
       echo "The svn configuration file is not present." 1>&2
       exit 1
    fi

    echo "----------------------------------" 1>&2
    echo "   Loading configuration file " 1>&2
    echo "----------------------------------" 1>&2    
    # load configuration file
        source configuration.cfg

    echo "----------------------------------" 1>&2
    echo "   Installing svn and apache module" 1>&2
    echo "----------------------------------" 1>&2
       aptitude install -y subversion subversion-tools libapache2-svn apache2 

    echo "----------------------------------" 1>&2
    echo "   Installing apache component to svn if not installed by the above action " 1>&2
    echo "----------------------------------" 1>&2
	a2enmod dav_svn 
  
    echo "----------------------------------" 1>&2
    echo "   Performing minor configuration stuff ... " 1>&2
    echo "----------------------------------" 1>&2

	# Make a auth file if not present. 
    if [ ! -f "$SVN_AUTH_FILE_PATH" ]; then
        touch $SVN_AUTH_FILE_PATH
    fi

	# Make a top level directory that will contain svn repositories
	mkdir -p $SVN_REPOSITORIES_PATH 

	# Giving ownership of repositories to apache. 
        chown -R www-data:$USER_GROUP $SVN_REPOSITORIES_PATH

        # making a copy of the template file. 
        cp dav_svn.conf.template dav_svn.conf

        # string replacement of variables.
	SVN_SERVER_NAME="svn.$SERVER_NAME"
        sed -i "s|SVN_AUTH_FILE_PATH|$SVN_AUTH_FILE_PATH|g" dav_svn.conf
        sed -i "s|SVN_REPOSITORIES_PATH|$SVN_REPOSITORIES_PATH|g" dav_svn.conf
	sed -i "s|SVN_SERVER_ADMIN_EMAIL|$SERVER_ADMIN_EMAIL|g" dav_svn.conf
	sed -i "s|SVN_SERVER_NAME|$SVN_SERVER_NAME|g" dav_svn.conf

        # For a setup with multiple vhosts, you will want to place
        # the configuration in /etc/apache2/sites-available/*, otherwise
        # /etc/apache2/mods-enabled/dav_svn.conf. For the purposes of 
        # this script, I will be placing it in /etc/apache2/sites-available/dav_svn
        # And because of that I will be doing a2ensite otherwise not neeeded.
	mv dav_svn.conf /etc/apache2/sites-available/$SVN_SERVER_NAME

	# enable the newly added svn site. 
	a2ensite $SVN_SERVER_NAME

	# Update local hosts file on the server to point to itself.
        echo "127.0.0.1 $SVN_SERVER_NAME" >> /etc/hosts


    echo "----------------------------------" 1>&2
    echo "   Restart of apache " 1>&2
    echo "----------------------------------" 1>&2
    # restart apache
        /etc/init.d/apache2 restart

    echo "----------------------------------" 1>&2
    echo "   Svn setup is complete.              " 1>&2
    echo "----------------------------------" 1>&2
