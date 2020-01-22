# Zeebe Helm Profiles
Repository with a set of Helm values files for Zeebe Helm Charts. 

The current profiles for the Zeebe Full Helm Chart are: 
- Default: default.yaml
- Zeebe Core Team: zeebe-core-team.yaml

You can install these profiles with: 
```
helm install <RELEASE NAME> zeebe/zeebe-full -v <PROFILE YAML FILE>
```
