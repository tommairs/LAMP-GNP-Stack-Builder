# LAMP-GNP-Stack-Builder
This will build a LAMPP stack with the addition of Git, Node, and PGSQL

## Installing
 - Create a new instance
 - Install git with ```sudo dnf install -y git-all``` or ```sudo yum install -y git-all```
 - Go to a safe place, IE: ```cd /var/tmp```
 - Clone this repo with ```git clone https://github.com/tommairs/LAMP-GNP-Stack-Builder```
 - Enter the repo ... ```cd LAMP-GNP-Stack-Builder```
 - Switch to a privileged user, ```sudo -s```
 - Modify the manifest.txt file if needed
 - Execute the installer for your Linux flavour.  IE: ```sh rk8-installer.sh```
 
 For example, if installing on Rocky Linux V8, you can do this:

```
sudo dnf install -y git-all
cd /var/tmp
git clone https://github.com/tommairs/LAMP-GNP-Stack-Builder
cd LAMP-GNP-Stack-Builder
sudo sh rk8-installer.sh
```
 
Tested: Rocky8
To Do: Retest AMZ, CentOS, RH8
