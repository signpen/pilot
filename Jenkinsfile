pipeline {
    agent any

    options {
        timestamps()
    }

    environment {
        REPO_URL = 'https://github.com/signpen/pilot.git'
        GIT_CREDENTIAL_ID = 'github-credentials'
        DEFAULT_DEPLOY_BRANCH = 'develop'
        DEPLOY_BRANCH = ''
    }

    stages {
        stage('Resolve deploy branch') {
            steps {
                deleteDir()
                git(
                    branch: env.DEFAULT_DEPLOY_BRANCH,
                    credentialsId: env.GIT_CREDENTIAL_ID,
                    url: env.REPO_URL
                )

                script {
                    sh '''
                        git fetch --prune origin \
                          +refs/heads/release/*:refs/remotes/origin/release/* \
                          +refs/heads/release-hotfix/*:refs/remotes/origin/release-hotfix/*
                    '''

                    def releaseBranchesRaw = sh(
                        script: "git for-each-ref --format='%(refname:strip=3)' refs/remotes/origin/release | sort",
                        returnStdout: true
                    ).trim()
                    def releaseHotfixBranchesRaw = sh(
                        script: "git for-each-ref --format='%(refname:strip=3)' refs/remotes/origin/release-hotfix | sort",
                        returnStdout: true
                    ).trim()

                    def releaseBranches = releaseBranchesRaw
                        ? releaseBranchesRaw.split("\\n").findAll { it?.trim() }
                        : []
                    def releaseHotfixBranches = releaseHotfixBranchesRaw
                        ? releaseHotfixBranchesRaw.split("\\n").findAll { it?.trim() }
                        : []
                    def activeBranches = releaseBranches + releaseHotfixBranches

                    if (activeBranches.size() > 1) {
                        error "배포 기준 브랜치가 2개 이상입니다. release/* 또는 release-hotfix/* 는 동시에 하나만 존재해야 합니다: ${activeBranches.join(', ')}"
                    }

                    env.DEPLOY_BRANCH = activeBranches
                        ? activeBranches[0]
                        : env.DEFAULT_DEPLOY_BRANCH

                    echo "Selected deploy branch: ${env.DEPLOY_BRANCH}"
                    echo "release/* branches found: ${releaseBranches ? releaseBranches.join(', ') : '(none)'}"
                    echo "release-hotfix/* branches found: ${releaseHotfixBranches ? releaseHotfixBranches.join(', ') : '(none)'}"
                }
            }
        }

        stage('Checkout deploy source') {
            steps {
                deleteDir()
                git(
                    branch: env.DEPLOY_BRANCH,
                    credentialsId: env.GIT_CREDENTIAL_ID,
                    url: env.REPO_URL
                )
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
