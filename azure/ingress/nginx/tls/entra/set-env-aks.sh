export certEmail="xxx"
export clusterName="xxx"
export resourceGroup="xxx-rg"

export camundaVersion=8.6.7
export camundaHelmVersion=11.1.1

# Use this to configure Google DNS
export dnsLabel="your-dns-label"
export baseDomainName="your.domain.name"
export dnsManagedZone="your-managed-zone-name"

export region="eastus"
export namespace="camunda"

export machineType=Standard_A8_v2
export minSize=1
export maxSize=6

# Prior to 8.6.6, Web Modeler docker images required credentials. However, the image is now freely available
#export camundaDockerRegistrySecretName="camunda-docker-registry"
#export camundaDockerRegistryUrl="https://registry.camunda.cloud/"
#export camundaDockerRegistryUsername="xxx"
#export camundaDockerRegistryPassword="xxx"
#export camundaDockerRegistryEmail="xxx"

# This is only relevant for performing backups
export awsKey="xxx"
export awsSecret="xxx"
export backupId="backup01"
export elasticsearchUrl="http://elasticsearch-master:9200"
export s3BucketName="my-bucket"
export s3BucketRegion="us-east-1"

export addressPrefix="10.1.0.0/16"
export nodeSubnetPrefix="10.1.240.0/24"
export podSubnetPrefix="10.1.241.0/24"
export serviceCidr="10.0.1.0/24"
export dnsServiceIp="10.0.1.10"
export dnsLBIp="20.104.45.90"

export regions=1
export regionId=0

export entraTentantId="entra-tenant-id"
export entraAppId="entra-app-id"
export entraClientSecret="entra-client-secret"
export entraAdminUserOid="entra-admin-user-id"

# echo demo | base64
# export base64Secret="ZGVtbwo="