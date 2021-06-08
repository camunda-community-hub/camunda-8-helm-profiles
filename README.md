[![Community Extension](https://img.shields.io/badge/Community%20Extension-An%20open%20source%20community%20maintained%20project-FF4700)](https://github.com/camunda-community-hub/community)
[![Lifecycle; Incubating](https://img.shields.io/badge/Lifecycle-Proof%20of%20Concept-blueviolet)](https://github.com/Camunda-Community-Hub/community/blob/main/extension-lifecycle.md#proof-of-concept-)[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# Zeebe Helm Profiles
Repository with a set of Helm values files for Zeebe Helm Charts. 

The current profiles for the Zeebe Full Helm Chart are: 
- Default: default.yaml
- Zeebe Core Team: zeebe-core-team.yaml
- Zeebe Dev: zeebe-dev-profile.yaml

You can install these profiles with: 
```
helm install <RELEASE NAME> zeebe/zeebe-full-helm -v <PROFILE YAML FILE>
```
example

```
helm install test-core zeebe/zeebe-full-helm --values https://raw.githubusercontent.com/zeebe-io/zeebe-helm-profiles/master/zeebe-core-team.yaml
```

Or the Dev Profile:

```
helm install test-core zeebe/zeebe-full-helm --values https://raw.githubusercontent.com/zeebe-io/zeebe-helm-profiles/master/zeebe-dev-profile.yaml
```

## Adding ZeeQS and TaskList

You can install the Zeebe Full Helm Chart to include ZeeQS and TaskList

```
helm install zeebe zeebe/zeebe-full-helm --set tasklist.enabled=true --set zeeqs.enabled=true
```
