# Dockerfile definitivo para rodar o pipeline inteiro dentro do container
FROM debian:12.1

# --- VARIÁVEIS DE CONFIGURAÇÃO ---
ENV FLUTTER_VERSION=3.35.2
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH:/opt/google-cloud-sdk/bin"

# --- INSTALAÇÃO DE DEPENDÊNCIAS DO SISTEMA ---
# Adicionado 'apt-transport-https' para o repositório do Google Cloud
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl git unzip openjdk-17-jdk xz-utils ca-certificates wget sudo apt-transport-https lsb-release gnupg && \
    rm -rf /var/lib/apt/lists/*

# --- (NOVO) INSTALAÇÃO DA GCLOUD CLI ---
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    apt-get update && \
    apt-get install -y google-cloud-cli

# --- INSTALAÇÃO DO FLUTTER ---
RUN wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -O /tmp/flutter.tar.xz && \
    mkdir -p ${FLUTTER_HOME} && \
    tar xf /tmp/flutter.tar.xz -C /opt && \
    rm /tmp/flutter.tar.xz

# --- INSTALAÇÃO DO ANDROID SDK ---
RUN mkdir -p ${ANDROID_SDK_ROOT} && \
    wget -q 'https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip' -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT} && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools ${ANDROID_SDK_ROOT}/latest && \
    mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/latest ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# Instala os pacotes do SDK.
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "build-tools;34.0.0" "platforms;android-34"

# --- CONFIGURAÇÃO DE USUÁRIO ---
RUN groupadd --gid 1001 flutterdev && \
    useradd --uid 1001 --gid 1001 --create-home --shell /bin/bash flutterdev
RUN chown -R flutterdev:flutterdev ${FLUTTER_HOME} ${ANDROID_SDK_ROOT}

# Define o usuário padrão para o container
USER flutterdev
WORKDIR /home/flutterdev/app

# Configura o ambiente para o usuário
RUN git config --global --add safe.directory ${FLUTTER_HOME}
RUN flutter config --android-sdk ${ANDROID_SDK_ROOT}