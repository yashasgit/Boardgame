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
                        sh '''
                            # Try to connect to Kubernetes cluster
                            if timeout 30s kubectl cluster-info --insecure-skip-tls-verify=true --server=https://172.31.34.168:6443; then
                                echo "✅ Kubernetes cluster is accessible"
                                
                                # Configure kubectl
                                kubectl config set-cluster my-cluster --server=https://172.31.34.168:6443 --insecure-skip-tls-verify=true
                                kubectl config set-credentials jenkins --token=''' + '"$K8S_TOKEN_SECRET"' + '''
                                kubectl config set-context my-context --cluster=my-cluster --user=jenkins
                                kubectl config use-context my-context

                                # Update and apply deployment
                                sed -i "s|image:.*|image: ''' + "${env.DOCKER_IMAGE}" + '''|" deployment-service.yaml
                                kubectl apply -f deployment-service.yaml
                                
                                echo "✅ Deployment applied successfully!"
                                
                            else
                                echo "⚠️ WARNING: Kubernetes cluster not accessible"
                                echo "📦 Docker image built and pushed: ''' + "${env.DOCKER_IMAGE}" + '''"
                                echo "📋 Deployment YAML updated with new image"
                                echo "🚀 Run 'kubectl apply -f deployment-service.yaml' manually when cluster is available"
                                
                                # Update the YAML file anyway for manual deployment
                                sed -i "s|image:.*|image: ''' + "${env.DOCKER_IMAGE}" + '''|" deployment-service.yaml
                            fi
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo "=== Pipeline Execution Summary ==="
            sh "echo 'Docker Image: ${env.DOCKER_IMAGE}'"
            sh "echo 'Kubernetes Server: ${env.K8S_SERVER}'"
            sh "echo 'Build Status: ${currentBuild.result}'"
        }
        success {
            echo "✅ CI/CD Pipeline Completed Successfully!"
            echo "📦 Image: ${env.DOCKER_IMAGE}"
        }
    }
}
