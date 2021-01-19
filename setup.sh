#!/bin/bash
# This Script is to be run on Ubuntu / Debian Linux Distributions.

#Package Upgrades
apt-get update
apt-get upgrade -y

#Install open JDK 8
apt install openjdk-8-jdk -y

#Adding sources for unifi Repository
echo 'deb http://www.ubnt.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list

#Importing the GPG key
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ubnt.com/unifi/unifi-repo.gpg

# Install UniFi
apt-get update
apt-get install unifi -y

# Add Let's Encrypt Repo
add-apt-repository -y ppa:certbot/certbot
apt-get update
apt-get install python-certbot-apache -y

echo "Make sure you have added the A record for the Domain"
echo "Enter the Domain name you want to use:"
read domain;
certbot --apache -d $domain --register-unsafely-without-email

# SSL Import
wget https://raw.githubusercontent.com/stevejenkins/unifi-linux-utils/master/unifi_ssl_import.sh -O /usr/local/bin/unifi_ssl_import.sh
chmod +x /usr/local/bin/unifi_ssl_import.sh

#modify unifi hostname
sed -i "25s/UNIFI_HOSTNAME=.*$/UNIFI_HOSTNAME=$domain/" /usr/local/bin/unifi_ssl_import.sh

#Modify Other Unifi Parameters
sed -i '29s,UNIFI_DIR=/opt/UniFi,#UNIFI_DIR=/opt/UniFi,' /usr/local/bin/unifi_ssl_import.sh
sed -i '30s,JAVA_DIR=${UNIFI_DIR},#JAVA_DIR=${UNIFI_DIR},' /usr/local/bin/unifi_ssl_import.sh
sed -i '31s,KEYSTORE=${UNIFI_DIR}/data/keystore,#KEYSTORE=${UNIFI_DIR}/data/keystore,' /usr/local/bin/unifi_ssl_import.sh

sed -i '34s,#UNIFI_DIR=/var/lib/unifi,UNIFI_DIR=/var/lib/unifi,' /usr/local/bin/unifi_ssl_import.sh
sed -i '35s,#JAVA_DIR=/usr/lib/unifi,JAVA_DIR=/usr/lib/unifi,' /usr/local/bin/unifi_ssl_import.sh
sed -i '36s,#KEYSTORE=${UNIFI_DIR}/keystore,KEYSTORE=${UNIFI_DIR}/keystore,' /usr/local/bin/unifi_ssl_import.sh

#Enabling Let's Encrypt Mode
sed -i "45s/LE_MODE=.*$/LE_MODE=yes/" /usr/local/bin/unifi_ssl_import.sh

echo "All Changes done - Running SSL import to add SSL Certificate"

#Import the LE SSL to Unifi
/bin/bash /usr/local/bin/unifi_ssl_import.sh

   if [[ $? == 0 ]]; then
        echo "Please try accessing UniFi at https://<domain>:8443"
   fi

#Adding to Crontab to enable daily check for SSL & Have Unifi Import it
echo -e '#!/bin/bash \n/usr/local/bin/unifi_ssl_import.sh' > /etc/cron.daily/unifi_ssl_import
chown root:root /etc/cron.daily/unifi_ssl_import
chmod +x /etc/cron.daily/unifi_ssl_import

echo “The Script has executed successfully.”
