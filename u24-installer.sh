#!/bin/bash

##################################################################################
# Building a LAMPP stack (with Git, Node, and PGSQL too)
# This will build a LAMPP stack with the addition of Git, Node, and PGSQL
##################################################################################

# First read the README, then build an Ubuntu 24 instance 
# Clone this repo, then ...
# cd LAMP-GNP-Stack-Builder


# You should just execute this as root, but if you copy and paste this, make sure you sudo first.
#sudo -s


# Start an installer log
INSTLOG=/var/log/fmn/lamppstack.log
sudo mkdir -p /var/log/fmn/
sudo touch $INSTLOG
sudo chmod 774 /var/log/fmn/ -R
echo Log Time: `date` |sudo tee -a $INSTLOG
echo Starting the LAMPP Stack Installer log  |sudo tee -a $INSTLOG


FILE=`find -path "./manifest.txt"`
if [ "$FILE" != "" ]; then
  echo "Found a manifext to load, continuing with that"
  source $FILE
  echo Using the manifest file   |sudo tee -a $INSTLOG
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
echo  "$PRIVATEIP    $MYFQDN"  |sudo tee -a /etc/hosts
hostname $MYFQDN

echo "export TZ=$MYTZ"  |sudo tee -a /etc/profile
export TZ=$MYTZ

echo "$PRIVATEIP  $HOSTNAME
$PUBLICIP $MYFQDN"  |sudo tee -a /etc/hosts

# Update the install log
echo "Using the following settings for install:"   |sudo tee -a $INSTLOG
echo Log Time: `date`  |sudo tee -a $INSTLOG
echo MAC Address = $MYMAC  |sudo tee -a $INSTLOG
echo HOSTNAME = $MYFQDN  |sudo tee -a $INSTLOG
echo Public IP = $PUBLICIP  |sudo tee -a $INSTLOG
echo Private IP = $PRIVATEIP  |sudo tee -a $INSTLOG
echo Time Zone = $MYTZ \($TZ\)  |sudo tee -a $INSTLOG
echo Friendly Name = $FNAME  |sudo tee -a $INSTLOG
echo System Owner = $OWNERNAME  |sudo tee -a $INSTLOG
echo Owner Email = $EMAIL  |sudo tee -a $INSTLOG
echo Certificate Country = $CERT_CO  |sudo tee -a $INSTLOG
echo Certificate State = $CERT_ST  |sudo tee -a $INSTLOG
echo Certificate City = $CERT_LO  |sudo tee -a $INSTLOG
echo Certificate Organization = $CERT_ORG  |sudo tee -a $INSTLOG
echo Certificate Domain = $MYFQDN  |sudo tee -a $INSTLOG

echo |sudo tee -a $INSTLOG


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
kernel.shmmni = 4096 " | sudo tee -a /etc/sysctl.d/k-sysctl.conf

sudo /sbin/sysctl -p /etc/sysctl.d/k-sysctl.conf


echo "Updating existing packages..."
echo "..............................."

sudo apt-get autoclean
sudo apt-get -y update
sudo apt-get -y upgrade


echo
echo "Adding required packages..."
echo "..............................."

sudo apt install -y firewalld tree telnet git bind9 bind9-utils vim jq

sudo apt install -y perl make gcc curl cpan tree jq wget locate  
sudo apt install -y php php-mysql apache2 which flex zip nmap 
sudo apt install -y mysql-server-8.0  postgresql 
sudo apt install -y git-all nodejs npm
sudo apt install -y python3


###############################################
# Adding RustC and Go
wget https://go.dev/dl/go1.19.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.19.3.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=$PATH:/usr/local/go/bin"  |sudo tee -a  /etc/profile
echo "export PATH=$PATH:/usr/local/go/bin"  |sudo tee -a  ~/.profile
echo "source /etc/profile"  |sudo tee -a /etc/motd.sh
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
"  |sudo tee -a /etc/sysconfig/network-scripts/ifcfg-eth0

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
"  |sudo tee -a  /etc/ssh/sshd_config 


service sshd restart


echo "
##################################################################
##################################################################
Welcome to $FNAME 
[ https://$MYFQDN ]
 - for any questions, please contact
$OWNERNAME <$EMAIL>

Installed with:" >/etc/motd
cat /etc/redhat-release  |sudo tee -a /etc/motd
httpd -v  |sudo tee -a /etc/motd
mysql --version  |sudo tee -a /etc/motd
php --version |egrep "(PHP .*) \("  |sudo tee -a /etc/motd
perl --version |egrep "(perl .*) \("  |sudo tee -a /etc/motd
git --version  |sudo tee -a /etc/motd
openssl version  |sudo tee -a /etc/motd
echo "Node: "  |sudo tee -a /etc/motd
node --version  |sudo tee -a /etc/motd
/usr/bin/psql --version  |sudo tee -a /etc/motd
python3 --version  |sudo tee -a /etc/motd
go version  |sudo tee -a /etc/motd
rustc -V   |sudo tee -a /etc/motd

# Update the install log
echo "Done with main install. Summary:"   |sudo tee -a $INSTLOG
echo Log Time: `date`  |sudo tee -a $INSTLOG
cat /etc/motd  |sudo tee -a  $INSTLOG

echo

cat /etc/motd

echo "You should now complete the MySQL secure installation process, then reboot to ensure it all comes back up"

sudo systemctl enable mysqld.service
sudo mysqladmin -u root password CHANGEME
 
echo "Remember to change the root password from CHANGEME"
sudo /usr/bin/mysql_secure_installation

# EOF
