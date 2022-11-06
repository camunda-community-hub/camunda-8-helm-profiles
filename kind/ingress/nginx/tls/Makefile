# ------------------------------------
# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster

certEmail ?= YOUR_EMAIL@yourdomain.com

# ------------------------------------
# The following variables should not be changed except for advanced use cases

root ?= $(shell pwd)/../../../..

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

#chartValues ?= $(root)/development/camunda-values.yaml
chartValues ?= $(root)/kind/ingress/nginx/tls/camunda-values-nginx-localhost.yaml

.PHONY: all
all: ingress-nginx-kind cert-manager letsencrypt-staging camunda-values-nginx-localhost.yaml camunda annotate-ingress-tls external-urls

# 0 kube from cluster.mk: Create Kubernetes cluster. (No aplication gateway required)
.PHONY: kube
kube: kube-kind

# 1 cert-manager from cert-manager.mk: create certificate manager for tls

# 2 letsencrypt-staging/-prod from cert-manager.mk: create letsencrypt cert issuer

# 3 create nginx ingress controller with dns and tls

# 4 create camunda-values-nginx-localhost.yaml with localhost ip
camunda-values-nginx-localhost.yaml:
	sed "s/YOUR_HOSTNAME/127.0.0.1.nip.io/g;" $(root)/kind/ingress/nginx/tls/camunda-values.yaml > $(root)/kind/ingress/nginx/tls/camunda-values-nginx-localhost.yaml

# 5 helm install camunda from camunda.mk with own tls config, combined ingress

# 6 annotate-ingress-tls from cert-manager.mk: add cluster-issuer annotation to nginx

# 7 Show external URLs
.PHONY: external-urls
external-urls:
	@echo https://127.0.0.1.nip.io/auth
	@echo https://127.0.0.1.nip.io/identity
	@echo https://127.0.0.1.nip.io/operate
#	@echo https://127.0.0.1.nip.io/tasklist
#	@echo https://127.0.0.1.nip.io/optimize
	@echo zbctl status --address 127.0.0.1.nip.io:443

.PHONY: clean-kube
clean-kube: clean-kube-kind

.PHONY: clean
clean: clean-camunda clean-ingress clean-cert-manager
	rm -f $(root)/kind/ingress/nginx/tls/camunda-values-nginx-localhost.yaml

include $(root)/include/camunda.mk
include $(root)/include/ingress-nginx.mk
include $(root)/include/cert-manager.mk
include $(root)/kind/include/kubernetes-kind.mk
