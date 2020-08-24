#!/bin/bash

## Get configuration file variables from Google Metadata server
BASTION_ALLOW_USERS=`curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/BASTION_ALLOW_USERS -H "Metadata-Flavor: Google"`

## Add the users whose SSH access is granted
echo -e "\nAllowUsers ${BASTION_ALLOW_USERS//./ }" >> /etc/ssh/sshd_config

## Recyle SSH service for changes to take effect
systemctl reload ssh
