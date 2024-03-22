[![Community Extension](https://img.shields.io/badge/Community%20Extension-An%20open%20source%20community%20maintained%20project-FF4700)](https://github.com/camunda-community-hub/community)
[![Lifecycle; Incubating](https://img.shields.io/badge/Lifecycle-Proof%20of%20Concept-blueviolet)](https://github.com/Camunda-Community-Hub/community/blob/main/extension-lifecycle.md#proof-of-concept-)[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Compatible with: Camunda Platform 8](https://img.shields.io/badge/Compatible%20with-Camunda%20Platform%208-0072Ce)

# Camunda 8 Helm Profile: Azure Multi Region Installation

> [!IMPORTANT]  
> This is a very advanced topic. Successfully configuring a kubernetes cluster to span multiple
> virtual networks requires deep understanding of advanced cloud networking. You should be very
> familiar with Kubernetes before attempting this type of installation.

> [!WARNING]
> If you want Camunda enterprise support for your multi-region setup,
> you must have your configuration and run books reviewed by Camunda before going to production.
> Due to the complexity of operating multi-region setups and the dependencies on the underlying
> Kubernetes prerequisites, this is required for us to be able to assist you in the event of an
> outage. If you operate this incorrectly, you risk corrupting and losing all data, especially in
> the dual-region case. Consider three regions if possible. As soon as you begin planning a
> multi-region setup, please contact your customer success manager. Camunda reserves the right to
> restrict support if no review was performed prior to launch or if the review revealed significant
> risks.

The following describes how to install a single Camunda 8 installation so that the Zeebe brokers span across multiple regions.

## Prerequisites

If this is your first time here, make sure you have [installed the prerequisites](../../../README.md).

After you've installed the prerequisites, open a Terminal and cd into this [azure/ingress/nginx/tls/multi-region](.) directory. 

## Create an AKS Clusters

Edit the [set-env-aks1.sh](./set-env-aks1.sh) script found in this directory. Set the variables appropriately.

This will be referred to as "Region 1". The `regionId` set to `0`.

Run the following in order to create an AKS cluster in Region 1:

```shell
. ./set-env-aks1.sh
make kube
make create-dns-lb
make dns-ip
```

Make note of the external IP address of the dns load balancer in Region 1. You'll need it to setup  DNS below. 

Now do the same for Region 2. 

Edit the [set-env-aks2.sh](./set-env-aks2.sh) script found in this directory. Set the variables appropriately.

This will be referred to as "Region 2". The `regionId` set to `1`.

Run the following in order to create an AKS cluster in Region 2:

```shell
. ./set-env-aks2.sh
make kube
make create-dns-lb
make dns-ip
```

Make note of the external IP address of the dns load balancer in Region 2. You'll need it to setup  DNS below.

## Configure vNet Peering

Sign in the Azure Console and search for `Virtual Networks`. Click on the first virtual network. For example, I set my cluster name to `dave01`, so the virtual network is named `dave01-vnet`. 

After selecting the vnet, click on `Peerings`, and then click to add a new Peering. 

The screenshot below shows how to complete this form: 

![azure_vnet_peering.png](..%2F..%2F..%2F..%2F..%2Fdocs%2Fimages%2Fazure_vnet_peering.png)

Click `Add`. Wait until the `Peering status` shows `Connected`. 

## Configure CoreDNS

Configure Core DNS so that Region 1 can access domain names inside Region 2. 

Update [set-env-aks1.sh](./set-env-aks1.sh) and set the `dnsLBIp` to the DNS IP address you recorded from Region 2.
Then run the following: 

```
. ./set-env-aks1.sh
make use-kube
make create-custom-dns
```

Configure Core DNS so that Region 1 can access domain names inside Region 2. 

Update [set-env-aks2.sh](./set-env-aks2.sh) and set the `dnsLBIp` to the DNS IP address you recorded from Region 1.
Then run the following:

```
. ./set-env-aks2.sh
make use-kube
make create-custom-dns
```

## Install Camunda

Install camunda in Region 1. These steps are very similar to installing camunda inside a single region, except that the
values file that is generated contains some extra params for multi region installs. 

```
. ./set-env-aks1.sh
make use-kube
make
```

Install camunda in Region 2. 

```
. ./set-env-aks2.sh
make use-kube
make
```

## Confirm

[netshoot](https://github.com/nicolaka/netshoot) is a Docker image useful for troubleshooting networks. Let's use it to 
confirm that the two vnets are peered correctly and that we can access a pod in Region 2 from a pod in Region 1.  

```shell
. ./set-env-aks1.sh
make use-kube
make netshoot
```

This should open a ssh terminal. 

Check that we can connect to all zeebe brokers from Region 1. For example, here are the commands I used:  

```shell
tmp-shell> nslookup camunda-zeebe-0.camunda-zeebe.camunda-canadacentral.svc.cluster.local
Server:		10.0.2.10
Address:	10.0.2.10#53

Name:	camunda-zeebe-0.camunda-zeebe.camunda-canadacentral.svc.cluster.local
Address: 10.2.241.12

tmp-shell> nslookup camunda-zeebe-0.camunda-zeebe.camunda-eastus.svc.cluster.local
Server:		10.0.2.10
Address:	10.0.2.10#53

Name:	camunda-zeebe-0.camunda-zeebe.camunda-eastus.svc.cluster.local
Address: 10.1.241.15
```

Don't forget to run the same tests from Region 2!
