# Dockerfile para Ambiente Flutter
# Baseado em Debian 12 (Bookworm) para estabilidade.
FROM debian:12-slim

# Define o locale para evitar avisos durante a instalação de pacotes.
ENV LANG C.UTF-8

# Variáveis de ambiente para as versões das ferramentas.
# Manter as versões fixas garante a consistência do build.
ENV FLUTTER_VERSION="3.35.2" \
    FLUTTER_CHANNEL="stable" \
    JAVA_VERSION="17" \
    ANDROID_SDK_VERSION="11076708" \
    GCLOUD_SDK_VERSION="488.0.0"

# Define o diretório do Flutter e o adiciona ao PATH.
ENV FLUTTER_HOME="/opt/flutter"
ENV PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:${PATH}"

# Define o diretório do Android SDK.
ENV ANDROID_HOME="/opt/android-sdk"
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

# 1. INSTALAÇÃO DE DEPENDÊNCIAS BÁSICAS
# Instala pacotes essenciais, OpenJDK, e Node.js/npm para o Firebase CLI.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-${JAVA_VERSION}-jdk \
    wget \
    unzip \
    git \
    curl \
    xz-utils \
    libglu1-mesa \
    nodejs \
    npm \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. INSTALAÇÃO DO FLUTTER SDK
# Baixa a versão específica do Flutter, extrai e a adiciona ao PATH.
RUN mkdir -p /opt && \
    cd /opt && \
    wget "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" && \
    tar xf "flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" && \
    rm "flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"

# Adiciona uma exceção de segurança do Git para o diretório do Flutter.
RUN git config --global --add safe.directory ${FLUTTER_HOME}

# Pré-configura o Flutter para evitar downloads durante o build
RUN flutter precache && \
    flutter config --no-analytics

# 3. INSTALAÇÃO DO ANDROID SDK
# Baixa e instala as ferramentas de linha de comando do Android SDK.
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    cd ${ANDROID_HOME}/cmdline-tools && \
    wget "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip" -O tools.zip && \
    unzip tools.zip && \
    mv cmdline-tools latest && \
    rm tools.zip

# Aceita as licenças do Android SDK de forma automática.
RUN yes | sdkmanager --licenses

# Instala os pacotes necessários do Android SDK.
RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 4. INSTALAÇÃO DO GOOGLE CLOUD SDK (gcloud CLI) E FIREBASE TOOLS
# Necessário para interagir com o Firebase Test Lab.
RUN cd /opt && \
    wget "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz" && \
    tar -xzf google-cloud-cli-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm google-cloud-cli-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    ./google-cloud-sdk/install.sh --quiet --usage-reporting false --path-update false

# Adiciona o gcloud ao PATH.
ENV PATH="/opt/google-cloud-sdk/bin:${PATH}"

# Instala o Firebase CLI globalmente via npm, que é a ferramenta para App Distribution.
RUN npm install -g firebase-tools

# 5. CONFIGURAÇÃO DO USUÁRIO
# Cria um usuário não-root para executar os builds, como boa prática de segurança.
RUN useradd -ms /bin/bash jenkins

# Muda a propriedade dos diretórios dos SDKs para o usuário 'jenkins'.
# Isso é crucial para resolver erros de 'Permission denied'.
RUN chown -R jenkins:jenkins ${FLUTTER_HOME} && \
    chown -R jenkins:jenkins ${ANDROID_HOME} && \
    chown -R jenkins:jenkins /opt/google-cloud-sdk

# Define o diretório de trabalho que será usado pelo Jenkins.
WORKDIR /home/jenkins/workspace

# Muda para o usuário 'jenkins'. Todas as operações subsequentes serão executadas por ele.
USER jenkins

