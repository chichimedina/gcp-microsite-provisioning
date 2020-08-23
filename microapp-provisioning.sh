#!/bin/bash


## Source the configuration file
. conf/microapp.conf


network_provisioning() {

  local subnet_name="$1"
  local subnet_range="$2"
  
  gcloud compute networks subnets create $subnet_name --region=$APP_NET_REGION --network=$APP_VPC --range=$subnet_range

}

vm_provisioning() {

  local vm_name="$1"
  local subnet_name="$2"
  local internet_facing="$3"
  local vm_tags="$4"
  local sscript="$5"
  local sscript_metadata="$6"
  local no_address=""

  [ "${internet_facing,,}" = "false" ] && no_address="--no-address"
  [ -z "$sscript_metadata" ] && metadata="--metadata enable-oslogin=TRUE" || metadata="--metadata $sscript_metadata,enable-oslogin=TRUE"

  gcloud compute instances create $vm_name       \
    --image-family=$COMPUTE_IMG_FAMILY           \
    --image-project=$COMPUTE_IMG_PROJECT         \
    --machine-type=$COMPUTE_TYPE                 \
    --scopes userinfo-email,cloud-platform       \
    --zone $APP_VM_ZONE                          \
    --subnet $subnet_name                        \
    $no_address                                  \
    $metadata                                    \
    --metadata-from-file startup-script=$sscript \
    --tags=$vm_tags

}

firewall_rules () {


  echo
  gcloud compute firewall-rules create bastion-deny-22-tcp  \
         --network=default                                  \
         --action deny                                      \
         --rules tcp:22                                     \
         --source-ranges 0.0.0.0/0                          \
         --target-tags=bastion                              \
         --priority 500

  echo
  gcloud compute firewall-rules create bastion-allow-22-tcp --network=default --action allow --rules tcp:22 --source-ranges 35.235.240.0/20,55.45.190.0/24,123.123.0.0/20 --target-tags=bastion --priority 50

  echo
  ## Deny all traffic to 22/TCP on "web" instances
  gcloud compute firewall-rules create frontend-backend-deny-22-tcp --network=default --action deny --rules tcp:22  --target-tags=frontend,backend --source-ranges=0.0.0.0/0 --priority 500

  echo
  ## Allow traffic to 22/TCP from "bastion" on "web" instances
  gcloud compute firewall-rules create frontend-backend-allow-22-tcp --network=default --action allow --rules tcp:22  --target-tags=frontend,backend --source-tags=bastion --priority 50

  echo
  ## Deny all traffic to 80/TCP on "app" instances
  gcloud compute firewall-rules create backend-deny-80-tcp --network=default --action deny --rules tcp:80 --target-tags=backend --source-ranges=0.0.0.0/0 --priority 500

  echo
  ## Allow traffic to 80/TCP from "web" instances
  gcloud compute firewall-rules create backend-allow-80-tcp --network=default --action allow --rules tcp:80  --target-tags=backend --source-tags=frontend --priority 50

  echo
  ## Deny traffic to 443/TCP from "bastion" and "app" tiers with high priority
  gcloud compute --project=assignments-01-285722 firewall-rules create frontend-deny-internet-only-443-tcp --direction=INGRESS --priority=50 --network=default --action=DENY --rules=tcp:443 --source-tags=bastion,backend --target-tags=frontend

  echo
  ## Allow traffic to 443/TCP from anywhere with low priority
  gcloud compute --project=assignments-01-285722 firewall-rules create frontend-allow-internet-only-44-tcp --direction=INGRESS --priority=500 --network=default --action=ALLOW --rules=tcp:443 --source-ranges=0.0.0.0/0 --target-tags=frontend

}


###network_provisioning $BASTION_NET_NAME $BASTION_NET_RANGE
###network_provisioning $FRONTEND_NET_NAME $FRONTEND_NET_RANGE
###network_provisioning $BACKEND_NET_NAME $BACKEND_NET_RANGE

echo -e "\n\n\t\tMicro-App Deployment"
echo -e "\t\t++++++++++++++++++++\n\n"


echo -e "--------\nPROVISIONING THE INSTANCES:\n--------\n"

echo -e "\n>>> Creating and setting up the \"bastion\" instance ... "
###vm_provisioning $BASTION_VHOSTNAME $BASTION_NET_NAME "true" $BASTION_TAGS $BASTION_SSCRIPT "BASTION_ALLOW_USERS=${BASTION_ALLOW_USERS// /.}"
echo -e "----------\n"

echo -e "\n>>> Creating and setting up  the \"frontend\" instance ... "
vm_provisioning $FRONTEND_VHOSTNAME $FRONTEND_NET_NAME "true" $FRONTEND_TAGS $FRONTEND_SSCRIPT ""
echo -e "----------\n"

echo -e "\n>>> Provisioning the \"backend\" instance ... "
vm_provisioning $BACKEND_VHOSTNAME $BACKEND_NET_NAME "true" $BACKEND_TAGS $BACKEND_SSCRIPT ""
echo -e "----------\n"

###echo -e "\n\n--------\nSETTING UP SOME FIREWALL RULES:\n--------\n"
firewall_rules

echo -ne "\n\n\n>>> ONE LAST STEP - Removing NAT IP (External IP) from the \"backend\" instance ... "
FRONTEND_NAT_IP=`gcloud compute instances describe $BACKEND_VHOSTNAME --zone $APP_VM_ZONE | grep -B 1 natIP | grep 'name:' | awk '{print $2}'`
gcloud compute instances delete-access-config $BACKEND_VHOSTNAME --zone $APP_VM_ZONE --access-config-name $FRONTEND_NAT_IP &> /dev/null
[ $? -eq 0 ] && echo [Done] || echo "[ERROR] Something went wrong!"


echo -e "\n\n"
