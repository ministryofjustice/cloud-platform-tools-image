FROM ruby:2.6.3-alpine

ENV \
  HELM_VERSION=3.6.3 \
  KOPS_VERSION=1.18.2 \
  KUBECTL_VERSION=1.20.7 \
  TERRAFORM_VERSION=0.14.8 \
  CLI_VERSION=latest

RUN \
  apk add \
    --no-cache \
    --no-progress \
    --update \
    bash \
    build-base \
    ca-certificates \
    coreutils \
    curl \
    docker-cli \
    findutils \
    git \
    gnupg \
    grep \
    jq \
    openssl \
    openssl-dev \
    openssh-keygen \
    postgresql-client \
    python3 \
    ruby-dev \
    util-linux \
    \
    && pip3 install --upgrade pip \
    && pip3 install pygithub boto3 awscli

# Build integration test environment
RUN mkdir -p /app/integration-test/; cd /app/integration-test \
      && wget \
      https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/main/smoke-tests/Gemfile \
      https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/main/smoke-tests/Gemfile.lock \
      \
      && gem install bundler \
      && bundle install

# Cloud Platform CLI
RUN URL=$(curl -sL https://api.github.com/repos/ministryofjustice/cloud-platform-cli/releases/${CLI_VERSION} | jq -r '.assets[] | select(.browser_download_url | match("linux_amd64")) | .browser_download_url') && \
    curl -sLo cli.tar.gz ${URL} && tar xzv -C /usr/local/bin -f cli.tar.gz && rm -f cli.tar.gz

# Install git-crypt
RUN git clone --depth 1 https://github.com/AGWA/git-crypt.git \
  && cd git-crypt && make && make install && cd - && rm -rf git-crypt

# Install kubectl
RUN curl -sLo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl

# Install kops
RUN curl -sLo /usr/local/bin/kops https://github.com/kubernetes/kops/releases/download/v${KOPS_VERSION}/kops-linux-amd64

# Install helm
RUN curl -L https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar xz && mv linux-amd64/helm /bin/helm && rm -rf linux-amd64

# Install Terraform
RUN curl -sLo terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && unzip terraform.zip && mv terraform /usr/local/bin && rm -f terraform.zip

# Ensure everything is executable
RUN chmod +x /usr/local/bin/*

# Create terraform plugins directory
RUN mkdir -p ~/.terraform.d/plugins

# utility command for teams who use this image as part of their CI pipelines
COPY circleci/tag-and-push-docker-image /usr/local/bin/tag-and-push-docker-image

CMD /bin/bash
