#!/bin/bash

myip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | head -n1`;
myint=`ifconfig | grep -B1 "inet addr:$myip" | head -n1 | awk '{print $1}'`;

clear 
#set time zone malaysia
echo "SET TIMEZONE KUALA LUMPUT GMT +8"
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime;
clear
echo "
CHECK AND INSTALL IT
COMPLETE 1%
"
apt-get -y install wget curl
clear
echo "
INSTALL COMMANDS
COMPLETE 15%
"

#install sudo
apt-get -y install sudo
apt-get -y wget

#ipforward
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
iptables -F
iptables -t nat -F
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.16.0.0/16 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.1.0.0/16 -o eth0 -j MASQUERADE
iptables-save

# go to root
cd

# update
apt-get update 
apt-get -y upgrade

# install webserver
apt-get -y install nginx php5-fpm php5-cli

# install essential package
apt-get -y install nmap nano iptables sysv-rc-conf openvpn vnstat apt-file
apt-get -y install libexpat1-dev libxml-parser-perl
apt-get -y install build-essential

# update apt-file
apt-file update

# Setting Vnstat
vnstat -u -i eth0
chown -R vnstat:vnstat /var/lib/vnstat
service vnstat restart

# Install Web Server
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/muchigo/VPS/master/conf/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Setup by Kiellez</pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/muchigo/VPS/master/conf/vps.conf"
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf
service php5-fpm restart
service nginx restart

# install vnstat gui
cd /home/vps/public_html/
wget http://www.sqweek.com/sqweek/files/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
sed -i "s/\$iface_list = array('eth0', 'sixxs');/\$iface_list = array('eth0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
sed -i "s/\$locale = 'en_US.UTF-8';/\$locale = 'en_US.UTF+8';/g" config.php
cd


#installing webmin
wget http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc
echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" >> /etc/apt/sources.list
apt-get update
apt-get -y install webmin
#disable webmin https
sed -i "s/ssl=1/ssl=0/g" /etc/webmin/miniserv.conf
/etc/init.d/webmin restart
cd

#installing squid3
aptitude -y install squid3
rm -f /etc/squid3/squid.conf

#restoring squid config with open port proxy 8080,7166
wget -P /etc/squid3/ "https://gist.githubusercontent.com/e7d/9472c3e7ac1821056867b95244c73609/raw/9764f69d8f0f40e6e8c9e9eca45baf649d48d968/squid.conf"
sed -i "s/$myip/$IP/g" /etc/squid3/squid.conf
service squid3 restart
cd

#bonus block torrent
wget https://raw.githubusercontent.com/zero9911/script/master/script/torrent.sh
chmod +x  torrent.sh
./torrent.sh

# Install Dos Deflate
apt-get -y install dnsutils dsniff
wget https://github.com/jgmdev/ddos-deflate/archive/master.zip
unzip master.zip
cd ddos-deflate-master
./install.sh
cd

cd /usr/local/bin/
echo "0 0 * * * root /usr/bin/reboot" > /etc/cron.d/reboot

echo "RESTART SERVICE"
service squid3 restart
service vnstat restart
service webmin restart
service cron restart
echo " DONE RESTART SERVICE"

echo "==============================================="

echo "vnstat   : http://$MYIP:81/vnstat/"
echo "WEBMIN : http://$myip:10000 "
echo "PROXY PORT : 3128"
echo "TORRENT PORT HAS BLOCK BY SCRIPT"
echo "VPS AUTO REBOOT TIAP 12 JAM"

echo "  === PLEASE REBOOT TAKE EFFECT  ===  "
echo "==============================================="
rm install.sh
