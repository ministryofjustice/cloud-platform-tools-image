FROM alpine:3.11
ENV JAVA_VERSION="jdk-11.0.6+10" \
    LANG='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    LC_ALL='en_US.UTF-8'


SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN set -eux; \
    apk add --no-cache --virtual .build-deps curl binutils; \
    GLIBC_VER="2.31-r0"; \
    ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download"; \
    GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-9.1.0-2-x86_64.pkg.tar.xz"; \
    GCC_LIBS_SHA256="91dba90f3c20d32fcf7f1dbe91523653018aa0b8d2230b00f822f6722804cf08"; \
    ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-3-x86_64.pkg.tar.xz"; \
    ZLIB_SHA256="17aede0b9f8baa789c5aa3f358fbf8c68a5f1228c5e6cba1a5dd34102ef4d4e5"; \
    curl -LfsS https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub; \
    SGERRAND_RSA_SHA256="823b54589c93b02497f1ba4dc622eaef9c813e6b0f0ebbb2f771e32adf9f4ef2"; \
    echo "${SGERRAND_RSA_SHA256} */etc/apk/keys/sgerrand.rsa.pub" | sha256sum -c -; \
    curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/glibc-${GLIBC_VER}.apk; \
    apk add --no-cache /tmp/glibc-${GLIBC_VER}.apk; \
    curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk > /tmp/glibc-bin-${GLIBC_VER}.apk; \
    apk add --no-cache /tmp/glibc-bin-${GLIBC_VER}.apk; \
    curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk > /tmp/glibc-i18n-${GLIBC_VER}.apk; \
    apk add --no-cache /tmp/glibc-i18n-${GLIBC_VER}.apk; \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true; \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh; \
    curl -LfsS ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz; \
    echo "${GCC_LIBS_SHA256} */tmp/gcc-libs.tar.xz" | sha256sum -c -; \
    mkdir /tmp/gcc; \
    tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc; \
    mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib; \
    strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so*; \
    curl -LfsS ${ZLIB_URL} -o /tmp/libz.tar.xz; \
    echo "${ZLIB_SHA256} */tmp/libz.tar.xz" | sha256sum -c -; \
    mkdir /tmp/libz; \
    tar -xf /tmp/libz.tar.xz -C /tmp/libz; \
    mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib; \
    apk del --purge .build-deps glibc-i18n; \
    rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar.xz /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*;

#
# AdoptOpenJDK/openjdk11 setup
#

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

WORKDIR /opt/java/openjdk

