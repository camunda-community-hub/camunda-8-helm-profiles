# Zeebe Helm Profiles
Repository with a set of Helm values files for Zeebe Helm Charts. 

The current profiles for the Zeebe Full Helm Chart are: 
- Default: default.yaml
- Zeebe Core Team: zeebe-core-team.yaml
- Zeebe Dev: zeebe-dev-profile.yaml

You can install these profiles with: 
```
helm install <RELEASE NAME> zeebe/zeebe-full -v <PROFILE YAML FILE>
```
example

```
helm install test-core zeebe/zeebe-full -v https://raw.githubusercontent.com/zeebe-io/zeebe-helm-profiles/master/zeebe-core-team.yaml
```

Or the Dev Profile:

```
helm install test-core zeebe/zeebe-full -v https://raw.githubusercontent.com/zeebe-io/zeebe-helm-profiles/master/zeebe-dev-profile.yaml
```

## Adding ZeeQS and TaskList

You can install the Zeebe Full Helm Chart to include ZeeQS and TaskList

```
helm install zeebe zeebe-jx/zeebe-full --set tasklist.enabled=true --set zeeqs.enabled=true
```
