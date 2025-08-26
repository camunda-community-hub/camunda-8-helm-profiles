.PHONY: all # install Camunda in both regions
all:
	$(MAKE) -C region0
	$(MAKE) -C region1

.PHONY: clean # uninstall Camunda from both regions
clean:
	$(MAKE) -C region0 clean
	$(MAKE) -C region1 clean

.PHONY: values # generate YAML snippets from namespace and region
values:
	. ./export_environment_prerequisites.sh; \
	./generate_zeebe_helm_values.sh

.PHONY: help # print this help
help:
	@grep -oP '^\.PHONY: \K.*' Makefile | sed 's/#/\t/'

########################################################################
# The following targets are for maintainers

.PHONY: meld-regions # maintain region directories in sync
meld-regions:
	meld region0/ region1/

.PHONY: meld-scripts # maintain shell scripts in sync with Camunda docs
meld-scripts:
	meld . ../../../c8-multi-region/aws/dual-region/scripts/

.PHONY: meld-values # maintain camunda-values.yaml in sync with Camunda docs
meld-values:
	meld ../../camunda-values.d/dual-region.yaml ../../../c8-multi-region/aws/dual-region/kubernetes/camunda-values.yml