RUN set -eux; \
    apk add --no-cache --virtual .fetch-deps curl; \
    ARCH="$(apk --print-arch)"; \
    case "${ARCH}" in \
       aarch64|arm64) \
         ESUM='7ed04ed9ed7271528e7f03490f1fd7dfbbc2d391414bd6fe4dd80ec3bad76d30'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.6%2B10/OpenJDK11U-jre_aarch64_linux_hotspot_11.0.6_10.tar.gz'; \
         ;; \
       ppc64el|ppc64le) \
         ESUM='49231f2c36487b53141ade3f7eb291e2855138b14b1129f9acf435ea9cc0e899'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.6%2B10/OpenJDK11U-jre_ppc64le_linux_hotspot_11.0.6_10.tar.gz'; \
         ;; \
       s390x) \
         ESUM='bcb3f46cbad742b08c81e922e313549c029f436ac7d91ef3c9bed8e4049d67d2'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.6%2B10/OpenJDK11U-jre_s390x_linux_hotspot_11.0.6_10.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='c5a4e69e2be0e3e5f5bb7c759960b20650967d0f571baad4a7f15b2c03bda352'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.6%2B10/OpenJDK11U-jre_x64_linux_hotspot_11.0.6_10.tar.gz'; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
    apk del --purge .fetch-deps; \
    rm -rf /var/cache/apk/*; \
    rm -rf /tmp/openjdk.tar.gz;

ARG SONAR_SCANNER_HOME=/opt/sonar-scanner
ARG NODEJS_HOME=/opt/nodejs
ARG UID=1000
ARG GID=1000
ENV JAVA_HOME=/opt/java/openjdk \
    HOME=/tmp \
    XDG_CONFIG_HOME=/tmp \
    SONAR_SCANNER_HOME=${SONAR_SCANNER_HOME} \
    SONAR_USER_HOME=${SONAR_SCANNER_HOME}/.sonar \
    SONAR_SCANNER_VERSION=4.4.0.2170 \
    NODEJS_HOME=${NODEJS_HOME} \
    NODEJS_VERSION=v12.18.2 \
    PATH=/opt/java/openjdk/bin:${SONAR_SCANNER_HOME}/bin:${NODEJS_HOME}/bin:${PATH} \
    NODE_PATH=${NODEJS_HOME}/lib/node_modules \
    SRC_PATH=/usr/src

WORKDIR /opt

RUN set -ex \
    && addgroup -S -g ${GID} scanner-cli \
    && adduser -S -D -u ${UID} -G scanner-cli scanner-cli \
    && apk add --no-cache --virtual build-dependencies wget unzip gnupg \
    && apk add --no-cache git python3 bash shellcheck \
    && wget -U "scannercli" -q -O /opt/sonar-scanner-cli.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip \
    && wget -U "scannercli" -q -O /opt/sonar-scanner-cli.zip.asc https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip.asc \
    && wget -U "scannercli" -q -O /opt/sonarsource-public.key https://binaries.sonarsource.com/sonarsource-public.key \
    && gpg --import /opt/sonarsource-public.key \
    && gpg --verify /opt/sonar-scanner-cli.zip.asc /opt/sonar-scanner-cli.zip \
    && unzip sonar-scanner-cli.zip \
    && rm sonar-scanner-cli.zip sonar-scanner-cli.zip.asc \
    && mv sonar-scanner-${SONAR_SCANNER_VERSION} ${SONAR_SCANNER_HOME} \
    && wget -U "nodejs" -q -O node-${NODEJS_VERSION}-linux-x64.tar.xz https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-x64.tar.xz \
    && wget -U "nodejs" -q -O SHASUMS256.txt https://nodejs.org/dist/${NODEJS_VERSION}/SHASUMS256.txt \
    && wget -U "nodejs" -q -O SHASUMS256.txt.sig https://nodejs.org/dist/${NODEJS_VERSION}/SHASUMS256.txt.sig \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys 4ED778F539E3634C779C87C6D7062848A1AB005C \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys 94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys 71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys 8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys 108F52B48DB57BB0CC439B2997B01419BD92F80A \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    && gpg --verify SHASUMS256.txt.sig SHASUMS256.txt \
    && grep node-${NODEJS_VERSION}-linux-x64.tar.xz SHASUMS256.txt | sha256sum -c - \
    && tar Jxf node-${NODEJS_VERSION}-linux-x64.tar.xz --no-same-owner \
    && rm node-${NODEJS_VERSION}-linux-x64.tar.xz SHASUMS256.txt SHASUMS256.txt.sig /tmp/.gnupg/pubring.kbx /tmp/.gnupg/trustdb.gpg \
    && mv node-${NODEJS_VERSION}-linux-x64 ${NODEJS_HOME} \
    && npm install -g typescript@3.7.5 \
    && pip3 install --upgrade pip \
    && pip install pylint \
    && apk del --purge build-dependencies \
    && mkdir -p "${SRC_PATH}" "${SONAR_USER_HOME}" "${SONAR_USER_HOME}/cache"\
    && chown -R scanner-cli:scanner-cli "${SONAR_SCANNER_HOME}" "${SRC_PATH}" \
    && chmod -R 777 "${SRC_PATH}" "${SONAR_USER_HOME}"

COPY --chown=scanner-cli:scanner-cli bin /usr/bin/

WORKDIR ${SRC_PATH}

#ENTRYPOINT ["/usr/bin/entrypoint.sh"]

#****************************************



ENV \
  HELM_VERSION=3.2.1 \
  KOPS_VERSION=1.16.3 \
  KUBECTL_VERSION=1.16.13 \
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
      https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/main/smoke-tests/Gemfile \
      https://raw.githubusercontent.com/ministryofjustice/cloud-platform-infrastructure/main/smoke-tests/Gemfile.lock \
      \
      && gem install bundler \
      && bundle install

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


CMD /bin/bash
#CMD ["sonar-scanner"]
