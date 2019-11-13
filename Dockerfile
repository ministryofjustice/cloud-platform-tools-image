# Build Pingdom Terraform provider
FROM golang:1.12.2-alpine3.9 as pingdom_builder
RUN apk add git
RUN GO111MODULE=on go get -v github.com/russellcardullo/terraform-provider-pingdom@d49195a7567560c3ca4d64b524c32ce8089ff26a

# Build Concourse Terraform provider
FROM golang:1.12.2-alpine3.9 as concourse_builder
RUN apk add git make
RUN \
    git clone https://github.com/alphagov/terraform-provider-concourse.git && \
    cd terraform-provider-concourse && \
    make build
RUN GO111MODULE=on go get github.com/mikefarah/yq@2.4.1

FROM ruby:2.6.3-alpine

ENV \
  HELM_VERSION=2.14.3 \
  KOPS_VERSION=1.13.2 \
  KUBECTL_VERSION=1.13.11 \
  TERRAFORM_AUTH0_VERSION=0.1.18 \
  TERRAFORM_VERSION=0.11.14 \
  YQ_VERSION=2.4.1

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
  && pip3 install awscli \
  && curl -sLo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  && curl -sLo /usr/local/bin/kops https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 \
  && curl -sL https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar -xzC /usr/local/bin --strip-components 1 linux-amd64/helm \
  && curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip | unzip -d /usr/local/bin - \
  && curl -sL /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_arm64 \
  && chmod +x /usr/local/bin/* \
  && curl -sL https://github.com/yieldr/terraform-provider-auth0/releases/download/v${TERRAFORM_AUTH0_VERSION}/terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION}_linux_amd64.tar.gz | tar xzv  \
  && mkdir -p ~/.terraform.d/plugins \
  && mv terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION} ~/.terraform.d/plugins/ \
  && git clone https://github.com/AGWA/git-crypt.git \
  && cd git-crypt && make && make install && cd - && rm -rf git-crypt

# Build integration test environment
RUN mkdir -p /app/integration-test/; cd /app/integration-test \
      && wget \
      https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/master/smoke-tests/Gemfile \
      https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/master/smoke-tests/Gemfile.lock \
      \
      && gem install bundler \
      && bundle install

COPY --from=pingdom_builder /go/bin/terraform-provider-pingdom /root/.terraform.d/plugins/
COPY --from=concourse_builder /go/terraform-provider-concourse /root/.terraform.d/plugins/
COPY --from=concourse_builder /go/bin/yq /usr/local/bin/

ENTRYPOINT /bin/bash
