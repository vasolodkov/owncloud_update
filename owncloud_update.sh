#!/bin/sh

#
# run as root
#

echo "------------------"
echo "enable maintenance" 
echo "------------------"
cd /var/www/html/owncloud/
sudo -u apache php occ maintenance:mode --on
systemctl stop httpd

echo "------"
echo "backup"
echo "------"
cd ..
cp -r /var/www/html/owncloud/ /var/www/html/owneloud_bkp_$(date + %Y%m%d)/

echo "-------------"
echo "dump database"
echo "-------------"
cd ~
DBUSER=$(grep dbuser /var/www/html/ouncloud/config/config.php | awk '{ print $3 }' | tr -d \'\, )
DBPASSWORD=$(grep dbpassword /var/www/html/owncloud/config/config.php | awk '{ print $3 }' | tr -d \'\,)
DBNAME=$(grep dbname /var/www/html/owncloud/config/config.php | awk '{ print $3 }' | tr -d \'\,)
OVER=$(grep 'Version =' /var/www/html/owncloud/version.php | awk '{ print$3 }' | cut -d\( -f2 | tr-d \)\; | sed -e 's/,/.g')

mysqldump -u$DBUSER -p$DBPASSWORD $DBNAME > owncloud_$(date +%Y%m%d)-$OVER.sql


echo "-----------------"
echo "check application"
echo "-----------------"
cd /var/www/html/owncloud
sudo -u apache php occ app:list

echo "-------------------"
echo "disable application"
echo "-------------------"
APPS=$(echo $TEST | sed -e 's/-/\n/g' | cut -d: -f1 | sed '1d;$d')
APPS="${APPS} user_ldap"
for APP in $APPS; do
sudo -u apache php occ app:disable $APP;
done;

echo "-------"
echo "updating"
echo "-------"
yum update -y

echo "--------------"
echo "restore config"
echo "--------------"
cp /var/www/html/owncloud_bkp_$(date +%Y%m%d)/config/config.php /var/www/html/owncloud/config/config.php
cp -r /var/www/html/owncloud_bkp_$(date +%Y%m%d)/data/ /var/www/html/owncloud/data/

echo "----------------"
echo "upgrade owncloud"
echo "----------------"
chown R apache:apache /var/www/html/owncloud
sudo -u apache php occ upgrade

echo "-------------------"
echo "disable maintenance"
echo "-------------------"
sudo -u apache php occ maintenance : mode --off
systemctl start httpd

echo "-------------------"
echo "enable applications"
echo "-------------------"
for APP in $APPS; do
sudo -u apache php occ app:enable $APP;
done;

sudo -u apache php occ upgrade
