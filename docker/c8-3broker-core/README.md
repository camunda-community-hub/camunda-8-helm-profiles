[![Community Extension](https://img.shields.io/badge/Community%20Extension-An%20open%20source%20community%20maintained%20project-FF4700)](https://github.com/camunda-community-hub/community)
[![Lifecycle; Incubating](https://img.shields.io/badge/Lifecycle-Proof%20of%20Concept-blueviolet)](https://github.com/Camunda-Community-Hub/community/blob/main/extension-lifecycle.md#proof-of-concept-)[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Compatible with: Camunda Platform 8](https://img.shields.io/badge/Compatible%20with-Camunda%20Platform%208-0072Ce)

# Camunda 8 docker-compose profile

This is meant for experimentation. Additional Camunda docker-compose files can be found at [https://github.com/camunda/camunda-platform](https://github.com/camunda/camunda-platform).

This is a sample docker-compose file that will deploy the following: 

- Zeebe Gateway (service is named zeebe)
- 3 Zeebe Brokers
- Elasticsearch
- Tasklist
- Operate
- Connectors

# Usage

To use this file, make sure you have [docker](https://docs.docker.com/compose/) installed.

By default, this will install the latest stable version of Camunda 8 Platform. Specify a different version by setting `CAMUNDA_PLATFORM_VERSION` variable, for example:

```shell
export CAMUNDA_PLATFORM_VERSION=8.2.0-alpha5
```

Open a terminal, `cd` into this directory, and then run `make`

The containers will take a few minutes to start. Use `make status` to check their health as they start up. When the environment is fully ready, each container should report a `healthy` status. 

![](healthy_containers.png)

Verify that you can connect to the environment using `zbctl`:  

```shell
zbctl --insecure status
```

![](zbctl_status.png)

To stop and delete the containers, run this command: 

```shell
make clean
```
