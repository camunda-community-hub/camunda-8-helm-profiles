#!/bin/sh

echo "Attempt to find ip address ...";

getIp()
{
  ELB_ID=$(kubectl get service -w ingress-nginx-controller -o 'go-template={{with .status.loadBalancer.ingress}}{{range .}}{{.hostname}}{{"\n"}}{{end}}{{.err}}{{end}}' -n ingress-nginx 2>/dev/null | head -n1 | cut -d'.' -f 1 | cut -d'-' -f 1)
  #echo "Attempt to find ip address for elb: ${ELB_ID}";
  IP_ADDRESS=$(aws ec2 describe-network-interfaces --filters Name=description,Values="ELB ${ELB_ID}" --query 'NetworkInterfaces[0].PrivateIpAddresses[*].Association.PublicIp' --output text)
  #echo "IP Address: $IP_ADDRESS";
}

getIp;

while [ "$IP_ADDRESS" = "None" ] || [ -z "$IP_ADDRESS" ]; do getIp; done;
echo "Found ip address: $IP_ADDRESS";