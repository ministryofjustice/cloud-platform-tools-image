# Build Pingdom Terraform provider
FROM golang:1.12.2-alpine3.9 as pingdom_builder
RUN apk add git
RUN GO111MODULE=on go get -v github.com/russellcardullo/terraform-provider-pingdom@d49195a7567560c3ca4d64b524c32ce8089ff26a

FROM ruby:2.6.3-alpine

ENV \
  HELM_VERSION=2.14.3 \
  KOPS_VERSION=1.13.2 \
  KUBECTL_VERSION=1.13.11 \
  TERRAFORM_AUTH0_VERSION=0.2.1 \
  TERRAFORM_VERSION=0.11.14 \
  TERRAFORM12_VERSION=0.12.13

RUN \
  apk add \
    --no-cache \
    --no-progress \
    --update \
    --virtual \
    build-deps \
    build-base \
    bash \
    ca-certificates \
    coreutils \
    curl \
    findutils \
    git \
    gnupg \
    grep \
    joe \
    jq \
    libc-dev \
    libxml2-dev \
    libxslt-dev \
    linux-headers \
    openssl \
    openssl-dev \
    openssh-keygen \
    postgresql-client \
    python3 \
    ruby-dev \
    util-linux \
  \
  && pip3 install --upgrade pip \
  && pip3 install pygithub boto3 \
  && pip3 install awscli

# Build integration test environment
RUN mkdir -p /app/integration-test/; cd /app/integration-test \
      && wget \
      https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/master/smoke-tests/Gemfile \
      https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/master/smoke-tests/Gemfile.lock \
      \
      && gem install bundler \
      && bundle install

# Install git-crypt
RUN git clone https://github.com/AGWA/git-crypt.git \
  && cd git-crypt && make && make install && cd - && rm -rf git-crypt

# Install kubectl
RUN curl -sLo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl

# Install kops
RUN curl -sLo /usr/local/bin/kops https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64

# Install helm
RUN curl -sL https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar -xzC /usr/local/bin --strip-components 1 linux-amd64/helm

# Install terraform
RUN curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip | unzip -d /usr/local/bin -

# Install terraform 12
RUN curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM12_VERSION}/terraform_${TERRAFORM12_VERSION}_linux_amd64.zip | unzip - && mv terraform /usr/local/bin/terraform12

# Install terraform auth0 provider
RUN curl -sL https://github.com/yieldr/terraform-provider-auth0/releases/download/v${TERRAFORM_AUTH0_VERSION}/terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION}_linux_amd64.tar.gz | tar xzv  \
  && mkdir -p ~/.terraform.d/plugins \
  && mv terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION} ~/.terraform.d/plugins/

# Install pingdom provider (needs the ~/.terraform.d/plugins directory from the previous step)
COPY --from=pingdom_builder /go/bin/terraform-provider-pingdom /root/.terraform.d/plugins/

# Ensure everything is executable
RUN chmod +x /usr/local/bin/*

CMD /bin/bash
