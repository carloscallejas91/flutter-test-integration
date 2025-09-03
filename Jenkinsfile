pipeline {
    agent any

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
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Construindo imagem de build..."
                    docker.build(IMAGE_NAME, '.')
                }
            }
        }

        stage('Build APKs') {
            steps {
                script {
                    echo "Construindo APKs do app e dos testes..."
                    docker.image(IMAGE_NAME).inside {
                        sh '''
                            cd android
                            ./gradlew clean
                            ./gradlew app:assembleDebug assembleDebugAndroidTest
                        '''
                    }
                }
            }
        }

        stage('Run Tests on Firebase Test Lab') {
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
            // Este estágio só roda se os testes no Test Lab passarem
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
                try {
                    docker.image(IMAGE_NAME).remove()
                } catch (err) {
                    echo "Imagem ${IMAGE_NAME} não encontrada para remoção."
                }
            }
        }
    }
}