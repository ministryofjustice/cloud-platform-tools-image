# Build Concourse Terraform provider
FROM golang:1.14.4-alpine3.12 as concourse_builder
RUN apk add git make
RUN \
    git clone https://github.com/alphagov/terraform-provider-concourse.git --branch v5.8.0 && \
    cd terraform-provider-concourse && \
    make build
FROM openjdk:8-alpine
ENV \
  HELM_VERSION=3.2.1 \
  KOPS_VERSION=1.16.3 \
  KUBECTL_VERSION=1.16.13 \
  TERRAFORM_PINGDOM_VERSION=1.1.1 \
  TERRAFORM_VERSION=0.12.17 \
  JAVA_VERSION=jdk-11.0.6+10 \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8 \
  BUNDLER_VERSION=2.0.2
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
    util-linux \
    ruby-dev \
  \
  && pip3 install --upgrade pip \
  && pip3 install pygithub boto3 \
  && pip3 install awscli
RUN \
  apk --update add ruby ruby-webrick ruby-io-console ruby-irb ruby-json ruby-rake ruby-rdoc  && \
  gem install bundler -v ${BUNDLER_VERSION} --no-document && \
  bundle config --global silence_root_warning 1
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
RUN apk add --no-cache curl grep sed unzip bash nodejs nodejs-npm
WORKDIR /usr/src
RUN curl --insecure -o ./sonarscanner.zip -L https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.0.0.1744-linux.zip && \
	unzip sonarscanner.zip && \
	rm sonarscanner.zip && \
	mv sonar-scanner-4.0.0.1744-linux /usr/lib/sonar-scanner && \
	ln -s /usr/lib/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
ENV SONAR_RUNNER_HOME=/usr/lib/sonar-scanner
ENV PATH $PATH:$SONAR_RUNNER_HOME/bin
#COPY sonar-runner.properties /usr/lib/sonar-scanner/conf/sonar-scanner.properties
#   ensure Sonar uses the provided Java for musl instead of a borked glibc one
RUN sed -i 's/use_embedded_jre=true/use_embedded_jre=false/g' /usr/lib/sonar-scanner/bin/sonar-scanner
CMD /bin/bash