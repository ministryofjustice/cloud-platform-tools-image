# Build Pingdom Terraform provider
FROM golang:1.12.2-alpine3.9 as pingdom_builder
RUN apk add git
RUN go get -v github.com/russellcardullo/terraform-provider-pingdom

FROM alpine:3.7

ENV \
  HELM_VERSION=2.14.3 \
  KOPS_VERSION=1.10.1 \
  KUBECTL_VERSION=1.11.10 \
  TERRAFORM_VERSION=0.11.14 \
  TERRAFORM_AUTH0_VERSION=0.1.18 \
  USER=toolsuser \
  UID=1002 \
  GROUP=toolsgroup

ENV HOME=/home/${USER}

RUN addgroup -g ${UID} -S ${GROUP} && \
    adduser -u ${UID} -S ${USER} -G ${GROUP}

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
    postgresql-client \
    python3 \
    ruby \
    util-linux \
    gnupg \
    openssl \
    openssl-dev \
    openssh-keygen \
  && pip3 install --upgrade pip \
  && pip3 install awscli \
  && curl -sLo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  && curl -sLo /usr/local/bin/kops https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 \
  && curl -sL https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar -xzC /usr/local/bin --strip-components 1 linux-amd64/helm \
  && curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip | unzip -d /usr/local/bin - \
  && chmod +x /usr/local/bin/* \
  && curl -sL https://github.com/yieldr/terraform-provider-auth0/releases/download/v${TERRAFORM_AUTH0_VERSION}/terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION}_linux_amd64.tar.gz | tar xzv  \
  && mkdir -p ${HOME}/.terraform.d/plugins \
  && mv terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION} ${HOME}/.terraform.d/plugins/ \
  && git clone https://github.com/AGWA/git-crypt.git \
  && cd git-crypt && make && make install && cd - && rm -rf git-crypt

COPY --from=pingdom_builder /go/bin/terraform-provider-pingdom ${HOME}/.terraform.d/plugins/

RUN chown -R ${USER}:${GROUP} ${HOME}

USER ${UID}
WORKDIR ${HOME}
