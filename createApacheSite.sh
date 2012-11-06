#!/bin/bash

# @author: Salim Kapadia
#
# @description - This program setups a website on the server
#
#   How to Run:
#   ./createApacheSite.sh [userName] [websiteName]
#   ./createApacheSite.sh salim mywebsite
#
SCRIPTNAME=`basename $0`

    echo "----------------------------------" 1>&2
    echo "   Starting site setup " 1>&2
    echo "----------------------------------" 1>&2   

    # Check that the user that is running this script is root. 
    if [[ $EUID -ne 0 ]]; then
       echo "This script must be run as root" 1>&2
       echo "Use 'sudo ./$SCRIPTNAME' " 1>&2 

       exit 1
    fi

    # Confirm that they passed in a user name. 
    if [ -z "$1" ]; then
        echo "You must enter a user name." 1>&2
        exit 1
    fi

    # Confirm that they passed in a website name. 
    if [ -z "$2" ]; then
        echo "You must enter the website name." 1>&2
        exit 1
    fi

    if [ ! -f configuration.cfg ]; then
       echo "The configuration file is not present." 1>&2
       exit 1
    fi

    # load configuration file
    source configuration.cfg

    # make sure the username entered exits on the system.
    if [ ! -d "$USER_HOME_DIRECTORY_PATH/$1" ]; then
        echo "The username is not a valid user on this server." 1>&2
        echo "Please add him as a user first." 1>&2
        exit 1
    fi

    #define script variables start:
        WEBSITEDIRECTORY="$USER_HOME_DIRECTORY_PATH/$1/$USER_PROJECT_DIRECTORY/trunk/$2"
        
        #apache virtual host file name
        VHOST_SITE_NAME=$1-$2.$SERVER_NAME

        # Get the ip address of this box. 
        #IPADDRESS=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
        IPADDRESS="127.0.0.1"
                
        LOGLOCATION=$USER_HOME_DIRECTORY_PATH/$1/logs

    #define script variables done

    if [ -d "$WEBSITEDIRECTORY" ]; then
        echo "That website already exits."  1>&2
        exit 1    
    fi

    if [ -f /etc/apache2/sites-available/$VHOST_SITE_NAME ]; then
       echo "A website already exists under this name." 1>&2
       exit 1
    fi
    
    # make log directory if it's not present. 
    if [ ! -d "$LOGLOCATION" ]; then
        echo "----------------------------------" 1>&2
        echo "   making log directory: $LOGLOCATION " 1>&2
        echo "----------------------------------" 1>&2   

	mkdir -p $LOGLOCATION            

    # touch the files and give write global write permissions.
	touch $LOGLOCATION/access.log
	touch $LOGLOCATION/error.log
	chmod 777 $LOGLOCATION/access.log
	chmod 777 $LOGLOCATION/error.log

    # make sym link to php_error.log 
    	ln -s $PHP_ERROR_LOG_FILE $LOGLOCATION/php_errors.log

    # Change ownership to the user.
    	chown -R $1:$USER_GROUP $LOGLOCATION 
            
    fi    

    echo "----------------------------------" 1>&2
    echo "   Making website path: $WEBSITEDIRECTORY " 1>&2
    echo "----------------------------------" 1>&2   
        # create the website directory
        mkdir -p $WEBSITEDIRECTORY/public
        mkdir -p $WEBSITEDIRECTORY/library
        
        chown -R $1:$USER_GROUP $WEBSITEDIRECTORY 


    echo "----------------------------------" 1>&2
    echo "   Making sym links in the library folder. " 1>&2
    echo "----------------------------------" 1>&2   
        # create sym links
        ln -s $ZEND_PATH $WEBSITEDIRECTORY/library/Zend
        ln -s $DOCTRINE_PATH $WEBSITEDIRECTORY/library/Doctrine

    echo "----------------------------------" 1>&2
    echo "   Calling sed to do string replacements. " 1>&2
    echo "----------------------------------" 1>&2   

        # making a copy of the template file. 
        cp virtualhostfile.template virtualhostfile
        
        # string replacement of variables.         
        sed -i "s|HOST_NAME_GOES_HERE|$VHOST_SITE_NAME|g" virtualhostfile
	sed -i "s|SERVER_ADMIN_EMAIL|$SERVER_ADMIN_EMAIL|g" virtualhostfile
	sed -i "s|SERVER_NAME|$SERVER_NAME|g" virtualhostfile
	
        sed -i "s|HOST_NAME_ALIAS_GOES_HERE|$IPADDRESS|g"  virtualhostfile
        sed -i "s|SITE_DOCUMENT_ROOT|$WEBSITEDIRECTORY/public|g"  virtualhostfile
        sed -i "s|SITE_LOCATION|$WEBSITEDIRECTORY/public|g"  virtualhostfile
        sed -i "s|LOG_FILE_LOCATION|$LOGLOCATION|g"  virtualhostfile
        
        sed -i "s|APPLICATION_ENV_GOES_HERE|$APPLICATION_ENV|g"  virtualhostfile
        
        mv virtualhostfile /etc/apache2/sites-available/$VHOST_SITE_NAME

    echo "----------------------------------" 1>&2
    echo "   Enabling site. " 1>&2
    echo "----------------------------------" 1>&2   
        # Enable the new virtual site. 
        a2ensite $VHOST_SITE_NAME

    echo "----------------------------------" 1>&2
    echo "   Forcing apache to reload config information. " 1>&2
    echo "----------------------------------" 1>&2   
        # Reload apache settings:
        service apache2 reload

    echo "----------------------------------" 1>&2
    echo "   Site setup is complete." 1>&2
    echo "----------------------------------" 1>&2   

