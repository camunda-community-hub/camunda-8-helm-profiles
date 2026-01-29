## In progress / Known Issues

## January 2026

- Major reorganization of the project
- Environment variables are now all uppercase with underscores
- Makefiles are now all found inside the `makefiles` directory
- New `recipes` directory will contain all the existing profiles plus new ones for 8.8
- Cloud provider folders have been removed. There are recipes for cloud providers now.
- camunda-values.yaml.d directory contains all helm values yaml files

## May 16, 2023

- Many improvements made in preparation for the Community Summit Workshop
- Updated profiles to use Camunda version 8.2.3 Helm Chart by default
- All non-tls profiles are using 8.2.3 of Camunda 8 Platform
- All tls profiles are using 8.3.0-alpha0 of Camunda 8 Platform
- Regression tested each cloud provider development profile
- Regression tested each cloud provider `ingress/nginx` profile
- Regression tested each cloud provider `ingress/nginx/tls` profile
- Enabled [Connectors](https://docs.camunda.io/docs/components/connectors/use-connectors/) in profiles
- Fixed Azure networking issue related to Azure Load Balancer Health Probes. We add /healthz to load balancer paths by default  
- The `deploy-models` target was moved out of the benchmark profile and refactored slightly to be more reusable. See examples inside [bpmn/deploy-models.mk](bpmn/deploy-models.mk)
- renamed `kube-nginx` target in azure profile to be kube-azure

## Before May 2023 Camunda v8.1.x, Helm Profiles 0.0.1

- This helm profile project existed since early 2022, but we did not start this CHANGELOG until May 2023. 
- Before then, Helm profiles supported Camunda version 8.1.x
