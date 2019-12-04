# Build Concourse Terraform provider
FROM golang:1.12.2-alpine3.9 as concourse_builder
RUN apk add git make
RUN \
    git clone https://github.com/alphagov/terraform-provider-concourse.git && \
    cd terraform-provider-concourse && \
    make build

FROM ruby:2.6.3-alpine

ENV \
  HELM_VERSION=2.16.1 \
  KOPS_VERSION=1.15.0 \
  KUBECTL_VERSION=1.15.3 \
  ISTIOCTL_VERSION=1.4.0 \
  TERRAFORM_AUTH0_VERSION=0.2.1 \
  TERRAFORM_PINGDOM_VERSION=1.1.1 \
  TERRAFORM_VERSION=0.12.13 \
  AWS_IAM_AUTHENTICATOR_VERSION="1.14.6/2019-08-22"

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

COPY --from=concourse_builder /go/terraform-provider-concourse /root/.terraform.d/plugins/

# Install git-crypt
RUN git clone https://github.com/AGWA/git-crypt.git \
  && cd git-crypt && make && make install && cd - && rm -rf git-crypt

# Install kubectl
RUN curl -sLo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl

# Install istioctl
RUN curl -sL https://github.com/istio/istio/releases/download/${ISTIOCTL_VERSION}/istio-${ISTIOCTL_VERSION}-linux.tar.gz | tar -xzC /usr/local/bin --strip-components 2 istio-${ISTIOCTL_VERSION}/bin/istioctl

# Install kops
RUN curl -sLo /usr/local/bin/kops https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64

# Install helm
RUN curl -sL https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar -xzC /usr/local/bin --strip-components 1 linux-amd64/helm

# Install terraform
RUN curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip | unzip -d /usr/local/bin -

# Ensure everything is executable
RUN chmod +x /usr/local/bin/*

# Create terraform plugins directory
RUN mkdir -p ~/.terraform.d/plugins

# Install terraform auth0 provider
RUN curl -sL https://github.com/yieldr/terraform-provider-auth0/releases/download/v${TERRAFORM_AUTH0_VERSION}/terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION}_linux_amd64.tar.gz | tar xzv  \
  && mv terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION} ~/.terraform.d/plugins/

# Install AWS IAM Authenticator
RUN curl -sLo /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/${AWS_IAM_AUTHENTICATOR_VERSION}/bin/linux/amd64/aws-iam-authenticator && chmod +x /usr/local/bin/aws-iam-authenticator

# Install Pingdom provider
RUN wget https://github.com/russellcardullo/terraform-provider-pingdom/releases/download/v${TERRAFORM_PINGDOM_VERSION}/terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}_linux_amd64_static \
  && chmod +x terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}_linux_amd64_static \
  && mv terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}_linux_amd64_static ~/.terraform.d/plugins/terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}

CMD /bin/bash
