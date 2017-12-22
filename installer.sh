Building a LAMP stack (with extras)
# This will build a LAMP stack with the addition of Git, Node, and PGSQL

# First build an RHEL 6.5 AMI and copy this installer script to /tmp

sudo -s
vi /etc/sysconfig/network
vi /etc/hosts
hostname hp.app.trymsys.net

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


resize2fs /dev/xvde

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config  
/usr/sbin/setenforce 0

yum clean headers
yum clean packages
yum clean metadata

yum update -y

yum install perl mcelog sysstat ntp gdb lsof.x86_64 wget yum-utils bind-utils telnet mlocate lynx unzip sudo lynx php-devel php-gd php-imap php-ldap php-mysql php-odbc php-xml php-xmlrpc php-pgsql  httpd mysql mysql-devel mysql-server which flex make gcc wget unzip zip nmap fileutils gcc-c++ curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel perl-HTML-Parser perl-DBI perl-Net-DNS perl-URI perl-Digest-SHA1 webalizer cpan perl-YAML mod_ssl openssl -y

yum -y install postgresql postgresql-contrib postgresql-devel postgresql-server
chkconfig postgresql on
service postgresql initdb
service postgresql start


rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
yum  -y install php56w php56w-opcache
yum  -y install yum-plugin-replace
yum  -y replace php-common --replace-with=php56w-common
yum  -y install php56w* --skip-broken

# Install GIT
sudo yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel -y
sudo yum install gcc perl-ExtUtils-MakeMaker -y
cd /usr/src
wget https://www.kernel.org/pub/software/scm/git/git-2.9.3.tar.gz
tar xzf git-2.9.3.tar.gz 
cd git-2.9.3
make prefix=/usr/local/git all
make prefix=/usr/local/git install
export PATH=$PATH:/usr/local/git/bin
source /etc/bashrc



/usr/bin/cpan CPAN LWP::UserAgent Carp URI JSON Data::Dumper XML::Simple DBI DBD::ODBC MAKAMAKA/JSON-2.51.tar.gz JSON --force

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

PAUSE

mysql -u root -p


exit;

chkconfig ntpd on 
/etc/init.d/ntpd start 
service postfix stop
/sbin/chkconfig postfix off

sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config   
echo "seteam       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
service sshd restart

useradd seteam
passwd seteam


node --version
php --version
perl --version
mysql --version
httpd -v
openssl version


init 6
