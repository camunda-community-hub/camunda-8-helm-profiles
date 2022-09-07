#!/bin/sh

getIp()
{
  IP_ADDRESS=$(aws ec2 describe-network-interfaces --filters Name=description,Values="ELB *" --query 'NetworkInterfaces[0].PrivateIpAddresses[*].Association.PublicIp' --output text)
  echo "Attempt to find ip address: $IP_ADDRESS";
}

getIp;
while [ "$IP_ADDRESS" = "None" ] || [ -z "$IP_ADDRESS" ]; do getIp; done;