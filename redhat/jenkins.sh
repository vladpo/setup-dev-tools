#!/bin/bash

JHOME=/var/lib/jenkins
JPLUGINS="$JHOME/plugins"
JCONF="$JHOME/config.xml"
MVN_CONF="$JHOME/hudson.tasks.Maven.xml"
declare -a PLUGINS=("structs" "token-macro" "ssh-credentials" "maven-plugin" "ant" "git" "gitlab-plugin" "cobertura" "conditional-buildstep" "dashboard-view" "display-url-api" "external-monitor-job" "greenballs" "icon-shim" "javadoc" "jquery" "junit" "mailer" "mapdb-api" "matrix-auth" "matrix-project" "m2release" "maven-repo-cleaner" "monitoring" "dependency-check-jenkins-plugin" "antisamy-markup-formatter" "parameterized-trigger" "run-condition" "slave-setup" "sonar" "ssh-slaves" "analysis-core" "windows-slaves")

function nls() {
  r="\n"
  for (( i=1; i<=$2; i++)); do
    r="$r\ "
  done
  echo $r$1
}

function installPlugin() {
  if [ -f ${JPLUGINS}/${1}.hpi -o -f ${JPLUGINS}/${1}.jpi ]; then
    if [ "$2" == "1" ]; then
      return 1
    fi
    echo "Skipped: $1 (already installed)"
    return 0
  else
    echo "Installing: $1"
    sudo curl -L --silent --output ${JPLUGINS}/${1}.hpi  https://updates.jenkins-ci.org/latest/${1}.hpi
    return 0
  fi
}

JDK8="<jdks>$(nls "<jdk>" 4)$(nls "<name>java-8-oracle<\/name>" 6)$(nls "<home>\/usr\/lib\/jvm\/java-8-oracle<\/home>" 6)$(nls "<properties\/>" 6)$(nls "\<\/jdk>" 4)$(nls "<\/jdks>" 2)"
MVN3="<?xml version='1.0' encoding='UTF-8'?>"$(nls "<hudson.tasks.Maven_-DescriptorImpl>" 0)$(nls "<installations>" 2)$(nls "<hudson.tasks.Maven_-MavenInstallation>" 4)$(nls "<name>mvn3<\/name>" 6)$(nls "<home>\/usr\/share\/maven<\/home>" 6)$(nls "<properties\/>" 6)$(nls "<\/hudson.tasks.Maven_-MavenInstallation>" 4)$(nls "<\/installations>" 2)$(nls "<\/hudson.tasks.Maven_-DescriptorImpl>" 0)

echo "Creating workspace"
sudo mkdir -p /mnt/jenkins/workspace
sudo chown -R jenkins:jenkins /mnt/jenkins

echo "Registering repo and installing Jenkins"
#sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
#sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
#sudo yum -y install jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get -y install jenkins

echo "Starting Jenkins"
sudo service jenkins start

sudo sleep 5

echo "Changing workspace location"
sudo sed -i 's/<workspaceDir>.*<\/workspaceDir>/<workspaceDir>\/mnt\/jenkins\/${ITEM_FULLNAME}<\/workspaceDir>/g' $JCONF

echo "Changing builds path"
sudo sed -i 's/<buildsDir>.*<\/buildsDir>/<buildsDir>\/mnt\/jenkins\/${ITEM_FULLNAME}\/builds<\/buildsDir>/g' $JCONF

echo "Configuring Java"
sudo sed -i "s/<jdks\/>/$JDK8/g" $JCONF

echo "Configuring Maven"
echo "tmp" | sudo tee $MVN_CONF
sudo chown jenkins:jenkins $MVN_CONF
sudo chmod +r $MVN_CONF
sudo sed -i "s/tmp/$MVN3/g" $MVN_CONF

echo "Stopping Jenkins"
sudo service jenkins stop

echo "Installing plugins"
for plugin in "${PLUGINS[@]}"; do
  installPlugin "$plugin"
done

changed=1
maxloops=100

while [ "$changed"  == "1" ]; do
  echo "Check for missing dependecies ..."
  if  [ $maxloops -lt 1 ] ; then
    echo "Max loop count reached - probably a bug in this script: $0"
    exit 1
  fi
  ((maxloops--))
  changed=0
  for f in ${JPLUGINS}/*.hpi ; do
    DEPS=$( sudo unzip -p ${f} META-INF/MANIFEST.MF | tr -d '\r' | sudo sed -e ':a;N;$!ba;s/\n //g' | grep -e "^Plugin-Dependencies: " | sudo awk '{ print $2 }' | tr ',' '\n' | awk -F ':' '{ print $1 }' | tr '\n' ' ' )
    for plugin in $DEPS; do
      installPlugin "$plugin" 1 && changed=1
    done
  done
done

sudo chown -R jenkins:jenkins $JPLUGINS

echo "Starting Jenkins"
sudo service jenkins start

echo "Finished"
