#!/bin/bash

##################################################################################
# Building a LAMPP stack (with Git, Node, and PGSQL too)
# This will build a LAMPP stack with the addition of Git, Node, and PGSQL
##################################################################################

# First build a Rocky 8 instance and copy this installer script to /tmp
# OR Clone this repo, then ...
cd LAMP-GNP-Stack-Builder


# You should just execute this as root, but if you copy and paste this, make sure you sudo first.
#sudo -s


FILE=`find -path "./manifest.txt"`
if [ "$FILE" != "" ]; then
  echo "Found a manifext to load, continuing with that"
  source $FILE
fi

##################################################################
# Get all the required manual entry data
##################################################################
  if [ "$FNAME" == "" ]; then
    echo "Enter the friendly name of this server (IE: \"my dev server\")"
    read FNAME
  fi
   
  if [ "$MYFQDN" == "" ]; then
    echo "Enter the FQDN  (IE: \"myserver.home.net\") or press ENTER/RETURN for default" 
    read MYFQDN
  fi

  if [ "$OWNERNAME" == "" ]; then
    echo "Enter the name of the system operator (IE: \"Bob Jones\")"
    read OWNERNAME
  fi

  if [ "$EMAIL" == "" ]; then
    echo "Enter the email address of the above system operator (IE: \"bob@here.com\")"
    read EMAIL
  fi 

  if [ "$TZ" == "" ]; then
    echo "What timezone is the server in? (EST,CST,MST,PST)"
    read TZ
  fi 


 export PUBLICIP=`curl -s checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//' `
 export PRIVATEIP=`hostname -i`


   if [ $TZ = "EST" ]; then
      MYTZ="America/New_York"
   fi
   if [ $TZ = "CST" ]; then
      MYTZ="America/Chicago"
   fi
   if [ $TZ = "MST" ]; then
      MYTZ="America/Edmonton"
   fi
   if [ $TZ = "PST" ]; then
      MYTZ="America/Los_Angeles"
   fi
   if [ $MYTZ = "" ]; then
      MYTZ="America/Los_Angeles"
   fi


sed -i "s/HOSTNAME=.*/HOSTNAME=$FQDN/" /etc/sysconfig/network
echo  "$PRIVATEIP    $FQDN" >> /etc/hosts
hostname $FQDN


systemctl stop iptables.service
systemctl stop ip6tables.service
systemctl mask iptables.service
systemctl mask ip6tables.service

systemctl enable ntpd.service
systemctl start  ntpd.service

systemctl stop  postfix.service
systemctl disable postfix.service

systemctl stop  qpidd.service
systemctl disable qpidd.service



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
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp

systemctl enable firewalld
firewall-cmd --reload


echo "export TZ=$MYTZ" >> /etc/profile
export TZ=$MYTZ

echo "$PRIVATEIP  $HOSTNAME
$PUBLICIP $FQDN" >> /etc/hosts


# Modify sysctl with Momentum friendly values
sudo echo "
vm.max_map_count = 768000
net.core.rmem_default = 32768
net.core.wmem_default = 32768
net.core.rmem_max = 262144
net.core.wmem_max = 262144
fs.file-max = 250000
net.ipv4.ip_local_port_range = 5000 63000
net.ipv4.tcp_tw_reuse = 1
kernel.shmmax = 68719476736
net.core.somaxconn = 1024
vm.nr_hugepages = 10
kernel.shmmni = 4096 " | sudo tee -a /etc/sysctl.d/ec-sysctl.conf

sudo /sbin/sysctl -p /etc/sysctl.d/ec-sysctl.conf

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config  
/usr/sbin/setenforce 0


echo "Updating existing packages..."
echo "..............................."
dnf clean all
dnf update -y

echo
echo "Adding required packages..."
echo "..............................."


dnf -y install epel-release
rpm -Uvh https://mirror.webtatic.com/dnf/el8/webtatic-release.rpm

dnf -y install perl mcelog firewalld make gcc curl cpan mysql*
dnf -y install sysstat ntp gdb lsof.x86_64 wget dnf-utils bind-utils telnet mlocate lynx unzip sudo 
# dnf -y install php-devel php-gd php-imap php-ldap php-mysql php-odbc php-xml php-xmlrpc php-pgsql  
dnf -y install httpd mysql mysql-devel mysql-server which flex make gcc wget unzip zip nmap fileutils gcc-c++ curl curl-devel 
dnf -y install perl-libwww-perl ImageMagick libxml2 libxml2-devel perl-HTML-Parser perl-DBI perl-Net-DNS perl-URI perl-Digest-SHA1 
dnf -y install postgresql postgresql-contrib postgresql-devel postgresql-server cpan perl-YAML mod_ssl openssl

