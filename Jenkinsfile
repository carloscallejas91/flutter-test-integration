// Jenkinsfile Declarativo para CI/CD de um projeto Flutter
// Constrói, Testa no Firebase Test Lab e Distribui para o Firebase App Distribution

pipeline {
    // 1. AGENTE DE EXECUÇÃO
    // Define que o pipeline será executado dentro de um container Docker
    // construído a partir do Dockerfile presente no repositório.
    agent {
        dockerfile {
            // CORREÇÃO: Usa 'customWorkspace' para definir um caminho de workspace absoluto dentro do container.
            // Isso evita que o Jenkins passe um caminho do Windows, resolvendo o erro "invalid path".
            customWorkspace '/home/jenkins/workspace'
            // Opcional: diretório onde o Dockerfile está localizado.
            dir '.'
        }
    }

    // 2. VARIÁVEIS DE AMBIENTE
    // Centraliza as configurações que podem mudar entre projetos ou ambientes.
    environment {
        // ID do seu projeto no Google Cloud.
        GCP_PROJECT_ID = 'test-integration-app-4e52e'
        // ID do seu App no Firebase (encontrado nas configurações do projeto).
        FIREBASE_APP_ID = '1:424599350937:android:5c7fd412fffd453bcb5208'
        // ID da credencial criada no Jenkins para a chave da Conta de Serviço.
        GCP_CREDENTIALS_ID = 'firebase-service-account-key'
        // Define o grupo de testadores no Firebase App Distribution.
        FIREBASE_TESTER_GROUP = 'qa-team'
    }

    // 3. ESTÁGIOS DO PIPELINE
    stages {
        // Estágio de Checkout: Baixa o código-fonte do repositório.
        stage('Checkout') {
            steps {
                script {
                    echo "Baixando o código-fonte..."
                    checkout scm
                }
            }
        }

        // Estágio de Build e Teste: Compila os APKs e executa os testes de integração.
        stage('Build & Test') {
            steps {
                // 'withCredentials' injeta a chave da conta de serviço em um arquivo temporário.
                withCredentials([file(credentialsId: "${GCP_CREDENTIALS_ID}", variable: 'GCP_KEY_FILE')]) {
                    script {
                        echo "Iniciando a autenticação com o Google Cloud..."
                        // Ativa a conta de serviço usando a chave JSON.
                        sh "gcloud auth activate-service-account --key-file=${GCP_KEY_FILE}"

                        echo "Configurando o projeto gcloud para ${GCP_PROJECT_ID}..."
                        sh "gcloud config set project ${GCP_PROJECT_ID}"

                        echo "Preparando o ambiente Flutter..."
                        // Baixa as dependências do projeto.
                        sh "flutter pub get"

                        echo "Limpando builds anteriores..."
                        sh "flutter clean"

                        echo "Construindo APK de debug..."
                        // Gera o APK principal do app.
                        sh "flutter build apk --debug"

                        echo "Construindo APK de teste de integração..."
                        // Gera o APK que contém os testes de integração.
                        sh "flutter build apk -t lib/main.dart --debug"

                        echo "Enviando testes para o Firebase Test Lab..."
                        // Executa o comando gcloud para rodar os testes em dispositivos reais.
                        sh """
                            gcloud firebase test android run \\
                                --type instrumentation \\
                                --app build/app/outputs/apk/debug/app-debug.apk \\
                                --test build/app/outputs/apk/debug/app-debug.apk \\
                                --device model=Pixel6,version=31,locale=pt_BR,orientation=portrait \\
                                --timeout 15m
                        """
                    }
                }
            }
        }

        // Estágio de Deploy: Distribui o APK para a equipe de QA.
        // Este estágio só será executado se o estágio 'Build & Test' for bem-sucedido.
        stage('Deploy to QA') {
            steps {
                script {
                    echo "Distribuindo o APK para o grupo '${FIREBASE_TESTER_GROUP}'..."
                    // Usa o comando 'firebase' (parte do gcloud SDK) para distribuir o app.
                    sh """
                        firebase appdistribution:distribute build/app/outputs/apk/debug/app-debug.apk \\
                            --app ${FIREBASE_APP_ID} \\
                            --release-notes "Build ${BUILD_NUMBER} - Nova versão para testes." \\
                            --groups "${FIREBASE_TESTER_GROUP}"
                    """
                }
            }
        }
    }

    // 4. AÇÕES PÓS-EXECUÇÃO
    // Define ações que serão executadas sempre ao final do pipeline,
    // independentemente do resultado (sucesso, falha, etc.).
    post {
        always {
            script {
                echo "Limpando o workspace..."
                // cleanWs() remove todos os arquivos do workspace para a próxima execução.
                cleanWs()
            }
        }
    }
}


