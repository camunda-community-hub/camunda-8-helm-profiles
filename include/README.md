This folder does not contain a Helm profile but common scripts and configuration files, e.g. for GNU Make,
that are shared among multiple profiles.

[camunda.mk](camunda.mk) is the installation script that is included in the `Makefile` of all Helm profiles.
It contains targets to install, update, and remove Camunda via Helm as well as
watch/await pods, get logs, forward ports, and open URLs with `kubectl`

[ingress-nginx.mk](ingress-nginx.mk) is the installation script for an Nginx Ingress Controller and getting its IP.

[cert-manager.mk](cert-manager..mk) is the installation script for setting up Kubernetes objects for issuing letsencrypt tls certificates
