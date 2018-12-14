#!/bin/bash

if [ -f "already_ran" ]; then
    echo "Already ran the Entrypoint once. Holding indefinitely for debugging."
    service vesta restart && service nginx restart && service apache2 restart && serivce mysql restart
    cat
fi
touch already_ran


# Vesta installation wrapper
# http://vestacp.com

#
# Currently Supported Operating Systems:
#
#   RHEL 5, 6, 7
#   CentOS 5, 6, 7
#   Debian 7, 8
#   Ubuntu 12.04 - 18.04
#

# Am I root?
if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root'
    exit 1
fi

# update
apt-get update

# install GnuPG
apt-get -y install gnupg gnupg2 wget

# Check admin user account
if [ ! -z "$(grep ^admin: /etc/passwd)" ] && [ -z "$1" ]; then
    echo "Error: user admin exists"
    echo
    echo 'Please remove admin user before proceeding.'
    echo 'If you want to do it automatically run installer with -f option:'
    echo "Example: bash $0 --force"
    exit 1
fi

# Check admin group
if [ ! -z "$(grep ^admin: /etc/group)" ] && [ -z "$1" ]; then
    echo "Error: group admin exists"
    echo
    echo 'Please remove admin group before proceeding.'
    echo 'If you want to do it automatically run installer with -f option:'
    echo "Example: bash $0 --force"
    exit 1
fi


# Install VestaCP
bash vst-install-debian.sh --nginx yes --apache yes --phpfpm no --named yes --remi yes --vsftpd no --proftpd no --iptables yes --fail2ban yes --quota no --exim yes --dovecot yes --spamassassin yes --clamav yes --softaculous no --mysql yes --postgresql no --hostname ${HOSTNAME} --email ${ADMIN_EMAIL} --password ${ADMIN_PASSWORD} -y no


# Add vestacp redirect template
cp /templates/web/nginx/vestacp-redirect.tpl /usr/local/vesta/data/templates/web/nginx/
cp /templates/web/nginx/vestacp-redirect.stpl /usr/local/vesta/data/templates/web/nginx/

# Add force https template
cp /templates/web/nginx/force-https.tpl /usr/local/vesta/data/templates/web/nginx/
cp /templates/web/nginx/force-https.stpl /usr/local/vesta/data/templates/web/nginx/


# Restart nginx
service nginx restart


# Clean up any old letsencrypt nginx challenge
rm -rf /home/*/conf/web/nginx.*.conf_letsencrypt/


# Change data dir of mysql
service mysql stop
rm -rf /var/lib/mysql
sudo ln -s /mysql /var/lib/mysql
chmod -R 777 /mysql
rm -rf /mysql/ib_logfile*
service mysql restart


# Install PHP FPM
bash vst-install-php.sh


# Hang
tail -f /dev/null
