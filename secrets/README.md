# Create secrets for Camunda 8

Use the following to manage k8s secrets object for the Camunda 8 credentials. 

Set `$defaultPassword` in your Makefile like this: 

```
defaultPassword ?= camunda
```

Then run the following command to create a k8s secret object named `camunda-credentials` (which is what the helm chart uses by default) 

```shell
make camunda-credentials
```

Use the following to remove the k8s secret object for the Camunda 8 credentials.

```shell
make clean-camunda-credentials
```