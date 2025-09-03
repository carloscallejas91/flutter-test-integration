pipeline {
    // (REMOVIDO) A declaração de agente foi movida para dentro dos estágios.
    // agent any

    environment {
        // ID do seu projeto no Google Cloud/Firebase
        FIREBASE_PROJECT_ID = "test-integration-app-4e52e"
        // ID da credencial que você criou no Jenkins no Passo 2
        SERVICE_ACCOUNT_CREDENTIALS_ID = "firebase-service-account-key"
        // Nome da imagem Docker a ser construída
        IMAGE_NAME = "test-integration-app/flutter-builder:${env.BUILD_NUMBER}"
        // ID do seu App no Firebase para o App Distribution (encontre em Configurações do Projeto no Firebase)
        FIREBASE_APP_ID="1:424599350937:android:5c7fd412fffd453bcb5208"
    }

    stages {
        stage('Checkout Code') {
            // Este estágio ainda roda no agente principal (Windows)
            agent any
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            // Este estágio também roda no agente principal
            agent any
            steps {
                script {
                    echo "Construindo imagem de build..."
                    docker.build(IMAGE_NAME, '.')
                }
            }
        }

        stage('Build APKs') {
            // (AJUSTADO) Este estágio agora roda DENTRO de um container Docker.
            agent {
                // Diz ao Jenkins para usar a imagem que acabamos de construir como o ambiente para este estágio.
                docker { image IMAGE_NAME }
            }
            steps {
                script {
                    echo "Construindo APKs do app e dos testes..."
                    // Os comandos agora são executados diretamente, pois já estamos no ambiente correto.
                    sh '''
                        cd android
                        ./gradlew clean
                        ./gradlew app:assembleDebug assembleDebugAndroidTest
                    '''
                }
            }
        }

        // Os estágios seguintes não precisam rodar dentro do container, pois usam a gcloud CLI do host.
        stage('Run Tests on Firebase Test Lab') {
            agent any
            steps {
                withCredentials([file(credentialsId: SERVICE_ACCOUNT_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        echo "Autenticando com o Google Cloud..."
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        gcloud config set project ${FIREBASE_PROJECT_ID}

                        echo "Enviando APKs para o Firebase Test Lab..."
                        gcloud firebase test android run \
                          --type instrumentation \
                          --app android/app/build/outputs/apk/debug/app-debug.apk \
                          --test android/app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
                          --device model=pixel6,version=34,locale=pt_BR,orientation=portrait \
                          --timeout 15m
                    '''
                }
            }
        }

        stage('Deploy to Firebase App Distribution') {
            agent any
            steps {
                withCredentials([file(credentialsId: SERVICE_ACCOUNT_CREDENTIALS_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        echo "Testes passaram! Distribuindo APK para o grupo de QA..."
                        gcloud firebase appdistribution apps distribute android/app/build/outputs/apk/debug/app-debug.apk \
                          --app ${FIREBASE_APP_ID} \
                          --release-notes "Build ${BUILD_NUMBER} via Jenkins. Testes de integração passaram." \
                          --groups "qa-testers"
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finalizado. Limpando..."
            cleanWs()
            script {
                // A limpeza da imagem Docker agora é feita de forma um pouco diferente.
                // O Jenkins pode não conseguir remover a imagem que ele mesmo usou como agente.
                // Esta limpeza é opcional e pode ser removida se causar problemas.
                try {
                    sh "docker rmi ${IMAGE_NAME}"
                } catch (err) {
                    echo "Imagem ${IMAGE_NAME} não encontrada ou não pôde ser removida."
                }
            }
        }
    }
}