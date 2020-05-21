# Build Concourse Terraform provider
FROM golang:1.12.2-alpine3.9 as concourse_builder
RUN apk add git make
RUN \
    git clone https://github.com/alphagov/terraform-provider-concourse.git && \
    cd terraform-provider-concourse && \
    make build

FROM ruby:2.6.3-alpine

ENV \
  HELM_VERSION=3.2.1 \
  KOPS_VERSION=1.16.2 \
  KUBECTL_VERSION=1.16.9 \
  TERRAFORM_AUTH0_VERSION=0.2.1 \
  TERRAFORM_PINGDOM_VERSION=1.1.1 \
  TERRAFORM_VERSION=0.12.17

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

# Install kops
RUN curl -sLo /usr/local/bin/kops https://github.com/kubernetes/kops/releases/download/v${KOPS_VERSION}/kops-linux-amd64

# Install helm
RUN curl -L https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar xz && mv linux-amd64/helm /bin/helm && rm -rf linux-amd64 

# Install terraform
RUN curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip | unzip -d /usr/local/bin -

# Install aws-iam-authenticator (required for EKS)
RUN curl -sLo /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator

# Ensure everything is executable
RUN chmod +x /usr/local/bin/*

# Create terraform plugins directory
RUN mkdir -p ~/.terraform.d/plugins

# Install terraform auth0 provider
RUN curl -sL https://github.com/yieldr/terraform-provider-auth0/releases/download/v${TERRAFORM_AUTH0_VERSION}/terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION}_linux_amd64.tar.gz | tar xzv  \
  && mv terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION} ~/.terraform.d/plugins/

# Install Pingdom provider
RUN wget https://github.com/russellcardullo/terraform-provider-pingdom/releases/download/v${TERRAFORM_PINGDOM_VERSION}/terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}_linux_amd64_static \
  && chmod +x terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}_linux_amd64_static \
  && mv terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}_linux_amd64_static ~/.terraform.d/plugins/terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}

# Copy utility commands for teams who use this image as part
# of their CI pipelines
COPY circleci/setup-kube-auth /usr/local/bin/setup-kube-auth
COPY circleci/tag-and-push-docker-image /usr/local/bin/tag-and-push-docker-image

CMD /bin/bash
