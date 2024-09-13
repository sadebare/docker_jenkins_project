pipeline {
    agent any

    tools {
        maven 'maven3.9' // Name from Global Tool Configuration
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    checkout([$class: 'GitSCM', 
                      branches: [[name: '*/main']], 
                      doGenerateSubmoduleConfigurations: false, 
                      extensions: [], 
                      userRemoteConfigs: [[
                        url: 'https://github.com/sadebare/docker_jenkins_project.git', 
                        credentialsId: 'github-token'
                      ]]
                    ])
                }
            }
        }
        stage('Build with Maven') {
            steps {
                script {
                    sh 'mvn -B clean package -DskipTests'
                }
            }
        }
        stage('Transfer WAR File') {
            steps {
                script {
                    sshPublisher(publishers: [sshPublisherDesc(
                        configName: 'dockerhost', 
                        transfers: [
                            sshTransfer(
                                cleanRemote: false, 
                                excludes: '', 
                                execCommand: '', // No command for transfer step
                                execTimeout: 120000, 
                                flatten: false, 
                                makeEmptyDirs: false, 
                                noDefaultExcludes: false, 
                                patternSeparator: '[, ]+', 
                                remoteDirectory: '/home/dockeradmin', 
                                remoteDirectorySDF: false, 
                                removePrefix: 'webapp/target/', 
                                sourceFiles: 'webapp/target/*.war'
                            )
                        ], 
                        usePromotionTimestamp: false, 
                        useWorkspaceInPromotion: false, 
                        verbose: true // Enable verbose logging
                    )])
                }
            }
        }
        stage('Run Docker Commands') {
            steps {
                script {
                    sshPublisher(publishers: [sshPublisherDesc(
                        configName: 'dockerhost', 
                        transfers: [
                            sshTransfer(
                                cleanRemote: false, 
                                excludes: '', 
                                execCommand: '''
                                # Ensure we are in the right directory
                                cd /home/dockeradmin/home/dockeradmin;

                                # List contents of the directory before Docker build
                                echo "Contents of /home/dockeradmin/home/dockeradmin before Docker build:";
                                ls -la;

                                # Remove existing container if it exists
                                if [ $(docker ps -a -q -f name=registerapp) ]; then
                                    docker stop registerapp;
                                    docker rm registerapp;
                                fi;

                                # Build Docker image without cache
                                docker build --no-cache -t regapp:44 .;

                                # Run Docker container with new image
                                docker run -d --name registerapp -p 8087:8080 regapp:44;

                                # List contents of the directory after Docker build
                                echo "Contents of /home/dockeradmin/home/dockeradmin after Docker build:";
                                ls -la;
                                ''',
                                execTimeout: 120000, 
                                flatten: false, 
                                makeEmptyDirs: false, 
                                noDefaultExcludes: false, 
                                patternSeparator: '[, ]+', 
                                remoteDirectory: '/home/dockeradmin', 
                                remoteDirectorySDF: false
                            )
                        ], 
                        usePromotionTimestamp: false, 
                        useWorkspaceInPromotion: false, 
                        verbose: true // Enable verbose logging
                    )])
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution complete.'
        }
        success {
            echo 'Build and deployment were successful.'
        }
        failure {
            echo 'Build or deployment failed. Check logs for more details.'
        }
    }
}
