# Helm Profiles for Camunda 8 on Kind

It's possible to use `kind` to experiment with kubernetes on your local developer laptop, but please keep in mind that
Kubernetes is not really intended to be run on a single machine. That being said, this can be handy for learning and
experimenting with Kubernetes.

Create a Camunda 8 self-managed Kubernetes Cluster in 3 Steps:

Step 1: Setup some [global prerequisites](../README.md#prerequisites)

Step 2: Setup command line tools and software for Kind:

1. Make sure to install Docker Desktop (https://www.docker.com/products/docker-desktop/)

2. Make sure that `kind` is installed (https://kind.sigs.k8s.io/)

Again, keep in mind that `kind` is an emulated kubernetes cluster meant only for development!

3. Use `Makefile` inside the `kind` directory to create a k8s cluster and install Camunda.

```shell
cd kind
make kube
```

This will create a new `kind` cluster in Docker Desktop

Run the following command to install Camunda

```shell
cd kind
make
```

The Kind environment is a stripped down version without ingress and without identity enabled. So, once pods start up, try using port forwarding to access them.

For example, try `make port-operate`, and then access operate at this url: 

http://localhost:8081

Or, try `make port-tasklist`, and then access task list here: 

http://localhost:8082

To access Zeebe via grpc, run `make port-zeebe`, then try: 

```shell
zbctl status --address localhost:26500 --insecure
```
