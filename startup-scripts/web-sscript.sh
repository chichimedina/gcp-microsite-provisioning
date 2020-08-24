#!/bin/bash

apt-get update
apt-get -y install apache2
apt-get -y install curl


## Get configuration file variables from Google Metadata server
FRONTEND_SSL_SITE=`curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/FRONTEND_SSL_SITE -H "Metadata-Flavor: Google" 2> /dev/null`
FRONTEND_SSL_CERT=`curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/FRONTEND_SSL_CERT -H "Metadata-Flavor: Google" 2> /dev/null`
FRONTEND_SSL_KEY=`curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/FRONTEND_SSL_KEY -H "Metadata-Flavor: Google" 2> /dev/null`
FRONTEND_HOMEPAGE=`curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/FRONTEND_HOMEPAGE -H "Metadata-Flavor: Google" 2> /dev/null`

## Install app files
curl -o /etc/apache2/sites-available/default-ssl.conf  $FRONTEND_SSL_SITE
curl -o /etc/ssl/certs/apache-selfsigned.crt           $FRONTEND_SSL_CERT
curl -o /etc/ssl/private/apache-selfsigned.key         $FRONTEND_SSL_KEY
curl -o /var/www/html/index.html                       $FRONTEND_HOMEPAGE

## Enable SSL module and SSL site on Apache
a2enmod ssl
a2ensite default-ssl

## Recycle Apache web server for changes to take effect
systemctl restart apache2
