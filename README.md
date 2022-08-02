[![Community Extension](https://img.shields.io/badge/Community%20Extension-An%20open%20source%20community%20maintained%20project-FF4700)](https://github.com/camunda-community-hub/community)
[![Lifecycle; Incubating](https://img.shields.io/badge/Lifecycle-Proof%20of%20Concept-blueviolet)](https://github.com/Camunda-Community-Hub/community/blob/main/extension-lifecycle.md#proof-of-concept-)[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# Camunda 8 Helm Profiles
Repository with a collection of [Helm](https://helm.sh/) values files for the [Camunda Platform Helm Chart](https://helm.camunda.io/). 

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
helm install test-core camunda/camunda-platform --values https://raw.githubusercontent.com/camunda-community-hub/zeebe-helm-profiles/master/zeebe-core-team.yaml
```

Or the Dev Profile (can be used with kind):

```
helm install test-core camunda/camunda-platform --values https://raw.githubusercontent.com/camunda-community-hub/zeebe-helm-profiles/master/zeebe-dev-profile.yaml
```

## Adding ZeeQS and TaskList

You can install the Zeebe Full Helm Chart to include ZeeQS and TaskList

```
helm install zeebe camunda/camunda-platform --set tasklist.enabled=true --set zeeqs.enabled=true
```
