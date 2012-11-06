#!/bin/bash

# @author: Salim Kapadia
# @description: This program sets up trac.
# @sources:
#	http://trac.edgewall.org/wiki/TracInstall#InstallingTrac
#	http://trac.edgewall.org/wiki/Ubuntu-11.10
#	http://minibiti.blogspot.com/2010/06/agilo-for-scrum.html	
#	http://trac.edgewall.org/wiki/TracOnUbuntu
#
# @How to Run:
#
#   sh <filename>
#   sh setupTrac.sh
#
#

SCRIPTNAME=`basename $0`

    echo "----------------------------------" 1>&2
    echo "   Starting Track setup " 1>&2
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

    echo "----------------------------------" 1>&2
    echo "   Loading configuration file " 1>&2
    echo "----------------------------------" 1>&2    
    # load configuration file
        source configuration.cfg

    echo "----------------------------------" 1>&2
    echo "   Installing Trac..." 1>&2
    echo "----------------------------------" 1>&2
	#Installing base packages
	aptitude install -y apache2 libapache2-mod-python python-setuptools python-genshi mysql-server python-mysqldb

	#Installing trac
        aptitude install -y trac

    echo "----------------------------------" 1>&2
    echo "   Trac, mysql and directory setup               " 1>&2
    echo "----------------------------------" 1>&2
        SQL_QUERY="CREATE DATABASE IF NOT EXISTS $TRAC_MYSQL_DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;GRANT ALL ON $TRAC_MYSQL_DBNAME.* TO '$TRAC_MYSQL_USR'@'$TRAC_MYSQL_HOST' IDENTIFIED BY '$TRAC_MYSQL_PSWD';FLUSH PRIVILEGES;"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "$SQL_QUERY"

	TRAC_SERVER_NAME="trac.$SERVER_NAME"

 	# trac directory setup.
	mkdir -p $TRAC_REPOSITORIES_PATH/$TRAC_SERVER_NAME

	# Set the proper permissions.
	chmod 2770 $TRAC_REPOSITORIES_PATH/$TRAC_SERVER_NAME

        # Creating trac repository
	COMMAND_TO_RUN="trac-admin $TRAC_REPOSITORIES_PATH/$TRAC_SERVER_NAME initenv $TRAC_PROJECT_NAME mysql://$TRAC_MYSQL_USR:$TRAC_MYSQL_PSWD@$TRAC_MYSQL_HOST/$TRAC_MYSQL_DBNAME"
	$COMMAND_TO_RUN

         # Giving ownership of repositories to apache. 
        chown -R www-data:$USER_GROUP $TRAC_REPOSITORIES_PATH/$TRAC_SERVER_NAME

	# Allow the group to write to the repository.
	chmod -R g+w $TRAC_REPOSITORIES_PATH/$TRAC_SERVER_NAME

	chmod -R 777 $TRAC_REPOSITORIES_PATH

        # Creating admin administrator account.
    if [ ! -f "$TRAC_AUTH_FILE_PATH" ]; then
        touch $TRAC_AUTH_FILE_PATH
    fi
        htpasswd -db $TRAC_AUTH_FILE_PATH $TRAC_ADMIN_USER $TRAC_ADMIN_USER_PASSWORD

	 # Enabling trac admin panel
	COMMAND_TO_RUN="trac-admin $TRAC_REPOSITORIES_PATH permission add $TRAC_ADMIN_USER TRAC_ADMIN"
	$COMMAND_TO_RUN

    echo "----------------------------------" 1>&2
    echo "   Trac vhost setup               " 1>&2
    echo "----------------------------------" 1>&2
	# making a copy of the template file. 
        cp trac.conf.template trac.conf
        # string replacement of variables.

        sed -i "s|TRAC_AUTH_FILE_PATH|$TRAC_AUTH_FILE_PATH|g" trac.conf
        sed -i "s|TRAC_SERVER_ADMIN_EMAIL|$SERVER_ADMIN_EMAIL|g" trac.conf
        sed -i "s|TRAC_SERVER_NAME|$TRAC_SERVER_NAME|g" trac.conf
	sed -i "s|TRAC_DOCUMENT_ROOT|$TRAC_REPOSITORIES_PATH/$TRAC_SERVER_NAME|g" trac.conf
	sed -i "s|TRAC_REPOSITORIES_PATH|$TRAC_REPOSITORIES_PATH|g" trac.conf
		
        mv trac.conf /etc/apache2/sites-available/$TRAC_SERVER_NAME

        # enable the newly added svn site. 
        a2ensite $TRAC_SERVER_NAME

        # Update local hosts file on the server to point to itself.
        echo "127.0.0.1 $TRAC_SERVER_NAME" >> /etc/hosts



    echo "----------------------------------" 1>&2
    echo "   restart of apache " 1>&2
    echo "----------------------------------" 1>&2
    # restart apache
        /etc/init.d/apache2 restart

    echo "----------------------------------" 1>&2
    echo "   Trac setup is complete.              " 1>&2
    echo "----------------------------------" 1>&2
