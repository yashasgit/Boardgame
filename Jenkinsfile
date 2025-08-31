pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "yashasdocker/boardgame-app:${env.BUILD_ID}"
        REGISTRY_CREDENTIALS = credentials('dockerhub-cred')
        K8S_SERVER = 'https://172.31.34.168:6443'
        // REMOVED: K8S_TOKEN = credentials('k8s-token') - This is now handled securely in the stage
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
                    dockerImage = docker.build("${DOCKER_IMAGE}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-cred') {
                        dockerImage.push()
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Handle the token securely using withCredentials
                    withCredentials([string(credentialsId: 'k8s-token', variable: 'K8S_TOKEN_SECRET')]) {
                        sh '''
                            # Configure kubectl with the token securely
                            kubectl config set-cluster my-cluster --server=$K8S_SERVER --insecure-skip-tls-verify=true
                            kubectl config set-credentials jenkins --token=$K8S_TOKEN_SECRET
                            kubectl config set-context my-context --cluster=my-cluster --user=jenkins
                            kubectl config use-context my-context

                            # Update and deploy
                            sed -i "s|image: yashasdocker/boardgame-app:latest|image: $DOCKER_IMAGE|" deployment-service.yaml
                            kubectl apply -f deployment-service.yaml
                            
                            # Wait for deployment to complete
                            kubectl rollout status deployment/boardgame-app --timeout=120s
                            
                            # Verify deployment
                            echo "Deployment status:"
                            kubectl get deployment/boardgame-app
                            echo "Service status:"
                            kubectl get service/boardgame-service
                        '''
                    }
                }
            }
        }
    }

    post {
        failure {
            echo 'Pipeline failed! Check the logs.'
        }
        success {
            echo 'Pipeline succeeded! Application is deployed.'
            sh "kubectl get svc boardgame-service -o wide"
        }
    }
}
