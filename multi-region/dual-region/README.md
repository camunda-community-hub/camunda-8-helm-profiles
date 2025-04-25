# Experimental Camunda 2.5-Datacenter Setup with nearby 2 Primary Datacenters

Warning: This profile is not (yet) officially supported by Camunda and it assumes a low network latency between the two primary datacenters called `region0` and `region1`, i.e. less than 15 miliseconds.

Zeebe is installed as a [dual-region active-active stretch cluster](https://docs.camunda.io/docs/self-managed/concepts/multi-region/dual-region/):
![Zeebe dual-region active-active stretch cluster](https://github.com/camunda/camunda-docs/blob/main/versioned_docs/version-8.7/self-managed/concepts/multi-region/img/dual-region.svg)

In opposite to the above picture/documentation, Elasticsearch is installed as a single cluster stretching across 2.5 datacenters:
[![Elasticsearch 2.5-region stretch cluster](https://media.licdn.com/dms/image/v2/D5612AQEXNDJ8c1DCVw/article-inline_image-shrink_1500_2232/article-inline_image-shrink_1500_2232/0/1667946099753?e=1750896000&v=beta&t=ItGnEzQnubzaaBcgMzqRgkc76NGGIognTjZbPN0ii78)](https://www.linkedin.com/pulse/building-on-prem-multi-datacenter-stretch-cluster-senguttuvan/)

Adjust the config.mk files in the region subfolders before running `make` either in the region folders or even in the root. You can run `make help` to see available targets. Running `make --dry-run` shows a preview of the commands to be executed.
