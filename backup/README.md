[![Community Extension](https://img.shields.io/badge/Community%20Extension-An%20open%20source%20community%20maintained%20project-FF4700)](https://github.com/camunda-community-hub/community)
[![Lifecycle; Incubating](https://img.shields.io/badge/Lifecycle-Proof%20of%20Concept-blueviolet)](https://github.com/Camunda-Community-Hub/community/blob/main/extension-lifecycle.md#proof-of-concept-)[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Compatible with: Camunda Platform 8](https://img.shields.io/badge/Compatible%20with-Camunda%20Platform%208-0072Ce)

# Camunda Backup Script

[This page](https://docs.camunda.io/docs/self-managed/operational-guides/backup-restore/backup-and-restore/) provides a list of steps necessary to create a backup of a Camunda Self Managed environment. These steps require [cluster level Elasticsearch privileges](https://docs.camunda.io/docs/self-managed/concepts/elasticsearch-privileges/)

In some cases, because of Security Policies, it is not possible to grant the Camunda applications the elastic search cluster level access necessary to run the backup steps.  

As a possible workaround to this problem, this directory contains a [backup.sh](backup.sh) script that is possible to run from outside a Camunda Kubernetes Cluster.

# Prerequisites

## Setup an S3 Bucket

1. Create a S3 bucket
2. Grant access from elastic search to the s3 bucket

There are many ways to configure access to an S3 bucket and covering all the ways to configure AWS authorization is definitely out of scope for this guide. But, I'll share one technique here for convenience. One technique is to grant access to an IAM user using an inline policy like this:
```json
{
	"Version": "2012-10-17",
	"Statement": [
	    {
	        "Action": [
	            "s3:*"
	   ],
	   "Effect": "Allow",
	   "Resource": [
        "arn:aws:s3:::bucket-name",
        "arn:aws:s3:::bucket-name/*"
      ] 
    }
	]
}
```
Then, create an [Access Key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) for your IAM user.

Create a Kubernetes Secret to store your AWS key and secret from the access key like so:

```shell
   kubectl create secret generic aws-credentials --from-literal=key=YOUR_AWS_KEY --from-literal=secret=YOUR_AWS_SECRET
```

# Configure Elasticsearch S3 Plugin and Client

## How to verify Elasticsearch is configured

Open a shell to one of your elasticsearch pods and run the following command: `elasticsearch-keystore list`. If you see `s3.client.*` keys defined, then this is probably good to go. 

```shell
camunda-elasticsearch-master-0> elasticsearch-keystore list
bootstrap.password
keystore.seed
s3.client.default.access_key
s3.client.default.secret_key
```

## Create Secret

Create a k8s secret containing your S3 bucket client id and secret:

```
kubectl create secret generic aws-credentials  \
 --from-literal=key=xxx \
 --from-literal=secret=xxx
```

Or, feel free to use the make target: 
`make create-aws-credentials-secret` which is located inside [backup.mk](backup.mk). Note you'll need to set env variables for `awsKey` and `awsSecret`. 

## Configure ES to know how to communicate with S3

> [!NOTE]  
> This step is slightly different depending on the version of Elasticsearch. Camunda 8.2.x includes Elasticsearch version 7.17.x. By default, Elasticsearch versions before 8.2 don't include the S3 snapshot repository plugin by default. However, Elasticsearch 8.2.x and above already include the required s3 plugin.

Find the version of Elasticsearch that is currently installed in your environment. [This version matrix](https://helm.camunda.io/camunda-platform/version-matrix) lists the version of Elasticsearch installed by default for each version of Camunda.

### Elasticsearch 8.2.x and above

Add the following `initScripts` definition to your Camunda `values.yaml` file under the [elasticsearch](https://github.com/camunda/camunda-platform-helm/tree/main/charts/camunda-platform#elasticsearch-parameters) section:

```shell
elasticsearch:
  initScripts:
    my_init_script.sh: |
      #!/bin/sh
      echo $AWS_KEY | elasticsearch-keystore add -f --stdin s3.client.default.access_key
      echo $AWS_SECRET | elasticsearch-keystore add -f --stdin s3.client.default.secret_key
  extraEnvVars:
    - name: AWS_KEY
      valueFrom:
        secretKeyRef:
          name: aws-credentials
          key: key
    - name: AWS_SECRET
      valueFrom:
        secretKeyRef:
          name: aws-credentials
          key: secret
                    
  extraVolumeMounts:
  - name: empty-dir
    mountPath: /bitnami/elasticsearch
    subPath: app-volume-dir
```

### Elasticsearch version before 8.2.x

Add the following `initContainer` definition to your Camunda `values.yaml` file under the [elasticsearch](https://github.com/camunda/camunda-platform-helm/tree/main/charts/camunda-platform#elasticsearch-parameters) section:

> [!INFO]  
> Remember to change the version (`YOUR_VERSION` below) of the elasticsearch image to match the current version of your existing elasticsearch

```shell
elasticsearch:
  extraInitContainers:
    - name: s3
      image: elasticsearch:YOUR_VERSION
      securityContext:
        privileged: true
      command:
        - sh
      args:
        - -c
        - |
          ./bin/elasticsearch-plugin install --batch repository-s3
          cp -a /usr/share/elasticsearch/plugins /usr/share
          ls -altr /usr/share/plugins
          echo $AWS_KEY | ./bin/elasticsearch-keystore add -f --stdin s3.client.default.access_key
          echo $AWS_SECRET | ./bin/elasticsearch-keystore add -f --stdin s3.client.default.secret_key
          cp -a /usr/share/elasticsearch/config/elasticsearch.keystore /usr/share/config
          ls -altr /usr/share/config
          echo "s3 plugin is ready!"
      volumeMounts:
        - name: plugins
          mountPath: /usr/share/plugins
        - name: keystore
          mountPath: /usr/share/config
      env:
        - name: AWS_KEY
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: key
        - name: AWS_SECRET
          valueFrom:
            secretKeyRef:
              name: aws-credentials
              key: secret
  extraVolumes:
    - name: plugins
      emptyDir: {}
    - name: keystore
      emptyDir: {}
  extraVolumeMounts:
    - name: plugins
      mountPath: /usr/share/elasticsearch/plugins
      readOnly: false
    - name: keystore
      mountPath: /usr/share/elasticsearch/config/elasticsearch.keystore
      subPath: elasticsearch.keystore
```

## Configure Zeebe to connect to the S3 Bucket

```shell
zeebe: 
  env:
    - name: ZEEBE_BROKER_EXECUTION_METRICS_EXPORTER_ENABLED
      value: "true"
    - name: ZEEBE_BROKER_DATA_BACKUP_STORE
      value: "S3"
    - name: ZEEBE_BROKER_DATA_BACKUP_S3_BUCKETNAME
      value: "YOUR_BUCKET_NAME"
    - name: ZEEBE_BROKER_DATA_BACKUP_S3_BASEPATH
      value: "zeebe-backup"
    - name: ZEEBE_BROKER_DATA_BACKUP_S3_ACCESSKEY
      valueFrom:
        secretKeyRef:
          name: aws-credentials
          key: key
    - name: ZEEBE_BROKER_DATA_BACKUP_S3_SECRETKEY
      valueFrom:
        secretKeyRef:
          name: aws-credentials
          key: secret
```

# Run the backup script

1. Port forward to the elasticsearch service

```shell
kubectl port-forward svc/camunda-elasticsearch 9200:9200 -n CAMUNDA_NAMESPACE
```
2. Edit `backup.sh` and update keys

3. Run backup.sh

