[![Community Extension](https://img.shields.io/badge/Community%20Extension-An%20open%20source%20community%20maintained%20project-FF4700)](https://github.com/camunda-community-hub/community)
[![Lifecycle; Incubating](https://img.shields.io/badge/Lifecycle-Proof%20of%20Concept-blueviolet)](https://github.com/Camunda-Community-Hub/community/blob/main/extension-lifecycle.md#proof-of-concept-)[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Compatible with: Camunda Platform 8](https://img.shields.io/badge/Compatible%20with-Camunda%20Platform%208-0072Ce)

# Camunda 8 docker-compose profile

This is a docker-compose file that will deploy a Zeebe Gateway + 3 Zeebe Brokers

For official Camunda Docker Compose files, please visit [https://github.com/camunda/camunda-platform](https://github.com/camunda/camunda-platform). 

# Usage

To use this file, make sure you have [docker](https://docs.docker.com/compose/) installed. Open a terminal, `cd` into
this directory, and then run `make`

The containers will take a few minutes to start. Use `make health` to check their status as they start up. When 
the environment is fully ready, each container should report a `healthy` status. 

![](healthy_containers.png)

Verify that you can connect to the environment using `zbctl` like so:  

```shell
zbctl --insecure status
```

![](zbctl_status.png)

To stop and delete the containers, run this command: 

```shell
make clean
```
