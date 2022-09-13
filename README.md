[![Community Extension](https://img.shields.io/badge/Community%20Extension-An%20open%20source%20community%20maintained%20project-FF4700)](https://github.com/camunda-community-hub/community)
[![Lifecycle; Incubating](https://img.shields.io/badge/Lifecycle-Proof%20of%20Concept-blueviolet)](https://github.com/Camunda-Community-Hub/community/blob/main/extension-lifecycle.md#proof-of-concept-)[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Compatible with: Camunda Platform 8](https://img.shields.io/badge/Compatible%20with-Camunda%20Platform%208-0072Ce)

# Camunda 8 Helm Profiles
Repository with a collection of [Helm](https://helm.sh/) values files
for installing the [Camunda Platform Helm Chart](https://helm.camunda.io/)
on an existing Kubernetes cluster (if you don't have one yet,
see [Camunda 8 Kubernetes Installation](https://github.com/camunda-community-hub/camunda8-greenfield-installation)).

Each subfolder of this repository (except the `include` folder)
contains a profile for installing Camunda Platform,
i.e. YAML file with chart values and maybe a `Makefile` to automate the installation.

You can install these profiles by running `make` inside the profile folder
or directly with Helm using: 
```
helm install <RELEASE NAME> camunda/camunda-platform -v <PROFILE YAML FILE>
```
example

```
helm install test-core camunda/camunda-platform --values https://raw.githubusercontent.com/camunda-community-hub/camunda-8-helm-profiles/master/ingress-nginx/camunda-values.yaml
```

Or the development profile, which can be used with KIND:

```
helm install test-core camunda/camunda-platform --values https://raw.githubusercontent.com/camunda-community-hub/camunda-8-helm-profiles/master/development/camunda-values.yaml
```
