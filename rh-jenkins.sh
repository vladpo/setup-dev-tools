#!/bin/bash

function nls() {
  r="\n"
  for (( i=1; i<=$2; i++))
   do
     r="$r\ "
   done
  echo $r$1
}

sudo mkdir -p /mnt/jenkins/workspace
sudo chown -R jenkins:jenkins /mnt/jenkins

sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
sudo yum -y install jenkins

sudo sed -i 's/<workspaceDir>.*<\/workspaceDir>/<workspaceDir>\/mnt\/jenkins\/${ITEM_FULLNAME}<\/workspaceDir>/g' /var/lib/jenkins/config.xml

sudo sed -i 's/<buildsDir>.*<\/buildsDir>/<buildsDir>\/mnt\/jenkins\/${ITEM_FULLNAME}\/builds<\/buildsDir>/g' /var/lib/jenkins/config.xml

sudo sed -i 's/<jdks\/>/<jdks>\\\n<jdk>\\\n<name>java-8-oracle<\/name>\\\n<home>\/usr\/lib\/jvm/java-8-oracle<\/home>\\\n<properties\/>\\\n<\/jdk>\\\n<\/jdks>/g' /var/lib/jenkins/config.xml

JDK8="<jdks>$(nls "<jdk>" 4)$(nls "<name>java-8-oracle<\/name>" 6)$(nls "<home>\/usr\/lib\/jvm\/java-8-oracle<\/home>" 6)$(nls "<properties\/>" 6)$(nls "\<\/jdk>" 4)$(nls "<\/jdks>" 2)"
sudo sed -i "s/<jdks\/>/$JDK8/g" "/var/lib/jenkins/config.xml"

MVN3="<installations>"$(nls "<hudson.tasks.Maven_-MavenInstallation>" 4)$(nls "<name>mvn3<\/name>" 6)$(nls "<home>\/usr\/share\/maven<\/home>" 6)$(nls "<properties\/>" 6)$(nls "<\/hudson.tasks.Maven_-MavenInstallation>" 4)$(nls "<\/installations>" 2)
sudo sed -i "s/<installations\/>/$MVN3/g" "/var/lib/jenkins/hudson.tasks.Maven.xml"
