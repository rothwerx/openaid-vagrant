#!/bin/bash
# This file runs when a new vagrant box is brought up.
# There are a few variables you can modify below. 

MYPASS='' # Set a MySQL password here, otherwise it will be 'change4prod'
OPENAID_VERSION='7.x-2.5-core'
PACKAGES="vim git drush apache2 mariadb-server mariadb-client php5 php5-mysql php5-gd libapache2-mod-php5 php5-mcrypt"
DRUSH_INSTALL=true # Set to false to disable drush site-install
#GIT_BRANCH='7.x-2.x' # Uncomment and set branch to use git instead of released tarball

##################################################

function preconfigure_mysql {
    echo "Password will be ${MYPASS:=change4prod}"
    # See http://dba.stackexchange.com/questions/59317/install-mariadb-10-on-ubuntu-without-prompt-and-no-root-password
    export DEBIAN_FRONTEND=noninteractive
    sudo debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password password ${MYPASS}"
    sudo debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password_again password ${MYPASS}"
    # We'll setup a my.cnf with credentials for simplicity
    echo -e "[client]\nuser=root\npassword=${MYPASS}" > ~/.my.cnf
    chmod 0600 ~/.my.cnf
}

function install_packages {
    apt-get update
    apt-get install -y ${PACKAGES}
}

function create_database {
    cat <<-EOF | mysql
    CREATE DATABASE drupal;
    CREATE USER drupaluser@localhost IDENTIFIED BY "${MYPASS}";
    GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,CREATE TEMPORARY TABLES,LOCK TABLES ON drupal.* TO drupaluser@localhost;
    FLUSH PRIVILEGES;
EOF
}

function configure_php {
    # Turn off allow_url_fopen and expose_php
    sed -i 's/\(allow_url_fopen = \)On/\1Off/' /etc/php5/apache2/php.ini
    sed -i 's/\(expose_php = \)On/\1Off/' /etc/php5/apache2/php.ini
}

function configure_apache {
    a2enmod rewrite
    cat <<-EOF > /etc/apache2/sites-available/000-default.conf
    <VirtualHost *:80>
        # ServerName  example.com
        ServerAdmin webmaster@example.com
        DocumentRoot /var/www/html

        <Directory /var/www/html>
            AllowOverride All 
            Require all granted 
        </Directory>
    </VirtualHost>
EOF
    a2ensite 000-default
    rm /var/www/html/index.html
    service apache2 restart
}

function arrange_files {
    mkdir /var/www/html/sites/default/files
    cp /var/www/html/sites/default/default.settings.php /var/www/html/sites/default/settings.php
    chmod 664 /var/www/html/sites/default/settings.php
}

function get_openaid {
    if [[ $GIT_BRANCH ]]; then
        get_openaid_git
        if [[ $? == 0 ]]; then
            return
        else
            echo "Git install failed. Maybe the branch specified wasn't valid?"
            echo "You'll need to install manually."
            return
        fi
    else
        # Openaid default installation & configuration.
        echo "Downloading openaid-${OPENAID_VERSION}"
        curl -sO http://ftp.drupal.org/files/projects/openaid-${OPENAID_VERSION}.tar.gz
        tar xzf /home/vagrant/openaid-${OPENAID_VERSION}.tar.gz
        cd /home/vagrant/openaid-${OPENAID_VERSION//-core}/
        rsync -az . /var/www/html
        arrange_files
    fi
}

function get_openaid_git {
    git clone --branch ${GIT_BRANCH} http://git.drupal.org/project/openaid.git
    cd openaid
    rsync -az . /var/www/html
    cd /var/www/html/
    drush make build-openaid.make -y
    arrange_files
}

function configure_with_drush {
    cd /var/www/html/
    # Specifying the profile fails when it's been built from the build-openaid.make file
    # so only set the openaid profile if it's downloaded from the tarball
    [[ ${GIT_BRANCH} ]] || profile="openaid"
    drush site-install -y ${profile} --db-url=mysql://drupaluser:${MYPASS}@localhost/drupal
    drushed=$?
}

function tell_em {
    myinfo=/home/vagrant/mysql.txt
    echo "Database name: drupal" > $myinfo
    echo "Database user: drupaluser" >> $myinfo
    echo "Database pass: ${MYPASS}" >> $myinfo
    echo "MySQL root credentials are in /root/.my.cnf" >> $myinfo
    if [[ $drushed == 0 ]]; then
        echo "Site configured with drush. Log in to http://localhost:8080/user/login"
        echo "with admin and the password it generates (in red above)."
    elif [[ $drushed ]] && [[ $drushed != 0 ]]; then
        echo "Drush configuration failed."
    else
        echo "Go to http://localhost:8080 and complete the installation."
    fi
}

function main {
    # If it's already been provisioned, don't run again
    [[ -e /etc/provisioned ]] && exit 1
    preconfigure_mysql
    install_packages
    create_database
    configure_php
    configure_apache
    get_openaid
    [[ $DRUSH_INSTALL == "true" ]] && configure_with_drush
    tell_em
    # Mark as provisioned
    date > /etc/provisioned
}

if [[ "$BASH_SOURCE" == "$0" ]]; then
    main $@
fi

