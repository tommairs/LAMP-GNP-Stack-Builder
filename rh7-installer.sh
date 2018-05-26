##################################################################################
# Building a LAMP stack (with extras)
# This will build a LAMP stack with the addition of Git, Node, and PGSQL
##################################################################################

# First build a CentOS 7.4 AMI and copy this installer script to /tmp

# You should just execute this as root, but if you copy and paste this, make sure you sudo first.
#sudo -s

# Get all the info you need to continue
echo "Enter the FQDN of this server (IE: \"my.dev.server.com\")"
read FQDN

echo "What timezone is the server in? (EST,CST,MST,PST)"
read MYTZ


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



PRIVATEIP=`hostname -i`
 
sed -i "s/HOSTNAME=.*/HOSTNAME=$FQDN/" /etc/sysconfig/network
echo  "$PRIVATEIP    $FQDN" >> /etc/hosts
hostname $FQDN


echo "Updating existing packages..."
echo "..............................."
yum clean headers
yum clean packages
yum clean metadata

yum update -y

echo
echo "Adding required packages..."
echo "..............................."

yum -y install perl mcelog sysstat ntp gdb lsof.x86_64 wget yum-utils bind-utils telnet mlocate lynx unzip sudo firewalld make gcc curl cpan mysql*

#Make sure it all stays up to date
#Run a yum update at 3AM daily
echo "0 3 * * * root /usr/bin/yum update -y >/dev/null 2>&1">/etc/cron.d/yum-updates

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



echo "
vm.max_map_count = 768000
net.core.rmem_default = 32768
net.core.wmem_default = 32768
net.core.rmem_max = 262144
net.core.wmem_max = 262144
fs.file-max = 250000
net.ipv4.ip_local_port_range = 5000 63000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
kernel.shmmax = 68719476736
net.core.somaxconn = 1024
vm.nr_hugepages = 10
kernel.shmmni = 4096
" >> /etc/sysctl.conf

/sbin/sysctl -p /etc/sysctl.conf

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config  
/usr/sbin/setenforce 0


yum clean headers
yum clean packages
yum clean metadata

yum update -y

yum -y install perl sysstat ntp gdb lsof.x86_64 wget yum-utils bind-utils telnet mlocate lynx unzip sudo 
yum -y install lynx php-devel php-gd php-imap php-ldap php-mysql php-odbc php-xml php-xmlrpc php-pgsql  
yum -y install httpd mysql mysql-devel mysql-server which flex make gcc wget unzip zip nmap fileutils gcc-c++ curl curl-devel 
yum -y install perl-libwww-perl ImageMagick libxml2 libxml2-devel perl-HTML-Parser perl-DBI perl-Net-DNS perl-URI perl-Digest-SHA1 
yum -y install postgresql postgresql-contrib postgresql-devel postgresql-server cpan perl-YAML mod_ssl openssl

wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
sudo rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum update

yum -y install epel-release
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

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


systemctl enable postgresql.service
postgresql-setup initdb
/bin/systemctl start postgresql.service

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
/usr/bin/cpan install --force CPAN LWP::UserAgent Carp URI JSON Data::Dumper XML::Simple DBI DBD::ODBC JSON::PP::Boolean MAKAMAKA/JSON-2.51.tar.gz JSON --force

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

systemctl enable mysqld.service
systemctl enable httpd.service
/bin/systemctl restart httpd.service
/bin/systemctl restart mysqld.service
/usr/bin/mysql_secure_installation

#PAUSE

systemctl enable ntpd.service
/bin/systemctl restart ntpd.service

systemctl disable postfix.service
/bin/systemctl stop postfix.service

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



