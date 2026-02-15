#!/bin/sh

echo "Inside aws-ingress.sh script"

# Validate AWS_REGION is set
if [ -z "$AWS_REGION" ]; then
    echo "ERROR: AWS_REGION environment variable is not set"
    echo "Usage: AWS_REGION=us-east-2 $0"
    exit 1
fi

echo "AWS_REGION: ${AWS_REGION}"

getIp()
{
    # Step 1: Get the ELB hostname using jsonpath
    ELB_HOSTNAME=$(kubectl get service ingress-nginx-controller \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' \
      -n ingress-nginx)

    # Step 2: Extract the ELB_ID (first part before the first dot)
    ELB_ID=$(echo "$ELB_HOSTNAME" | cut -d'.' -f 1 | cut -d'-' -f 1)

    # Step 3: Retrieve the public IP address associated with the ELB using AWS CLI
    IP_ADDRESS=$(aws ec2 describe-network-interfaces \
                  --region $AWS_REGION \
                  --filters Name=description,Values="ELB ${ELB_ID}" \
                  --query 'NetworkInterfaces[0].PrivateIpAddresses[*].Association.PublicIp' \
                  --output text)

}

getIp;

echo "Searching for external IP address associated with ELB hostname: $ELB_HOSTNAME and ELB ID: $ELB_ID"
echo "The search may take a few minutes. Please wait..."

while [ "$IP_ADDRESS" = "None" ] || [ -z "$IP_ADDRESS" ]; do getIp; done;

echo "Found IP address: ${IP_ADDRESS} associated with ELB hostname: ${ELB_HOSTNAME} and ELB ID: ${ELB_ID}"