FROM google/cloud-sdk:alpine

ARG ARCH

# Ignore to update versions here
# docker build --no-cache --build-arg KUBECTL_VERSION=${tag} --build-arg HELM_VERSION=${helm} --build-arg KUSTOMIZE_VERSION=${kustomize_version} -t ${image}:${tag} .
ARG HELM_VERSION=3.9.0
ARG KUBECTL_VERSION=1.27.2

# Install helm (latest release)
# ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
RUN case `uname -m` in \
    x86_64) ARCH=amd64; ;; \
    armv7l) ARCH=arm; ;; \
    aarch64) ARCH=arm64; ;; \
    ppc64le) ARCH=ppc64le; ;; \
    s390x) ARCH=s390x; ;; \
    *) echo "un-supported arch, exit ..."; exit 1; ;; \
    esac && \
    echo "export ARCH=$ARCH" > /envfile && \
    cat /envfile

RUN . /envfile && echo $ARCH && \
    apk add --update --no-cache curl ca-certificates bash git && \
    curl -sL https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz | tar -xvz && \
    mv linux-${ARCH}/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-${ARCH}

# Install kubectl
RUN . /envfile && echo $ARCH && \
    curl -sLO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl && \
    mv kubectl /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl

# Install jq
RUN apk add --update --no-cache jq yq

# Install for envsubst
RUN apk add --update --no-cache gettext

# Install make
RUN apk add --no-cache make

# Install gke-gcloud-auth-plugin
RUN gcloud components install gke-gcloud-auth-plugin

ADD --chmod=755 bpmn /apps/camunda-8-helm-profiles/bpmn
ADD --chmod=755 echo-server /apps/camunda-8-helm-profiles/echo-server
ADD --chmod=755 google /apps/camunda-8-helm-profiles/google
ADD --chmod=755 include /apps/camunda-8-helm-profiles/include
ADD --chmod=755 ingress-nginx /apps/camunda-8-helm-profiles/ingress-nginx
ADD --chmod=755 metrics /apps/camunda-8-helm-profiles/metrics
ADD --chmod=755 oauth2-proxy /apps/camunda-8-helm-profiles/oauth2-proxy
ADD --chmod=755 operate /apps/camunda-8-helm-profiles/operate
ADD --chmod=755 tasklist /apps/camunda-8-helm-profiles/tasklist

WORKDIR /apps/camunda-8-helm-profiles/google/ingress/nginx/tls