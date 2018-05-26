#!/bin/bash

##################################################################################
# Building a LAMP stack (with extras)
# This will build a LAMP stack with the addition of Git, Node, and PGSQL
##################################################################################

# First build an Amazon Linux AMI and copy this installer script to /tmp
# This installer uses Amazon Linux AMI release 2017.09

# You should just execute this as root, but if you copy and paste this, make sure you sudo first.
#sudo -s

# Get all the info you need to continue
echo "Enter the FQDN of this server (IE: \"my.dev.server.com\")"
read FQDN

PRIVATEIP=`hostname -i`
 
sed -i "s/HOSTNAME=.*/HOSTNAME=$FQDN/" /etc/sysconfig/network
echo  "$PRIVATEIP    $FQDN" >> /etc/hosts
hostname $FQDN

echo "
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [82:15000]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 25 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 81 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 587 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
" > /etc/sysconfig/iptables
service iptables restart


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

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm

yum clean headers
yum clean packages
yum clean metadata

yum update -y

yum -y install perl sysstat ntp gdb lsof.x86_64 wget yum-utils bind-utils telnet mlocate lynx unzip sudo 
yum -y install lynx php-devel php-gd php-imap php-ldap php-mysql php-odbc php-xml php-xmlrpc php-pgsql  
yum -y install httpd mysql mysql-devel mysql-server which flex make gcc wget unzip zip nmap fileutils gcc-c++ curl curl-devel 
yum -y install perl-libwww-perl ImageMagick libxml2 libxml2-devel perl-HTML-Parser perl-DBI perl-Net-DNS perl-URI perl-Digest-SHA1 
yum -y install postgresql postgresql-contrib postgresql-devel postgresql-server cpan perl-YAML mod_ssl openssl

# Uncomment this section if you want PHP 5.6
#yum -y remove php*
#yum -y install php56w php56w-opcache
#yum -y install php56w* --skip-broken
#yum -y remove php56w-mysqlnd
#yum -y install php56w-mysql

# Uncomment this section if you want PHP 7.0
yum -y remove php*
yum -y install php70w php70w-opcache
yum -y install php70w* --skip-broken
yum -y remove php70w-mysqlnd
yum -y install php70w-mysql

# Make mlocatedb current
updatedb

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
curl --silent --location https://rpm.nodesource.com/setup_9.x | sudo bash -
sudo yum -y install nodejs

cd /tmp

export LANG=en_US
/usr/bin/cpan CPAN LWP::UserAgent Carp URI JSON Data::Dumper XML::Simple DBI DBD::ODBC JSON::PP::Boolean MAKAMAKA/JSON-2.51.tar.gz JSON --force

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
/usr/bin/mysql_secure_installation

#PAUSE

chkconfig ntpd on 
/etc/init.d/ntpd start 
service postfix stop
/sbin/chkconfig postfix off

# Create a separate "ops" user with sudo access:
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config   
echo "ops       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
service sshd restart

useradd ops
passwd ops

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
echo
echo "PHP Version:"
php --version
echo
echo
echo "PERL Version:"
perl --version
echo
echo
echo "MySQL Version:"
mysql --version
echo
echo
echo "Apache HTTPD Version:"
httpd -v
echo
echo
echo "OpenSSL Version:"
openssl version
echo
echo
echo "PostgreSQL Version:"
/usr/bin/psql --version
echo
echo


echo "You should 'init 6' here to make sure everything comes back up ok."

echo "DONE"

