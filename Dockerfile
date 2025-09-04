# Dockerfile para criar um ambiente de compilação consistente para Flutter
# Baseado em Debian 12 (Slim) para um tamanho de imagem otimizado

# 1. IMAGEM BASE E VARIÁVEIS DE AMBIENTE
FROM debian:12-slim

# Define o locale para evitar avisos durante a instalação de pacotes.
ENV LANG=C.UTF-8

# Argumentos para definir as versões das ferramentas. Permite flexibilidade.
ARG FLUTTER_VERSION="3.35.2"
ARG FLUTTER_CHANNEL="stable"
ARG ANDROID_SDK_VERSION="11076708" # Corresponde às últimas ferramentas do Android Studio
ARG JAVA_VERSION="17"
ARG GCLOUD_SDK_VERSION="488.0.0" # Versão fixa para o gcloud SDK

# Variáveis de ambiente para o Flutter, Android SDK e Google Cloud SDK.
ENV FLUTTER_HOME="/opt/flutter"
ENV ANDROID_SDK_ROOT="/opt/android-sdk"
ENV GCLOUD_HOME="/opt/google-cloud-sdk"
ENV PATH="${GCLOUD_HOME}/bin:${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# 2. INSTALAÇÃO DE DEPENDÊNCIAS DO SISTEMA
# Instala todas as ferramentas necessárias numa única camada para otimizar o tamanho.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    curl \
    file \
    git \
    openjdk-${JAVA_VERSION}-jdk \
    unzip \
    wget \
    xz-utils \
    libglu1-mesa \
    # Dependências para a instalação do Node.js
    ca-certificates \
    gnupg && \
    # Limpa o cache do apt para reduzir o tamanho da imagem.
    rm -rf /var/lib/apt/lists/*

# Instala o Node.js v22 (LTS) a partir do repositório oficial NodeSource.
# O Firebase CLI requer uma versão mais recente do que a disponível no Debian padrão.
RUN mkdir -p /etc/apt/keyrings /etc/apt/sources.list.d && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# 3. INSTALAÇÃO DO FLUTTER SDK
RUN mkdir -p /opt && \
    cd /opt && \
    wget "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" && \
    tar xf "flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" && \
    rm "flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" && \
    # Adiciona uma exceção de segurança para o Git, pois os comandos serão executados como root.
    git config --global --add safe.directory ${FLUTTER_HOME}

# Pré-configura o Flutter para evitar downloads durante o build.
RUN flutter precache && \
    flutter config --no-analytics

# 4. INSTALAÇÃO DO ANDROID SDK
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    cd ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip" -O sdk.zip && \
    unzip sdk.zip && \
    # O SDK é extraído para uma pasta 'cmdline-tools', então movemos o conteúdo para 'latest'.
    mv cmdline-tools latest && \
    rm sdk.zip && \
    # Aceita as licenças do SDK automaticamente.
    yes | sdkmanager --licenses && \
    # Instala os pacotes necessários.
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 5. INSTALAÇÃO DAS FERRAMENTAS DO GOOGLE CLOUD E FIREBASE
# CORREÇÃO FINAL: Descarrega e extrai o gcloud CLI diretamente, sem usar o script de instalação.
RUN cd /opt && \
    wget "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz" && \
    tar -xzf "google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz" && \
    rm "google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz"

# Instala as ferramentas do Firebase via npm.
RUN npm install -g firebase-tools

# 6. CONFIGURAÇÃO DO USUÁRIO
# Cria um usuário não-root 'jenkins' para executar os comandos de build.
RUN useradd -ms /bin/bash jenkins && \
    # Concede a propriedade dos diretórios dos SDKs ao novo usuário.
    chown -R jenkins:jenkins ${FLUTTER_HOME} && \
    chown -R jenkins:jenkins ${ANDROID_SDK_ROOT} && \
    chown -R jenkins:jenkins ${GCLOUD_HOME}

# Define o usuário 'jenkins' como o padrão para os próximos comandos.
USER jenkins

# Define o diretório de trabalho padrão dentro do container.
WORKDIR /home/jenkins/workspace

