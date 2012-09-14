#!/bin/bash

# this script is inteded to setup everything required to bring 
# up a phpBB server on an amazon linux distro micro-instance
# on Amazon EC2


SECURITY_GROUP=phpBB_web
SECURITY_DESC='Allows ports 22 and 80 from anywhere'
AMI=ami-734c6936
INSTANCE_TYPE=t1.micro


# setup the security group
echo "Setting up the security group: $SECURITY_GROUP"
echo $SECURITY_DESC | ec2-add-group $SECURITY_GROUP -d -
ec2-authorize $SECURITY_GROUP -p 22
ec2-authorize $SECURITY_GROUP -p 80

# bring up the server
echo "Bringing up a micro instance. AMI: $AMI   TYPE: $INSTANCE_TYPE   SECURITY GROUP: $SECURITY_GROUP"
INSTANCE_ID=`ec2-run-instances $AMI -t $INSTANCE_TYPE -g $SECURITY_GROUP -k phpBBdev | grep INSTANCE | awk '{print $2}'`

# setup the ANSIBLE_HOSTS environment vars
echo "Setting up the Ansible environnment"
echo [web-server] > ./ansible_hosts
PUB_DNS=""
while [ -z "$PUB_DNS"  ]
do
	PUB_DNS=`ec2-describe-instances $INSTANCE_ID | grep -o 'ec2.*\.compute\.amazonaws\.com'`
done
echo $PUB_DNS >> ./ansible_hosts

export ANSIBLE_HOSTS=./ansible_hosts
RESPOND=""
while [ -z "$RESPOND" ]
do
	RESPOND=`ansible $PUB_DNS -m ping -u ec2-user | grep success`
done
ansible-playbook phpBB_php.yml

firefox $PUB_DNS
