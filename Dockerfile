FROM ubuntu:xenial
LABEL Author="charliemaiors@gmail.com" 

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_HOME=/opt/android-sdk-linux \
    NPM_VERSION=6.0.1 \
    IONIC_VERSION=3.20.0 \
    CORDOVA_VERSION=8.0.0 \
    YARN_VERSION=1.6.0 \
    GRADLE_VERSION=4.4.1 \
    # Fix for the issue with Selenium, as described here:
    # https://github.com/SeleniumHQ/docker-selenium/issues/87
    DBUS_SESSION_BUS_ADDRESS=/dev/null

# We want GCP!!!
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update -y && apt-get install google-cloud-sdk -y

# Install basics
RUN apt  update && \
    apt install -y git wget curl unzip build-essential apt-transport-https && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    export AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list && \
    curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - && \
    apt update &&  \
    apt install -y nodejs azure-cli && \
    npm install -g npm@"$NPM_VERSION" cordova@"$CORDOVA_VERSION" ionic@"$IONIC_VERSION" yarn@"$YARN_VERSION" && \
    npm cache clear --force && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    dpkg --unpack google-chrome-stable_current_amd64.deb && \
    apt install -f -y && \
    apt clean && \
    rm google-chrome-stable_current_amd64.deb && \
    mkdir Sources && \
    mkdir -p /root/.cache/yarn/ && \

# Font libraries
    apt-get -qqy install fonts-ipafont-gothic xfonts-100dpi xfonts-75dpi xfonts-cyrillic xfonts-scalable libfreetype6 libfontconfig && \

# install python-software-properties (so you can do add-apt-repository)
    apt update && apt install -y -q python3-software-properties software-properties-common python3-pip libssl-dev && \
    apt install -y  default-jdk && \

# System libs for android enviroment
    echo ANDROID_HOME="${ANDROID_HOME}" >> /etc/environment && \
    dpkg --add-architecture i386 && \
    apt update && \
    apt install -y --force-yes expect ant wget libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1 qemu-kvm kmod && \
    apt clean && \
    apt autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \

# Install Android Tools
    mkdir  /opt/android-sdk-linux && cd /opt/android-sdk-linux && \
    wget --output-document=android-tools-sdk.zip --quiet https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
    unzip -q android-tools-sdk.zip && \
    rm -f android-tools-sdk.zip && \

# Install Gradle
    mkdir  /opt/gradle && cd /opt/gradle && \
    wget --output-document=gradle.zip --quiet https://services.gradle.org/distributions/gradle-"$GRADLE_VERSION"-bin.zip && \
    unzip -q gradle.zip && \
    rm -f gradle.zip && \
    chown -R root. /opt && \

# Install Openstack Clients
    pip3 install --upgrade pip  && \
    pip install python-openstackclient awscli

# Setup environment
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:/opt/gradle/gradle-${GRADLE_VERSION}/bin

# Install Android SDK
RUN yes Y | ${ANDROID_HOME}/tools/bin/sdkmanager "build-tools;28.0.0" "platforms;android-28" "platform-tools"
RUN cordova telemetry off

WORKDIR Sources
EXPOSE 8100 35729
CMD ["ionic", "serve"]