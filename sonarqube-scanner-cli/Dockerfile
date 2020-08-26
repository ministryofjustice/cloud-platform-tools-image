# Build Concourse Terraform provider
FROM openjdk:8-alpine
ENV \
  KUBECTL_VERSION=1.16.13 \
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

# Install git-crypt
RUN git clone https://github.com/AGWA/git-crypt.git \
  && cd git-crypt && make && make install && cd - && rm -rf git-crypt
# Install kubectl
RUN curl -sLo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl
# Ensure everything is executable
RUN chmod +x /usr/local/bin/*
# Create terraform plugins directory
RUN mkdir -p ~/.terraform.d/plugins
RUN apk add --no-cache curl grep sed unzip bash nodejs nodejs-npm
# Install Sonar Qube
WORKDIR /usr/src
RUN curl --insecure -o ./sonarscanner.zip -L https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.0.0.1744-linux.zip && \
	unzip sonarscanner.zip && \
	rm sonarscanner.zip && \
	mv sonar-scanner-4.0.0.1744-linux /usr/lib/sonar-scanner && \
	ln -s /usr/lib/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
ENV SONAR_RUNNER_HOME=/usr/lib/sonar-scanner
ENV PATH $PATH:$SONAR_RUNNER_HOME/bin
#   ensure Sonar uses the provided Java for musl instead of a borked glibc one
RUN sed -i 's/use_embedded_jre=true/use_embedded_jre=false/g' /usr/lib/sonar-scanner/bin/sonar-scanner
CMD /bin/bash