# Uncomment this section if you want PHP 5.6
#dnf -y remove php*
#dnf -y install php56w php56w-opcache
#dnf -y install php56w* --skip-broken
#dnf -y remove php56w-mysqlnd
#dnf -y install php56w-mysql

# Uncomment this section if you want PHP 7.0
dnf -y remove php*
dnf -y install php70w php70w-opcache
dnf -y install php70w* --skip-broken
dnf -y remove php70w-mysqlnd
dnf -y install php70w-mysql



wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
sudo rpm -ivh mysql-community-release-el7-5.noarch.rpm
dnf update -y


# Make mlocatedb current
updatedb


#Make sure it all stays up to date
#Run a dnf update at 3AM daily
echo "0 3 * * * root /usr/bin/dnf update -y >/dev/null 2>&1">/etc/cron.d/dnf-updates




systemctl enable postgresql.service
postgresql-setup initdb
/bin/systemctl start postgresql.service

# Install GIT
dnf install -y git-all

## Skip rest?
dnf install curl-devel expat-devel gettext-devel openssl-devel zlib-devel -y
dnf install gcc perl-ExtUtils-MakeMaker -y
cd /usr/src
wget https://www.kernel.org/pub/software/scm/git/git-2.9.3.tar.gz
tar xzf git-2.9.3.tar.gz 
cd git-2.9.3
make prefix=/usr/local/git all
make prefix=/usr/local/git install
export PATH=$PATH:/usr/local/git/bin
source /etc/bashrc

# Install Node

dnf install -y nodejs npm

cd /usr/src
curl --silent --location https://rpm.nodesource.com/setup_9.x | sudo bash -
sudo dnf -y install nodejs

cd /tmp

export LANG=en_US
/usr/bin/cpan install --force CPAN LWP::UserAgent Carp URI JSON Data::Dumper XML::Simple DBI DBD::ODBC JSON::PP::Boolean MAKAMAKA/JSON-2.51.tar.gz JSON --force

cd /tmp

# Generate private key 
openssl genrsa -out ca.key 2048 

# Generate CSR 
openssl req -new -key ca.key -out ca.csr

echo "If this script stops here, check the script and run everyting after the \"PAUSE\""

# PAUSE 

# Generate Self Signed Key
openssl x509 -req -days 365 -in ca.csr -signkey ca.key -out ca.crt

# Copy the files to the correct locations
mv -f ca.crt /etc/pki/tls/certs
mv -f ca.key /etc/pki/tls/private/ca.key
mv -f ca.csr /etc/pki/tls/private/ca.csr

sed -i 's/SSLCertificateFile \/etc\/pki\/tls\/certs\/localhost.crt/SSLCertificateFile \/etc\/pki\/tls\/certs\/ca.crt/' /etc/httpd/conf.d/ssl.conf
sed -i 's/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/localhost.key/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/ca.key/' /etc/httpd/conf.d/ssl.conf

systemctl enable ntpd.service
/bin/systemctl restart ntpd.service
systemctl disable postfix.service
/bin/systemctl stop postfix.service
systemctl enable httpd.service
/bin/systemctl restart httpd.service
/bin/systemctl restart mysqld.service


# Make sure server is only accessible by PubKey
echo "
## Configure for pubkey only logins
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
" >>  /etc/ssh/sshd_config 


service sshd restart


echo "
##############################################
Welcome to the web server 
[ https://$FQDN ]
 - for any questions, please contact
$USERNAME <$EMAIL>
Installed with:
" >/etc/motd

cat /etc/redhat-release >>/etc/motd
httpd -v >>/etc/motd
mysql --version >>/etc/motd
php --version |egrep "(PHP .*) \(" >>/etc/motd
perl --version |egrep "(perl .*) \(" >>/etc/motd
echo " " >>/etc/motd
git --version >>/etc/motd
openssl version >>/etc/motd
echo "Node: " >>/etc/motd
node --version >>/etc/motd
/usr/bin/psql --version >>/etc/motd

echo "
##############################################
" >> /etc/motd

echo "
cat /etc/*elease
echo " > /etc/motd.sh

echo "sh /etc/motd.sh" >> /etc/profile




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

# End Script here 
###################################################################
# Then run the MySQL Secure COnfig

systemctl enable mysqld.service
/usr/bin/mysql_secure_installation

#PAUSE
