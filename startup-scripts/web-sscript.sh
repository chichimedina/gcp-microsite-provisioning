#!/bin/bash

apt-get update
apt-get -y install apache2
apt-get -y install curl


a2enmod ssl
systemctl restart apache2
