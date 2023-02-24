#!/bin/bash

##################################################################################
# Building a LAMPP stack (with Git, Node, and PGSQL too)
# This will build a LAMPP stack with the addition of Git, Node, and PGSQL
##################################################################################

# First read the README, then build a Rocky 8 instance and copy this installer script to /tmp
# OR Clone this repo, then ...
#cd LAMP-GNP-Stack-Builder


# You should just execute this as root, but if you copy and paste this, make sure you sudo first.
#sudo -s


# Start an installer log
INSTLOG=/var/log/lamppstack.log
touch $INSTLOG
echo Log Time: `date` >> $INSTLOG
echo Starting the LAMPP Stack Installer log >> $INSTLOG


FILE=`find -path "./manifest.txt"`
if [ "$FILE" != "" ]; then
  echo "Found a manifext to load, continuing with that"
  source $FILE
  echo Using the manifest file  >> $INSTLOG
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
  
   if [ "$CERT_CO" == "" ]; then
    echo "For the certificate, what country code are you in? (CA,US,UK, etc)"
    read CERT_CO
  fi

  if [ "$CERT_ST" == "" ]; then
    echo "For the certificate, what State or Province are you in? (Alberta, California, etc)"
    read CERT_ST
  fi 
  
  if [ "$CERT_LO" == "" ]; then
    echo "For the certificate, what city are you in? (Edmonton, Houston, etc)"
    read CERT_LO
  fi 
  
  if [ "$CERT_ORG" == "" ]; then
    echo "For the certificate, what is the name of your company or organization"
    read CERT_ORG
  fi 



 export MYHOST=`hostname -f`
 export PUBLICIP=`curl -s checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//' `
 export PRIVATEIP=`hostname -i`



   if [ $TZ = "EST" ]; then
      export MYTZ="America/New_York"
   fi
   if [ $TZ = "CST" ]; then
      export MYTZ="America/Chicago"
   fi
   if [ $TZ = "MST" ]; then
      export MYTZ="America/Edmonton"
   fi
   if [ $TZ = "PST" ]; then
      export MYTZ="America/Los_Angeles"
   fi
   if [ $MYTZ = "" ]; then
      export MYTZ="America/Los_Angeles"
   fi


sed -i "s/HOSTNAME=.*/HOSTNAME=$MYFQDN/" /etc/sysconfig/network
echo  "$PRIVATEIP    $MYFQDN" >> /etc/hosts
hostname $MYFQDN

echo "export TZ=$MYTZ" >> /etc/profile
export TZ=$MYTZ

echo "$PRIVATEIP  $HOSTNAME
$PUBLICIP $MYFQDN" >> /etc/hosts

# Update the install log
echo "Using the following settings for install:"  >> $INSTLOG
echo Log Time: `date` >> $INSTLOG
echo MAC Address = $MYMAC >> $INSTLOG
echo HOSTNAME = $MYFQDN >> $INSTLOG
echo Public IP = $PUBLICIP >> $INSTLOG
echo Private IP = $PRIVATEIP >> $INSTLOG
echo Time Zone = $MYTZ \($TZ\) >> $INSTLOG
echo Friendly Name = $FNAME >> $INSTLOG
echo System Owner = $OWNERNAME >> $INSTLOG
echo Owner Email = $EMAIL >> $INSTLOG
echo Certificate Country = $CERT_CO >> $INSTLOG
echo Certificate State = $CERT_ST >> $INSTLOG
echo Certificate City = $CERT_LO >> $INSTLOG
echo Certificate Organization = $CERT_ORG >> $INSTLOG
echo Certificate Domain = $MYFQDN >> $INSTLOG

echo >> $INSTLOG


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

# Update the install log
echo "Turning off SELINUX:"  >> $INSTLOG

echo "Updating existing packages..."
echo "..............................."
dnf clean all
dnf update -y

echo
echo "Adding required packages..."
echo "..............................."


dnf -y install epel-release
dnf config-manager --set-enabled powertools
# rpm -Uvh https://mirror.webtatic.com/dnf/el8/webtatic-release.rpm

dnf -y install perl mcelog firewalld make gcc curl cpan tree
dnf -y install libssh perl-App-cpanminus jq gnutls gnutls-devel
dnf -y install sysstat chrony gdb lsof.x86_64 wget dnf-utils bind-utils telnet mlocate lynx unzip sudo 
dnf -y install php*  
dnf -y install httpd which flex make gcc wget zip nmap fileutils gcc-c++ curl-devel 
dnf -y install cmake clang
dnf -y install --skip-broken mysql* 
dnf -y install perl-libwww-perl ImageMagick libxml2 libxml2-devel perl-HTML-Parser perl-DBI perl-Net-DNS perl-URI perl-Digest-SHA1 
dnf -y install postgresql* cpan perl-YAML mod_ssl openssl
dnf -y install git-all nodejs npm
dnf -y install python36

###############################################
# Adding RustC and Go
wget https://go.dev/dl/go1.19.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.19.3.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=$PATH:/usr/local/go/bin" >>  /etc/profile
echo "export PATH=$PATH:/usr/local/go/bin" >>  ~/.profile
echo "source /etc/profile" >> /etc/motd.sh
go version

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.profile
source ~/.cargo/env
rustc -V


# Make mlocatedb current
sudo updatedb

#Make sure it all stays up to date
#Run a dnf update at 3AM daily
sudo echo "0 3 * * * root /usr/bin/dnf update -y >/dev/null 2>&1">/etc/cron.d/dnf-updates


### - Not even installed at this point - does it matter?
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


systemctl enable firewalld
firewall-cmd --reload

systemctl enable postgresql.service
postgresql-setup --initdb --unit postgresql  
/bin/systemctl start postgresql.service

export LANG=en_US
sudo cpanm install --force CPAN LWP::UserAgent Carp URI JSON Data::Dumper XML::Simple DBI DBD::ODBC JSON::PP::Boolean MAKAMAKA/JSON-2.51.tar.gz JSON 

# Generate private key 
openssl genrsa -out ca.key 2048 

# Generate CSR 
#openssl req -new -key ca.key -out ca.csr           
openssl req -new -key ca.key -out ca.csr -subj "/C=$CERT_CO/ST=$CERT_ST/L=$CERT_LO/O=$CERT_ORG/CN=$MYFQDN/"
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

systemctl enable chronyd.service
/bin/systemctl restart chronyd.service
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
##################################################################
##################################################################
Welcome to $FNAME 
[ https://$MYFQDN ]
 - for any questions, please contact
$OWNERNAME <$EMAIL>

Installed with:" >/etc/motd
cat /etc/redhat-release >>/etc/motd
httpd -v >>/etc/motd
mysql --version >>/etc/motd
php --version |egrep "(PHP .*) \(" >>/etc/motd
perl --version |egrep "(perl .*) \(" >>/etc/motd
git --version >>/etc/motd
openssl version >>/etc/motd
echo "Node: " >>/etc/motd
node --version >>/etc/motd
/usr/bin/psql --version >>/etc/motd
python3 --version >>/etc/motd
go version >>/etc/motd
rustc -V  >>/etc/motd

# Update the install log
echo "Done with main install. Summary:"  >> $INSTLOG
echo Log Time: `date` >> $INSTLOG
cat /etc/motd >>  $INSTLOG

echo

cat /etc/motd

echo "You should now complete the MySQL secure installation process....."

sudo systemctl enable mysqld.service
sudo mysqladmin -u root password CHANGEME
 
echo "Remember to change the root password from CHANGEME"
sudo /usr/bin/mysql_secure_installation

# EOF
