#!/bin/bash

sudo apt-add-repository -y ppa:webupd8team/java
sudo apt update
sudo echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
sudo apt install -y oracle-java8-installer
