#!/bin/bash

function substring() {
  echo "*$1*"
}

function installGitRh() {
  sudo yum update
  sudo yum -y install git
  OS="redhat"
}

function installGitDeb() {
  sudo apt-get update
  sudo apt-get install -y git
  OS="debian"
}

if [[ ! -f $# ]]; then
  echo "Usage: "
  echo ""
  echo "./main.sh /path-to-private-ssh-key-file"
  exit 1
fi

CAT_CMD="sudo cat /etc/*-release | tr \"\\n\" ' '"
RELEASE=`eval $CAT_CMD`
RH=$(substring "Red Hat")
CENTOS=$(substring "CentOS")
DEB=$(substring "Debian")
UBUNTU=$(substring "Ubuntu")
OS=""

cd /mnt

case $RELEASE in
  $RH) installGitRh;;
  $CENTOS) installGitRh;;
  $DEB) installGitDeb;;
  $UBUNTU) installGitDeb;;
  *) 
    echo "Unknown Linux Distribution"
    exit 1
esac

exit 0
sudo git config --global user.email gaia.uat@ullink.com
sudo git config --global user.name "Gaia Uat Ullink"
sudo eval "$(ssh-agent -s)"
sudo ssh-add $1

sudo git clone git@gitlab.ullink.lan:information.systems/dev-tools-setup.git
sudo chmod +x -R ./dev-tools-setup/
cd dev-tools-setup/$OS

for script in "$@"; do
  sudo sh $script
done

echo "Finished"
