#!/bin/bash

BASTION_ALLOW_USERS=`curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/BASTION_ALLOW_USERS -H "Metadata-Flavor: Google"`

echo -e "\nAllowUsers ${BASTION_ALLOW_USERS//./ }" >> /etc/ssh/sshd_config

systemctl reload ssh
