# Dockerfile para criar um ambiente de compilação CI/CD para Flutter
# Baseado em Debian 12 (Bookworm) para estabilidade.
FROM debian:12-slim

# Evita que os instaladores peçam inputs interativos
ENV DEBIAN_FRONTEND=noninteractive

# Variáveis de ambiente para versões das ferramentas e caminhos
# Facilita a manutenção e atualização das versões no futuro
ENV FLUTTER_VERSION="3.52.2"
ENV FLUTTER_CHANNEL="stable"
ENV ANDROID_CMD_LINE_TOOLS_VERSION="11076708"
ENV ANDROID_SDK_ROOT="/opt/android-sdk"
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
ENV PATH="$PATH:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${FLUTTER_HOME}/bin"
ENV FLUTTER_HOME="/opt/flutter"

# 1. Instalação de dependências essenciais
# Inclui: git, ssh, wget, unzip, xz-utils (para descompactar o SDK do Flutter)
# e openjdk-17-jdk, recomendado para as versões mais recentes do Android.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    wget \
    unzip \
    xz-utils \
    openjdk-17-jdk \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. Instalação do Flutter SDK
# Baixa a versão específica do Flutter, extrai e a adiciona ao PATH.
RUN mkdir -p /opt && \
    cd /opt && \
    wget "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" && \
    tar xf "flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" && \
    rm "flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"

# Pré-configura o Flutter para evitar downloads durante o build
RUN flutter precache && \
    flutter config --no-analytics

# 3. Instalação do Android SDK
# Baixa as ferramentas de linha de comando, que são a forma moderna de gerenciar o SDK.
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    cd ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMD_LINE_TOOLS_VERSION}_latest.zip" && \
    unzip "commandlinetools-linux-${ANDROID_CMD_LINE_TOOLS_VERSION}_latest.zip" && \
    # Move o conteúdo para um diretório "latest" para corresponder à estrutura esperada
    mv cmdline-tools latest && \
    rm "commandlinetools-linux-${ANDROID_CMD_LINE_TOOLS_VERSION}_latest.zip"

# Aceita as licenças do Android SDK de forma automática
RUN yes | sdkmanager --licenses

# Instala os pacotes necessários do SDK: platform-tools, build-tools e a plataforma Android 34.
# O Flutter doctor indicará quais pacotes são necessários.
RUN sdkmanager "platform-tools" "build-tools;34.0.0" "platforms;android-34"

# 4. Instalação do Google Cloud SDK (gcloud CLI)
# Necessário para interagir com o Firebase Test Lab e App Distribution.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gnupg \
    curl && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && \
    apt-get install -y google-cloud-sdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 5. Configuração do ambiente final
# Cria um usuário não-root 'jenkins' para executar os comandos por segurança.
RUN useradd -ms /bin/bash jenkins
USER jenkins

# Define o diretório de trabalho padrão dentro do container.
WORKDIR /home/jenkins/workspace

# Comando padrão (pode ser sobrescrito pelo Jenkins)
CMD ["flutter", "doctor", "-v"]

