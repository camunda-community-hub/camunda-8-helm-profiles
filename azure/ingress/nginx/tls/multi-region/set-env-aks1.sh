export certEmail=david.paroulek@camunda.com
export clusterName=dave01
export resourceGroup=dave01-rg

export camundaVersion=8.4.1
export camundaHelmVersion=9.0.1

export dnsLabel=dave01
export baseDomainName=aks.c8sm.com
#export baseDomainName=eastus.cloudapp.azure.com
export dnsManagedZone=aks

export region=eastus
export namespace=camunda-eastus
export namespace2=camunda-canadacentral

export machineType=Standard_A8_v2
export minSize=1
export maxSize=6

export camundaDockerRegistrySecretName="camunda-docker-registry"
export camundaDockerRegistryUrl="https://registry.camunda.cloud/"
export camundaDockerRegistryUsername="xxx"
export camundaDockerRegistryPassword="xxx"
export camundaDockerRegistryEmail="xxx"

export addressPrefix="10.1.0.0/16"
export nodeSubnetPrefix="10.1.240.0/24"
export podSubnetPrefix="10.1.241.0/24"
export serviceCidr="10.0.1.0/24"
export dnsServiceIp="10.0.1.10"
export dnsLBIp="20.104.45.90"

export regions=2
export regionId=0