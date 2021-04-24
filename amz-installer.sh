#!/bin/bash

##################################################################################
# Building a LAMP stack (with extras)
# This will build a LAMP stack with the addition of Git, Node, and PGSQL
##################################################################################

# First build an Amazon Linux AMI and copy this installer script to /tmp
# This installer uses Amazon Linux AMI  amzn2-ami-hvm-2.0.20210219.0-x86_64-gp2

# You should just execute this as root, but if you copy and paste this, make sure you sudo first.
#sudo -s

# Get all the info you need to continue
echo "Enter the FQDN of this server (IE: \"my.dev.server.com\")"
read FQDN
echo "What is your full name?"
read $USERNAME 
echo "What is your email address?"
read $EMAIL

PRIVATEIP=`hostname -i`
 
sed -i "s/HOSTNAME=.*/HOSTNAME=$FQDN/" /etc/sysconfig/network
echo  "$PRIVATEIP    $FQDN" >> /etc/hosts
hostname $FQDN



echo "
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these two values:
#     targeted - Targeted processes are protected,
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
" > /etc/selinux/config

/usr/sbin/setenforce 0

#rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
#rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm

yum clean headers
yum clean packages
yum clean metadata

yum update -y

# Install any supporting packages that we may want for later...
yum -y install perl mcelog sysstat ntp gdb lsof.x86_64 wget yum-utils bind-utils telnet mlocate lynx unzip sudo
yum -y install make gcc curl cpan firewalld lynx
yum -y install perl sysstat ntp gdb lsof.x86_64 wget yum-utils bind-utils telnet mlocate lynx unzip sudo 
yum -y install httpd httpd httpd-tools mod_ssl mysql mysql-devel mysql-server 
yum -y install which flex make gcc wget unzip zip nmap fileutils gcc-c++ curl curl-devel 
yum -y install perl-libwww-perl ImageMagick libxml2 libxml2-devel perl-HTML-Parser perl-DBI perl-Net-DNS perl-URI perl-Digest-SHA1 
yum -y install postgresql postgresql-contrib postgresql-devel postgresql-server cpan perl-YAML mod_ssl openssl

wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
yum localinstall -y mysql57-community-release-el7-11.noarch.rpm 
yum install -y mysql-community-server
systemctl start mysqld.service


# Installing PHP 7.3
yum -y remove php*
amazon-linux-extras disable php7.4
amazon-linux-extras disable php7.2
amazon-linux-extras enable php7.3
yum install -y php php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip,imap}

#Make sure it all stays up to date
#Run a yum update at 3AM daily
echo "0 3 * * * root /usr/bin/yum update -y >/dev/null 2>&1">/etc/cron.d/yum-updates


# Make mlocatedb current
updatedb



# Turn off any services that we do not want
# Turn on any ones that we do need
systemctl stop iptables.service
systemctl stop ip6tables.service
systemctl disable iptables.service
systemctl disable ip6tables.service

systemctl enable ntpd.service
systemctl start  ntpd.service

systemctl stop  postfix.service
systemctl disable postfix.service

systemctl stop  qpidd.service
systemctl disable qpidd.service5

# Update and start Firewalld
systemctl enable firewalld

echo "ZONE=public
" >> /etc/sysconfig/network-scripts/ifcfg-eth0

systemctl stop firewalld
systemctl start firewalld.service
firewall-cmd --set-default-zone=public
firewall-cmd --zone=public --change-interface=eth0
firewall-cmd --zone=public --permanent --add-service=http
firewall-cmd --zone=public --permanent --add-service=https
firewall-cmd --zone=public --permanent --add-service=ssh
firewall-cmd --zone=public --permanent --add-service=smtp
firewall-cmd --zone=public --permanent --add-port=587/tcp
firewall-cmd --zone=public --permanent --add-port=81/tcp
firewall-cmd --zone=public --permanent --add-port=2081/tcp
firewall-cmd --zone=public --permanent --add-port=2084/tcp

systemctl enable firewalld


chkconfig postgresql on
service postgresql initdb
service postgresql start

# Install GIT
yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel -y
yum install gcc perl-ExtUtils-MakeMaker -y
cd /usr/src
wget https://www.kernel.org/pub/software/scm/git/git-2.9.3.tar.gz
tar xzf git-2.9.3.tar.gz 
cd git-2.9.3
make prefix=/usr/local/git all
make prefix=/usr/local/git install
export PATH=$PATH:/usr/local/git/bin
source /etc/bashrc

# Install Node
cd /usr/src
curl --silent --location https://rpm.nodesource.com/setup_14.x | sudo bash -
sudo yum -y install nodejs

cd /tmp

# Generate private key 
openssl genrsa -out ca.key 2048 

# Generate CSR 
openssl req -new -key ca.key -out ca.csr

# PAUSE 

# Generate Self Signed Key
openssl x509 -req -days 365 -in ca.csr -signkey ca.key -out ca.crt

# Copy the files to the correct locations
mv ca.crt /etc/pki/tls/certs
mv ca.key /etc/pki/tls/private/ca.key
mv ca.csr /etc/pki/tls/private/ca.csr

sed -i 's/SSLCertificateFile \/etc\/pki\/tls\/certs\/localhost.crt/SSLCertificateFile \/etc\/pki\/tls\/certs\/ca.crt/' /etc/httpd/conf.d/ssl.conf
sed -i 's/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/localhost.key/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/ca.key/' /etc/httpd/conf.d/ssl.conf

chkconfig --level 345 mysqld on
chkconfig --level 345 httpd on
service httpd restart
service mysqld restart


chkconfig ntpd on 
/etc/init.d/ntpd start 
service postfix stop
/sbin/chkconfig postfix off


echo "
##############################################
Welcome to the web server 
[ https://$FQDN ]

 - for any questions, please contact
$USERNAME <$EMAIL>
##############################################
" > /etc/motd

echo "
cat /etc/*elease
echo " > /etc/motd.sh

echo "sh /etc/motd.sh" >> /etc/profile





echo
echo
echo
echo
echo
echo
echo
echo

echo "NODE Version:"
node --version
echo
echo "PHP Version:"
php --version
echo
echo "PERL Version:"
perl --version
echo
echo "MySQL Version:"
mysql --version
echo
echo "Apache HTTPD Version:"
httpd -v
echo
echo "OpenSSL Version:"
openssl version
echo
echo "PostgreSQL Version:"
/usr/bin/psql --version
echo
echo "Git Version:"
/usr/bin/git --version
echo

echo "Now running ' /usr/bin/mysql_secure_installation ' "
echo "Remember to use this temporary root password:"
grep 'temporary password' /var/log/mysqld.log

echo "You should then 'init 6' here to make sure everything comes back up ok."

/usr/bin/mysql_secure_installation

