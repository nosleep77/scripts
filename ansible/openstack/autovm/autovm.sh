#!/bin/bash

## Create instance and add its record to Windows 2008 DNS

## first source Openstack RC file
## USAGE: ./autovm.sh host_name keypair_name flavor Net_ID_1 Net_ID_2

hostname=$1
keypair=$2
flavor=$3
nic1=$4
nic2=$5

if [ -z "$nic2" ]
then
  nova boot --flavor $flavor --snapshot 6b7d2ecc-e441-4005-805a-9f11b00b57f3 \
        --key-name $keypair \
        --nic net-id=$nic1 \
        --poll $hostname
else
  nova boot --flavor $flavor --snapshot 6b7d2ecc-e441-4005-805a-9f11b00b57f3 \
        --key-name $keypair \
        --nic net-id=$nic1 \
        --nic net-id=$nic2 \
        --poll $hostname
fi

ip_add=`nova show $hostname | grep network | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | grep '10.'`

winexe --user diwlab/test --password=Password123 //10.99.99.50 \
        "cmd.exe /c dnscmd diwlbad01.diwlab.local /RecordDelete testdns.local $hostname A /f"

winexe --user diwlab/test --password=Password123 //10.99.99.50 \
        "cmd.exe /c dnscmd diwlbad01.diwlab.local /RecordAdd testdns.local $hostname A $ip_add"
