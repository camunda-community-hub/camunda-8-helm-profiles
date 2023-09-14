# Configure the fully qualified domain name
# The dnsLabel is the first part of the domain address. It will be used no matter what baseDomain you configure below
# Sample value:
# dnsLabel ?= your_dns_label

ifndef dnsLabel
$(error 'dnsLabel' is mandatory. To fix, edit file: $(root)/google/config/properties-dns.mk )
endif

# By default, we'll use nip.io (See more at [https://nip.io](http://nip.io) )
# The fully qualified domain name will look something like <dnsLabel>.<ip address>.nip.io
baseDomainName ?= nip.io

# Another option is to replace baseDomainName with your own domain name
# In this case, the fully qualified domain name will look like <dnsLabel>.<baseDomainName>
# baseDomainName ?= your_base_domain_name