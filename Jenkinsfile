pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "yashasdocker/boardgame-app:${env.BUILD_ID}"
        REGISTRY_CREDENTIALS = credentials('dockerhub-cred')
        K8S_SERVER = 'https://172.31.34.168:6443'
    }

    stages {
        stage('SCM Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-cred') {
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'k8s-token', variable: 'K8S_TOKEN_SECRET')]) {
                        sh """
                            kubectl config set-cluster my-cluster --server=$K8S_SERVER --insecure-skip-tls-verify=true
                            kubectl config set-credentials jenkins --token=$K8S_TOKEN_SECRET
                            kubectl config set-context my-context --cluster=my-cluster --user=jenkins
                            kubectl config use-context my-context

                            sed -i "s|image:.*|image: $DOCKER_IMAGE|" deployment-service.yaml
                            
                            kubectl apply -f deployment-service.yaml
                            
                            sleep 30
                            
                            echo "=== Deployment Status ==="
                            kubectl get deployment/boardgame-app -o wide
                            
                            echo "=== Pod Status ==="
                            kubectl get pods -l app=boardgame-app -o wide
                            
                            echo "=== Service Status ==="
                            kubectl get service/boardgame-service -o wide
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "=== Pipeline Execution Summary ==="
            sh """
                echo "Pipeline completed with status: ${currentBuild.result}"
            """
        }
        success {
            echo "✅ CI/CD Pipeline Completed Successfully!"
            echo "🎉 Your application is deployed and available!"
        }
    }
}
