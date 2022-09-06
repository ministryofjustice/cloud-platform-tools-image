FROM ruby:2.6.3-alpine

ENV \
  HELM_VERSION=3.6.3 \
  KUBECTL_VERSION=1.21.5 \
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
    python3-dev \
    ruby-dev \
    util-linux \
    \
    && pip3 install --upgrade pip \
    && pip3 install pygithub boto3 awscli

# Install Go
COPY --from=golang:1.18-alpine /usr/local/go/ /usr/local/go/

ENV PATH="/usr/local/go/bin:${PATH}"

# Cloud Platform CLI
RUN git clone -b apply-env https://github.com/ministryofjustice/cloud-platform-cli.git && cd cloud-platform-cli && git pull origin apply-env && make build \
    && mv cloud-platform-1.18.2-next-4a4b187-20220906 /usr/local/bin
# RUN URL=$(curl -sL https://api.github.com/repos/ministryofjustice/cloud-platform-cli/releases/${CLI_VERSION} | jq -r '.assets[] | select(.browser_download_url | match("linux_amd64")) | .browser_download_url') && \
#     curl -sLo cli.tar.gz ${URL} && tar xzv -C /usr/local/bin -f cli.tar.gz && rm -f cli.tar.gz

# Install git-crypt
RUN git clone --depth 1 https://github.com/AGWA/git-crypt.git \
  && cd git-crypt && make && make install && cd - && rm -rf git-crypt

# Install kubectl
RUN curl -sLo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl

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
