#!/bin/sh

sudo yum -y install tomcat mariadb mariadb-server wget
sudo systemctl start mariadb
sudo mysql -u root -e "create database softslate;"
sudo wget https://www.softslate.com/distributions/community/3.4.1/softslate-3.4.1.war -O /usr/share/tomcat/webapps/cart.war
sudo systemctl start tomcat

# Fetch our public hostname
HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
BASE_CUSTOMER_URL="http:\/\/${HOSTNAME}:8080\/cart\/"
SECURE_CUSTOMER_URL="http:\/\/${HOSTNAME}:8080\/cart\/"
ADMINISTRATOR_URL="http:\/\/${HOSTNAME}:8080\/cart\/administrator"

# Fix our database file
sudo perl -p -i -e "s/BASE_CUSTOMER_URL/${BASE_CUSTOMER_URL}/g" /home/ec2-user/spacely_backup.sql
sudo perl -p -i -e "s/SECURE_CUSTOMER_URL/${SECURE_CUSTOMER_URL}/g" /home/ec2-user/spacely_backup.sql
sudo perl -p -i -e "s/ADMINISTRATOR_URL/${ADMINISTRATOR_URL}/g" /home/ec2-user/spacely_backup.sql

# Restore the database
sudo mysql -u root softslate < /home/ec2-user/spacely_backup.sql