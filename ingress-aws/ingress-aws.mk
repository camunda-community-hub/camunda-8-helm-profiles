# NOTE: if there are more than one elastic load balancer, this command will list multiple ip addresses.
# If that's the case, replace the "ELB *" a specific ELB name.
# NOTE: Each elastic load balancer has one ip address per zone per load balancer dns name. The `NetworkInterfaces[0]`
# syntax below gets the first of these zone ip addresses. Use `NetworkInterfaces[*]` to see all zones ip addresses.
.PHONY: elb-ip-address
elb-ip-address:
	$(eval IP:= $(shell aws ec2 describe-network-interfaces --filters Name=description,Values="ELB *" --query 'NetworkInterfaces[0].PrivateIpAddresses[*].Association.PublicIp' --output text))
	@echo "Attempting to configure ingress with IP Address $(IP)"

camunda-values-aws.yaml: await-elb elb-ip-address
	sed "s/127.0.0.1/$(IP)/g;" ../ingress-nginx/camunda-values.yaml > ./camunda-values-aws.yaml

.PHONY: await-elb
await-elb:
	./aws-ingress.sh