FROM golang:1.14.4-alpine3.12 as cloud_platform_cli_builder
RUN apk add git
RUN \
    git clone https://github.com/ministryofjustice/cloud-platform-cli.git && \
    cd cloud-platform-cli && \
    go build -o cloud-platform ./cmd/cloud-platform/main.go

FROM ruby:2.6.3-alpine

ENV \
  HELM_VERSION=3.4.0 \
  KOPS_VERSION=1.18.2 \
  KUBECTL_VERSION=1.18.16

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
    docker-cli \
  \
  && pip3 install --upgrade pip \
  && pip3 install pygithub boto3 \
  && pip3 install awscli

# Build integration test environment
RUN mkdir -p /app/integration-test/; cd /app/integration-test \
      && wget \
      https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/main/smoke-tests/Gemfile \
      https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/main/smoke-tests/Gemfile.lock \
      \
      && gem install bundler \
      && bundle install

COPY --from=cloud_platform_cli_builder /go/cloud-platform-cli/cloud-platform /usr/local/bin/

# Install git-crypt
RUN git clone https://github.com/AGWA/git-crypt.git \
  && cd git-crypt && make && make install && cd - && rm -rf git-crypt

# Install kubectl
RUN curl -sLo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl

# Install kops
RUN curl -sLo /usr/local/bin/kops https://github.com/kubernetes/kops/releases/download/v${KOPS_VERSION}/kops-linux-amd64

# Install helm
RUN curl -L https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar xz && mv linux-amd64/helm /bin/helm && rm -rf linux-amd64

# Install Terraform
COPY --from=hashicorp/terraform:0.14.7 /bin/terraform /usr/local/bin/terraform

# Install aws-iam-authenticator (required for EKS)
RUN curl -sLo /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator

# Ensure everything is executable
RUN chmod +x /usr/local/bin/*

# Create terraform plugins directory
RUN mkdir -p ~/.terraform.d/plugins

# Install AWS provider (until https://github.com/hashicorp/terraform-provider-aws/issues/17712)
RUN wget https://releases.hashicorp.com/terraform-provider-aws/3.28.0/terraform-provider-aws_3.28.0_linux_amd64.zip \
  && unzip terraform-provider-aws_3.28.0_linux_amd64.zip && chmod +x terraform-provider-aws_v3.28.0_x5 \
  && mv terraform-provider-aws_v3.28.0_x5 ~/.terraform.d/plugins/

# Copy utility commands for teams who use this image as part
# of their CI pipelines
COPY circleci/setup-kube-auth /usr/local/bin/setup-kube-auth
COPY circleci/tag-and-push-docker-image /usr/local/bin/tag-and-push-docker-image

CMD /bin/bash
