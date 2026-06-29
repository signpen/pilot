pipeline {
    agent any

    options {
        timestamps()
    }

    environment {
        REPO_URL = 'git@github.com:signpen/pilot.git'
        DEFAULT_DEPLOY_BRANCH = 'develop'
        DEPLOY_BRANCH = ''
    }

    stages {
        stage('Resolve deploy branch') {
            steps {
                script {
                    def releaseBranchesRaw = sh(
                        script: "git ls-remote --heads '${env.REPO_URL}' 'release/*' | awk '{print \\$2}' | sed 's#refs/heads/##' | sort",
                        returnStdout: true
                    ).trim()

                    def releaseBranches = releaseBranchesRaw
                        ? releaseBranchesRaw.split("\\n").findAll { it?.trim() }
                        : []

                    if (releaseBranches.size() > 1) {
                        error "release 브랜치가 여러 개입니다: ${releaseBranches.join(', ')}"
                    }

                    env.DEPLOY_BRANCH = releaseBranches
                        ? releaseBranches[0]
                        : env.DEFAULT_DEPLOY_BRANCH

                    echo "Selected deploy branch: ${env.DEPLOY_BRANCH}"
                    echo "Release branches found: ${releaseBranches ? releaseBranches.join(', ') : '(none)'}"
                }
            }
        }

        stage('Checkout deploy source') {
            steps {
                deleteDir()
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${env.DEPLOY_BRANCH}"]],
                    userRemoteConfigs: [[url: env.REPO_URL]]
                ])
                sh 'git branch --show-current || true'
                sh 'git rev-parse HEAD'
            }
        }

        stage('Build') {
            steps {
                script {
                    if (fileExists('ant.sh')) {
                        sh 'chmod +x ./ant.sh && ./ant.sh war'
                    } else if (fileExists('build.xml')) {
                        sh 'ant war'
                    } else {
                        echo 'No ant.sh or build.xml found; skipping build step in this example pipeline.'
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploy target branch: ${env.DEPLOY_BRANCH}"
                sh '''
                    if [ -f dist/pilot.war ]; then
                      echo "Deploying dist/pilot.war from ${DEPLOY_BRANCH}"
                    else
                      echo "No dist/pilot.war found; replace this block with the real deployment command."
                    fi
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'dist/pilot.war', allowEmptyArchive: true
        }
    }
}
