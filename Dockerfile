FROM alpine:3.7

ENV \
  HELM_VERSION=2.11.0 \
  KOPS_VERSION=1.10.1 \
  KUBECTL_VERSION=1.10.12 \
  TERRAFORM_VERSION=0.11.11 \
  TERRAFORM_AUTH0_VERSION=0.1.12 \
  TERRAFORM_PINGDOM_VERSION=0.2.0 \

RUN \
  apk add \
    --no-cache \
    --no-progress \
    bash \
    build-base \
    ca-certificates \
    coreutils \
    curl \
    findutils \
    git \
    grep \
    jq \
    python3 \
    util-linux \
  && pip3 install --upgrade pip \
  && pip3 install awscli \
  && curl -sLo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  && curl -sLo /usr/local/bin/kops https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 \
  && curl -sL https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar -xzC /usr/local/bin --strip-components 1 linux-amd64/helm \
  && curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip | unzip -d /usr/local/bin - \
  && mkdir -p ~/.terraform.d/plugins \
  && curl -sL https://github.com/russellcardullo/terraform-provider-pingdom/archive/v${TERRAFORM_PINGDOM_VERSION}.tar.gz | tar -xzC ~/.terraform.d/plugins \
  && curl -sL https://github.com/alexkappa/terraform-provider-auth0/archive/v${TERRAFORM_AUTH0_VERSION}.tar.gz | tar xzC ~/.terraform.d/plugins  \
  && chmod +x /usr/local/bin/*

 
