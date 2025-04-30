ARG ALPINE_VERSION=3.16

FROM python:3.10.8-alpine${ALPINE_VERSION} as builder

# Install build dependencies
RUN apk add --no-cache git unzip groff build-base libffi-dev cmake

# Clone awscli
ARG AWS_CLI_VERSION=2.7.20
RUN git clone https://github.com/aws/aws-cli.git --single-branch -b ${AWS_CLI_VERSION} awscli

# Build process
WORKDIR awscli
RUN sed -i'' 's/PyInstaller.*/PyInstaller==5.2/g' requirements-build.txt
RUN python -m venv venv
RUN . venv/bin/activate
RUN scripts/installers/make-exe
RUN unzip -q dist/awscli-exe.zip
RUN aws/install --bin-dir /aws-cli-bin
RUN /aws-cli-bin/aws --version

# Remove examples as unnecessary
RUN rm -rf /usr/local/aws-cli/v2/current/dist/awscli/examples
RUN find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

# Install Go
FROM golang:1.23-alpine as go-builder

RUN mkdir app

WORKDIR /app

COPY . ./

RUN go mod download

RUN go build pkg/delete_job/delete_job.go

FROM ruby:3.1.3-alpine3.16

ENV \
  HELM_VERSION=3.7.2 \
  KUBECTL_VERSION=1.30.4 \
  TERRAFORM_VERSION=1.2.5 \
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
  parallel \
  neovim \
  github-cli

# Install AWS cli
COPY --from=builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=builder /aws-cli-bin/ /usr/local/bin/
COPY --from=go-builder /app/delete_job .
COPY --from=go-builder /usr/local/go/ /usr/local/go/ 
ENV PATH="/usr/local/go/bin:${PATH}"

# Cloud Platform CLI
RUN URL=$(curl -sL https://api.github.com/repos/ministryofjustice/cloud-platform-cli/releases/${CLI_VERSION} | jq -r '.assets[] | select(.browser_download_url | match("linux_amd64")) | .browser_download_url') && \
  curl -sLo cli.tar.gz ${URL} && tar xzv -C /usr/local/bin -f cli.tar.gz && rm -f cli.tar.gz

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
