#!/bin/bash

echo "Starting Cert Builder"
echo


FILE=`find -path "./manifest.txt"`
if [ "$FILE" != "" ]; then
  echo "Found a manifest to load, continuing with that"
  source ./manifest.txt
else
      bash ./get_manifest.sh	
fi


APACHETEST=`sudo systemctl status apache2  2>&1`
if [[ "$APACHETEST" != *"could not be found"* ]]; then
    sudo systemctl stop apache2
fi
NGINXTEST=`sudo systemctl status nginx  2>&1`
if [[ "$NGINXTEST" != *"could not be found"* ]]; then
    sudo systemctl stop nginx
fi

PKGTYPE=`cat /etc/os-release |grep ^NAME`

if [ "$PKGTYPE" == "NAME=\"Rocky Linux\"" ]; then
        echo "Running DNF cert builder"
        # Getting cert with LetsEncrypt
        sudo dnf -y install epel-release
        sudo dnf -y upgrade
        sudo dnf -y install snapd
        sudo systemctl enable --now snapd.socket
        sudo ln -s /var/lib/snapd/snap /snap
        sudo dnf -y remove certbot
        sudo snap install --classic certbot
        sudo ln -s /snap/bin/certbot /usr/local/bin/certbot
        sudo certbot certonly --standalone -n --agree-tos -m $EMAIL -d $MYFQDN
elif [ "$PKGTYPE" == "NAME=\"Ubuntu\"" ]; then
        echo "Running APT cert builder"
        # Getting cert with LetsEncrypt
        sudo apt-get remove certbot
        sudo snap install --classic certbot
        sudo ln -s /snap/bin/certbot /usr/bin/certbot
        sudo certbot certonly --standalone -n --agree-tos -m $EMAIL -d $MYFQDN
fi 


# Copy the files to the correct locations
# Note this is /etc/ssl/ for Ubuntu/Debian
# Note this is /etc/pki/tls/ for CentOS/Rocky
# Note this is /opt/kumomta/etc/tls/ for KumoMTA Specific

echo "Relocating TLS Cert data"

if [ $SSLDIR == "Ubuntu" ] || [ $SSLDIR == "Debian" ]; then
  sudo mkdir -p /etc/ssl/$DOMAIN
  sudo cp -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/ssl/$DOMAIN/ca.crt
  sudo cp -f /etc/letsencrypt/live/$DOMAIN/privkey.pem /etc/ssl/$DOMAIN/ca.key
  sudo cp -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/ssl/$DOMAIN/ca.csr
  fi

if [ $SSLDIR == "Apache" ] || [ $SSLDIR == "Centos" ] || [ $SSLDIR == "Rocky" ]; then
  sudo mkdir -p /etc/pki/tls/private/$DOMAIN
  sudo mkdir -p /etc/pki/tls/certs/$DOMAIN
  sudo cp -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/pki/tls/certs/$DOMAIN/ca.crt
  sudo cp -f /etc/letsencrypt/live/$DOMAIN/privkey.pem /etc/pki/tls/private/$DOMAIN/ca.key
  sudo cp -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/pki/tls/private/$DOMAIN/ca.csr
  sed -i 's/SSLCertificateFile \/etc\/pki\/tls\/certs\/localhost.crt/SSLCertificateFile \/etc\/pki\/tls\/certs\/ca.crt/' /etc/httpd/conf.d/ssl.conf
  sed -i 's/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/localhost.key/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/ca.key/' /etc/httpd/conf.d/ssl.conf
fi

# Build DKIM keys
echo "Building DKIM keys for $DOMAIN"
  sudo mkdir -p /opt/kumomta/etc/tls/$DOMAIN
  sudo cp -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem /opt/kumomta/etc/tls/$DOMAIN/ca.crt
  sudo cp -f /etc/letsencrypt/live/$DOMAIN/privkey.pem /opt/kumomta/etc/tls/$DOMAIN/ca.key
  sudo cp -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem /opt/kumomta/etc/tls/$DOMAIN/ca.csr

  sudo chmod 644 /opt/kumomta/etc/tls/$DOMAIN/ca.*
  sudo chown root:root /opt/kumomta/etc/tls/$DOMAIN/ca.*

sudo systemctl restart apache2

echo
echo "Leaving Cert Builder"
echo
