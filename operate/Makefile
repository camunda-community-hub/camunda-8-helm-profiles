# ------------------------------------
# Set the following for your specific environment

# Configure the fully qualified domain name
# The dnsLabel is the first part of the domain address. It will be used no matter what baseDomain you configure below
dnsLabel ?= YOUR_DNS_LABEL

# By default, we'll use nip.io (See more at [https://nip.io](http://nip.io) )
# The fully qualified domain name will look something like <dnsLabel>.<ip address>.nip.io
# baseDomainName ?= nip.io

# Another option is to replace baseDomainName with your own domain name
# In this case, the fully qualified domain name will look like <dnsLabel>.<baseDomainName>
baseDomainName ?= YOUR_DOMAIN_NAME

# Only used for oauth2-proxy
# clientSecret ?= CLIENT_SECRET

# ------------------------------------
# The following variables should not be changed except for advanced use cases

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/..
else
    root ?= $(shell pwd)/..
endif

include $(root)/include/ingress-nginx.mk
include $(root)/operate/include/operate.mk
