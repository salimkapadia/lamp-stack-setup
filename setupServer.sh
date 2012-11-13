#!/bin/bash

# @author: Salim Kapadia
# @description: This program sets up the server
#
# @How to Run:
#
#   sh <filename>
#   sh setupServer.sh
#

# define internal variables for this file.
MYSQL=`whereis mysql`
MYSQLPATH=`which mysql`
APACHEPATH=`whereis apache2`
SCRIPTNAME=`basename $0`

    echo "----------------------------------" 1>&2
    echo "   Starting server setup " 1>&2
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

    if [ ! -f php.ini ]; then
       echo "The php.ini file is not present." 1>&2
       exit 1
    fi

    echo "----------------------------------" 1>&2
    echo "   Loading configuration file " 1>&2
    echo "----------------------------------" 1>&2    
    # load configuration file
        source configuration.cfg

	
    echo "----------------------------------" 1>&2
    echo "   Installing aptitude  " 1>&2
    echo "----------------------------------" 1>&2
    # install required binaries    
        apt-get install --assume-yes --force-yes aptitude

    echo "----------------------------------" 1>&2
    echo "   Update and upgrading via aptitude " 1>&2
    echo "----------------------------------" 1>&2    
        aptitude update -y
	aptitude upgrade -y

    echo "----------------------------------" 1>&2
    echo "   Setting up parameters to pass to programs that asks setup based questions (mysql, phpmyadmin) " 1>&2
    echo "----------------------------------" 1>&2
        aptitude install -y debconf-utils

        echo "mysql-server-5.1 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" > /tmp/apt.seed
        echo "mysql-server-5.1 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" >> /tmp/apt.seed
	echo "mysql-server-5.1 mysql-server/start_on_boot boolean true" >> /tmp/apt.seed
        echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" >> /tmp/apt.seed
        echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" >> /tmp/apt.seed
        echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PASSWORD" >> /tmp/apt.seed
        
        
        echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASSWORD" >> /tmp/apt.seed
        echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASSWORD" >> /tmp/apt.seed
	echo "phpmyadmin phpmyadmin/setup-password password $PHPMYADMIN_PASSWORD" >> /tmp/apt.seed
        echo "phpmyadmin phpmyadmin/password-confirm password $PHPMYADMIN_PASSWORD" >> /tmp/apt.seed
        
        cat /tmp/apt.seed | debconf-set-selections
        
    if [ ! -f "$APACHEPATH" ]; then        
        echo "----------------------------------" 1>&2
        echo "   Installing apache " 1>&2
        echo "----------------------------------" 1>&2

        aptitude install -y apache2        
    fi

    if [ ! -f "$MYSQLPATH" ]; then

	echo "----------------------------------" 1>&2
	echo "   Installing mysql" 1>&2
    	echo "----------------------------------" 1>&2
 
	aptitude install -y mysql-server mysql-client
    fi
    

    echo "----------------------------------" 1>&2
    echo "   Installing dependent objects " 1>&2
    echo "----------------------------------" 1>&2
    # Install required dependences    
	aptitude install -y openssh-server
        aptitude install -y libapache2-mod-php5
        aptitude install -y php5-mysql
        aptitude install -y php5-curl
        aptitude install -y php-pear
        aptitude install -y php5-dev
        aptitude install -y php5-xdebug
        aptitude install -y phpmyadmin
        aptitude install -y subversion
        aptitude install -y git
        aptitude install -y make        
        ####aptitude install -y kdiff3
        

    echo "----------------------------------" 1>&2
    echo "   Installing pear components " 1>&2
    echo "----------------------------------" 1>&2
    # install PEAR Components        
        pear channel-update pear.net
        pear upgrade pear
        pear channel-discover pear.phpunit.de
        pear channel-discover components.ez.no
        pear channel-discover pear.symfony-project.com
        pear install XML_Serializer-0.20.2    
        pear install --alldeps phpunit/PHPUnit                
        pear install phpunit/DbUnit
        pear install phpunit/PHPUnit_Selenium
        pecl install xdebug
    
    echo "----------------------------------" 1>&2
    echo "   zend  setup version 1.12.0" 1>&2
    echo "----------------------------------" 1>&2
    # download zend, unzip, move, and clean up
        cd /tmp
	wget http://packages.zendframework.com/releases/ZendFramework-1.12.0/ZendFramework-1.12.0.tar.gz
        tar xf ZendFramework-1.12.0.tar.gz	
        mv /tmp/ZendFramework-1.12.0 $LIB_PATH
	ln -s $LIB_PATH/ZendFramework-1.12.0/library/Zend $ZEND_PATH
	ln -s $LIB_PATH/ZendFramework-1.12.0/bin/zf.sh $BIN_PATH/zf
        rm ZendFramework-1.12.0.tar.gz;

    echo "----------------------------------" 1>&2
    echo "   Composer setup" 1>&2
    echo "----------------------------------" 1>&2    
	curl -s https://getcomposer.org/installer | sudo php -- --install-dir="$BIN_PATH"

    echo "----------------------------------" 1>&2
    echo "   Doctrine setup " 1>&2
    echo "----------------------------------" 1>&2
    # download doctrine unzip, move, and clean up
        cd /tmp;
        wget http://www.doctrine-project.org/downloads/DoctrineORM-2.3.0-full.tar.gz
        tar xf DoctrineORM-2.3.0-full.tar.gz
        mv /tmp/DoctrineORM-2.3.0/Doctrine $DOCTRINE_PATH
        rm -rf DoctrineORM-2.3.0
        rm DoctrineORM-2.3.0-full.tar.gz

    echo "----------------------------------" 1>&2
    echo "   Doctrine extension " 1>&2
    echo "----------------------------------" 1>&2
    # download doctrine extensions unzip, move, and clean up
        cd /tmp
        svn export http://svn.github.com/beberlei/DoctrineExtensions 
        mv /tmp/DoctrineExtensions/lib/DoctrineExtensions $DOCTRINE_EXTENSIONS_PATH
        rm -rf /tmp/DoctrineExtensions

    echo "----------------------------------" 1>&2
    echo "   Copy of php.ini " 1>&2
    echo "----------------------------------" 1>&2
    # copy php.ini file over
        cd /tmp
        mv php.ini /etc/php5/apache2/php.ini

    echo "----------------------------------" 1>&2
    echo "   copying bashrc files           " 1>&2
    echo "----------------------------------" 1>&2
        cd /tmp
        mv bashrc ~/.bashrc

    echo "----------------------------------" 1>&2
    echo "   Misc setup               " 1>&2
    echo "----------------------------------" 1>&2    
	# log stuff ...
        touch /var/log/xdebug.log
        chmod 777 /var/log/xdebug.log
	
	# password file
   if [ ! -f "$SVN_AUTH_FILE_PATH" ]; then
   	touch $SVN_AUTH_FILE_PATH 
   fi

   if [ ! -f "$TRAC_AUTH_FILE_PATH" ]; then
        touch $TRAC_AUTH_FILE_PATH  
   fi
	# user group settings
	addgroup $USER_GROUP
	adduser www-data $USER_GROUP

	# clean up tasks
	rm /tmp/apt.seed

	# Update local hosts file on the server to point to itself.
	echo "" >> /etc/hosts
	echo "127.0.0.1	$SERVER_NAME" >> /etc/hosts

	# Activate mod rewrite
	a2enmod rewrite

    echo "----------------------------------" 1>&2
    echo "   Restart of apache " 1>&2
    echo "----------------------------------" 1>&2

    # restart apache
        /etc/init.d/apache2 restart

    echo "----------------------------------" 1>&2
    echo "   Server setup is complete.              " 1>&2
    echo "----------------------------------" 1>&2
