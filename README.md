[![Community Extension](https://img.shields.io/badge/Community%20Extension-An%20open%20source%20community%20maintained%20project-FF4700)](https://github.com/camunda-community-hub/community)
[![Lifecycle; Incubating](https://img.shields.io/badge/Lifecycle-Proof%20of%20Concept-blueviolet)](https://github.com/Camunda-Community-Hub/community/blob/main/extension-lifecycle.md#proof-of-concept-)[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Compatible with: Camunda Platform 8](https://img.shields.io/badge/Compatible%20with-Camunda%20Platform%208-0072Ce)

# Camunda 8 Helm Profiles

This is a Community Project that helps to install Camunda and other supporting technologies into Kubernetes.

Those who are already familiar with DevOps and Kubernetes may find it easier, and more flexible, to use the official [Camunda Helm Charts](https://github.com/camunda/camunda-platform-helm) along with your own methods and tools. 

For those looking for more guidance, this project provides `Makefiles`, along with custom scripts and `camunda-values.yaml` files to help with: 

- Creating Kubernetes Clusters from scratch in several popular cloud providers, including Google Cloud Platform, Azure, AWS, and Kind. 

- Installing Camunda into existing Kubernetes Clusters by providing `camunda-values.yaml` pre-configured for specific use cases. 

- Automating common tasks, such as installing Ingress controllers, configuring temporary TLS certificates, installing Prometheus and Grafana for metrics, etc.  

## How is it Organized?

Each subfolder of this project is intended to support a specific (and opinionated) use case (aka "profile").

The [Azure Nginx Ingress TLS profile](azure/ingress/nginx/tls/README.md) helps to create Azure Kubernetes (AKS) cluster, install Camunda, and configure an nginx ingress with temporary tls certificates.

The [AWS Nginx Ingress TLS profile](aws/ingress/nginx/tls/README.md) helps to create an AWS Kubernetes (EKS) cluster, install Camunda, and configure an nginx ingress with temporary tls certificates.

The [Google Nginx Ingress TLS profile](google/ingress/nginx/tls/README.md) helps to create an Google Kubernetes (GKE) cluster, install Camunda, and configure an nginx ingress with temporary tls certificates.

The [metrics profile](metrics/README.md) sets up a systems monitoring web dashboard using Prometheus and Grafana.

Explore the subfolders of this project fo discover more profiles. See the `README.md` file inside each profile for more information about the specific details. 

## How does it work?

Each profile contains a `Makefile`. These `Makefiles` define `Make` targets. `Make` targets use command line tools and bash scripts to accomplish the work of each profile. 

For example, let's say your use case is to have a fully working Camunda 8 Environment in an Azure AKS Cluster. `cd` into the `azure/ingress/nginx/tls` directory, and run `make`. The `Make` targets found there will use the `az` command line tool as well as `kubectl`, and `helm` commands to do the tasks needed to create a fully functioning environment. See the [Azure Nginx Ingress TLS profile](azure/ingress/nginx/tls/README.md) for more details.

# Prerequisites

Complete the following steps regardless of which cloud provider you use.

1. Clone the [Camunda 8 Helm Profiles git repository](https://github.com/camunda-community-hub/camunda-8-helm-profiles).

> **Note** As of October 2022, the [Camunda 8 Greenfield installation project](https://github.com/camunda-community-hub/camunda8-greenfield-installation) has been deprecated. All functionality from the Greenfield has been combined into the camunda-8-helm-profiles repository (the one you are currently viewing) 

2. Verify `kubectl` is installed

       kubectl --help

3. Verify `helm` is installed. Helm version must be at least `3.7.0`

       helm version

4. Verify GNU `make` is installed.

       make --version

# Ideas for new Profiles

If you have an idea for a new profile that is not yet available here, please open a [GitHub Issue](https://github.com/camunda-community-hub/camunda-8-helm-profiles/issues).

# Connecting to an existing cluster

TODO: describe how to use `make use-kube`

# Customizing Profiles

It can be convenient to pick and choose pieces of this project and customize it for your own specific purpose.

Here are some ideas and tips and tricks for customizing the scripts and tools found in this project to meet your specific needs. 

## Use several `camunda-values.yaml` files

Instead of running `make` inside the profile folder, it's possible to use of camunda values yaml files directly with Helm using:

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

# Networking with nip.io

There are 2 techniques to setup networking for a Camunda 8 Environment. 

1. Serve each application using a separate domain name. For example: 

```shell
identity.mydomain.com
operate.mydomain.com
tasklist.mydomain.com
optimize.mydomain.com
```

2. Use a single domain, and serve each application as a different context path. For example: 

```shell
mydomain.com/identity
mydomain.com/operate
mydomain.com/tasklist
mydomain.com/optimize
```

Kubernetes Networking is, of course, a very complicated topic! There are many ways to configure Ingress and networks. And to make things worse, each cloud provider has a slightly different flavor of load
balancers and network configuration options.

For a variety of reasons, it's often convenient (and sometimes required) to access services via dns names rather than IP addresses.

Provisioning a custom domain name can be time-consuming and complicated, especially for demonstrations or prototypes. 

Here's a technique using a public service called [nip.io](https://nip.io) that might be useful. [nip.io](https://nip.io) makes it possible to quickly and easily translate ip addresses into domain names.

[nip.io](https://nip.io) provides dynamic domain names for any ip address. For example, if your ip address is `1.2.3.4`, a doman name like `my-domain.1.2.3.4.nip.io` will resolve to ip address `1.2.3.4`.

So, for example, say our Cloud provider created a Load Balancer listening on ip address `54.210.85.151`. We can configure our environment to use dns names like this: 

```shell
http://identity.54.210.85.151.nip.io
http://keycloak.54.210.85.151.nip.io
http://operate.54.210.85.151.nip.io
http://tasklist.54.210.85.151.nip.io
```

Several of the profiles in this project use [nip.io](https://nip.io) for convenience. You're always welcome (and encouraged!) to substitute your own domain name. To do so, you will need to make some manual configuration changes to the `camunda-values.yaml` files.  
