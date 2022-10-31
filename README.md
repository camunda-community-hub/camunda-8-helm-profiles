[![Community Extension](https://img.shields.io/badge/Community%20Extension-An%20open%20source%20community%20maintained%20project-FF4700)](https://github.com/camunda-community-hub/community)
[![Lifecycle; Incubating](https://img.shields.io/badge/Lifecycle-Proof%20of%20Concept-blueviolet)](https://github.com/Camunda-Community-Hub/community/blob/main/extension-lifecycle.md#proof-of-concept-)[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Compatible with: Camunda Platform 8](https://img.shields.io/badge/Compatible%20with-Camunda%20Platform%208-0072Ce)

# Camunda 8 Helm Profiles

## What is this?

This is a Community Project that helps to install Camunda and other supporting technologies into Kubernetes.

If you're a DevOps Kubernetes expert, you may find it easier to use the official [Camunda Helm Charts](https://github.com/camunda/camunda-platform-helm) along with your own methods and tools. 

However, for the rest of us, this project provides `Makefiles`, along with custom scripts and `camunda-values.yaml` files, to help install Camunda into Kubernetes.

If you don't yet have access to a Kubernetes cluster, this project provides scripts to help create a Kubernetes Cluster from scratch in several popular cloud providers, including Google Cloud Platform, Azure, AWS, and Kind. 

If you already have access to a cluster, this project provides scripts to help automate tasks such as installing and configuring Camunda, installing Nginx Ingress controllers, configuring TLS certificates and more. 

## How is it Organized?

Each subfolder of this project is designed to support a specific (and opinionated) use case (aka "profile").

For example, the `azure/nginx/tls` profile contains everything needed to create a new AKS Cluster, and setup Camunda with TLS nginx ingress.

Another example, the `ingress-nginx` profile, contains everything needed to set up a nginx ingress into an existing kubernetes environment. This profile can be used in any could provider as long as you have a `kubectl` connection. 

Another example, the `metrics` profile, contains everything needed to setup prometheus and grafana. This way, you will have access to a Web dashboard showing runtime statistics of your environment. 

Please see the `README.md` file inside each profile for more information about the specific use cases. 

## How does it work?

Each profile contains a `Makefile`. These `Makefiles` define `Make` targets to accomplish the work of each profile. 

For example, let's say your use case is to have a fully working Camunda 8 Environment in an Azure AKS Cluster. Simply `cd` into the `azure/nginx/tls` directory, and run `make`. The `Make` targets found there will use the `az` command line tool as well as `kubectl`, and `helm` command line tools to do the tasks needed to create a fully functioning environment. See `azure/nginx/tls/README.md` for more details.

# Prerequisites

Complete the following steps regardless of which cloud provider you use.

1. Clone the [Camunda 8 Helm Profiles git repository](https://github.com/camunda-community-hub/camunda-8-helm-profiles).

> **Note** As of October 2022, the [Camunda 8 Greenfield installation project](https://github.com/camunda-community-hub/camunda8-greenfield-installation) has been deprecated. All functionality has been moved from the Greenfield Project into this one. 

2. Verify `kubectl` is installed

       kubectl --help

3. Verify `helm` is installed. Helm version must be at least `3.7.0`

       helm version

4. Verify GNU `make` is installed.

       make --version

### Next Steps

If you need to create a brand new Kubernetes Cluster, see the "Cloud-platform-specific Profiles" below. 

If you already have a Kubernetes Cluster, take a look at the "General Profiles" in the section below.

# Profiles

Conceptually, profiles are divided into 2 categories: Cloud-specific, or General. 

1. If you're starting from scratch, and don't yet have a Kubernetes Cluster, the Cloud-platform-specific profiles listed below can help you create a new cluster quickly and easily. 

2. If you already access to an existing Kubernetes Cluster, then use the General Profiles to install additional software into an existing Kubernetes Cluster.

## Ideas for new Profiles
If you have an idea for a new profile that is not yet available here, please open a [GitHub Issue](https://github.com/camunda-community-hub/camunda-8-helm-profiles/issues).

## Cloud-platform-specific Profiles

The profiles listed in this section can help you to create Kubernetes Clusters in a specific cloud provider such as Azure, Google, AWS, or Kind.

If you have an existing cluster in a cloud provider, these profiles can help to install Camunda in that environment. 

- [Azure AKS Cluster with nginx ingress over TLS](https://github.com/camunda-community/camunda-8-helm-profiles/azure/nginx/tls/README.md)
- Google - TODO
- AWS - TODO
- KIND / Developer - TODO

## General Profiles

The following profiles can be run against an existing Kubernetes Cluster. If you don't yet have a Kubernetes Cluster see the sections below for help to create a brand-new cluster.

- [Default Camunda Install in any Kubernetes Environment](https://github.com/camunda-community/camunda-8-helm-profiles/azure/nginx/tls/README.md)
- [Development Environment](https://github.com/camunda-community/camunda-8-helm-profiles/development/README.md)
- [Nginx Ingress](https://github.com/camunda-community/camunda-8-helm-profiles/development/README.md)
- Metrics - TODO
- Benchmark - TODO

# Connecting to an existing cluster

TODO: describe how to use `make use-kube`

# Customizing Profiles

It can be convenient to pick and choose pieces of this project and customize it for your own specific purpose.

Here are some ideas and tips and tricks for customizing the scripts and tools found in this project to meet your specific needs. 

## Use several `camunda-values.yaml` files

Instaad of running `make` inside the profile folder, it's possible to use of camunda values yaml files directly with Helm using:

```
helm install <RELEASE NAME> camunda/camunda-platform --values <PROFILE YAML FILE>
```

For example, here's how to run helm using the development version of `camunda-values.yaml`: 

```
helm install test-core camunda/camunda-platform --values https://raw.githubusercontent.com/camunda-community-hub/camunda-8-helm-profiles/master/development/camunda-values.yaml
```

Or, as another example, you might manually edit the `ingress-nginx/camunda-values.yaml` file, and replace `127.0.0.1` urls with your custom domain name. Then you could run the following to install camunda with ingress rules for your custom domain: 

```
helm install test-core camunda/camunda-platform --values ingress-nginx/camunda-values.yaml
```

