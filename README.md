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

The [makefiles](./makefiles) directory contains  Makefile targets to support common tasks across multiple cloud providers.

The [camunda-values.d](./camunda-values.d) directory contains reusable Helm values files that can be composed together to create different Camunda Platform 8 configurations. Each file provides a specific configuration aspect that can be mixed and matched across different profiles, aka, `recipes`. 

The [recipes](./recipes) directory contains `Makefiles` and `camunda-values.yaml` files to support specific use cases.

## How does it work?

Each profile contains a `Makefile`. These `Makefiles` define `Make` targets. `Make` targets use command line tools and bash scripts to accomplish the work of each profile. 

For example, let's say your use case is to have a fully working Camunda 8 Environment in an Azure AKS Cluster. `cd` into the `azure/ingress/nginx/tls` directory, and run `make`. The `Make` targets found there will use the `az` command line tool as well as `kubectl`, and `helm` commands to do the tasks needed to create a fully functioning environment. See the [Azure Nginx Ingress TLS profile](azure/ingress/nginx/tls/README.md) for more details.

# Prerequisites

Complete the following steps regardless of which cloud provider you use.

1. Clone the [Camunda 8 Helm Profiles git repository](https://github.com/camunda-community-hub/camunda-8-helm-profiles).

2. Verify GNU `make` is installed.

       make --version

Each recipe may have additional prerequisites. See the `README.md` file inside each recipe for more details.
