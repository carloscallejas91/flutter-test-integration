# Dockerfile otimizado para BUILD de APKs para o Firebase Test Lab
FROM debian:12.1

# --- VARIÁVEIS DE CONFIGURAÇÃO ---
ENV FLUTTER_VERSION=3.35.2
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

# --- INSTALAÇÃO DE DEPENDÊNCIAS DO SISTEMA ---
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl git unzip openjdk-17-jdk xz-utils ca-certificates wget sudo && \
    rm -rf /var/lib/apt/lists/*

# --- (Opcional) CONFIGURAÇÃO DE CERTIFICADOS CORPORATIVOS ---
# Descomente e ajuste se o seu Jenkins estiver em uma rede corporativa com proxy.
# COPY certs/*.crt /usr/local/share/ca-certificates/
# RUN update-ca-certificates

# --- INSTALAÇÃO DO FLUTTER ---
RUN wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -O /tmp/flutter.tar.xz && \
    mkdir -p ${FLUTTER_HOME} && \
    tar xf /tmp/flutter.tar.xz -C /opt && \
    rm /tmp/flutter.tar.xz

# --- INSTALAÇÃO DO ANDROID SDK (VERSÃO MÍNIMA PARA BUILD) ---
RUN mkdir -p ${ANDROID_SDK_ROOT} && \
    wget -q 'https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip' -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT} && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools ${ANDROID_SDK_ROOT}/latest && \
    mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/latest ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# Instala apenas os pacotes necessários para o BUILD.
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "build-tools;34.0.0" "platforms;android-34"

# --- CONFIGURAÇÃO DE USUÁRIO (BOA PRÁTICA) ---
RUN groupadd --gid 1001 flutterdev && \
    useradd --uid 1001 --gid 1001 --create-home --shell /bin/bash flutterdev
RUN chown -R flutterdev:flutterdev ${FLUTTER_HOME} ${ANDROID_SDK_ROOT}

USER flutterdev
WORKDIR /home/flutterdev/app

RUN git config --global --add safe.directory ${FLUTTER_HOME}
RUN flutter config --android-sdk ${ANDROID_SDK_ROOT}

# --- PREPARAÇÃO DA APLICAÇÃO ---
COPY --chown=flutterdev:flutterdev . .
RUN flutter pub get

CMD ["/bin/bash"]