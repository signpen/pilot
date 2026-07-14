def selectedDeployBranch = null

def defaultDeployBranchValue() {
    return 'develop'
}

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
                script {
                    String defaultDeployBranch = (env.DEFAULT_DEPLOY_BRANCH ?: defaultDeployBranchValue()).trim()

                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${defaultDeployBranch}"]],
                        userRemoteConfigs: [[
                            credentialsId: env.GIT_CREDENTIAL_ID,
                            url: env.REPO_URL,
                            refspec: "+refs/heads/${defaultDeployBranch}:refs/remotes/origin/${defaultDeployBranch} +refs/heads/release/*:refs/remotes/origin/release/* +refs/heads/release-hotfix/*:refs/remotes/origin/release-hotfix/*"
                        ]]
                    ])

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
                    String deployBranch = activeBranches
                        ? activeBranches[0].trim()
                        : defaultDeployBranch

                    if (activeBranches.size() > 1) {
                        error "배포 기준 브랜치가 2개 이상입니다. release/* 또는 release-hotfix/* 는 동시에 하나만 존재해야 합니다: ${activeBranches.join(', ')}"
                    }

                    if (!deployBranch) {
                        error '배포 브랜치를 결정할 수 없습니다.'
                    }

                    env.DEPLOY_BRANCH = deployBranch
                    selectedDeployBranch = deployBranch

                    echo "Selected deploy branch: ${deployBranch}"
                    echo "Default deploy branch: ${defaultDeployBranch}"
                    echo "release/* branches found: ${releaseBranches ? releaseBranches.join(', ') : '(none)'}"
                    echo "release-hotfix/* branches found: ${releaseHotfixBranches ? releaseHotfixBranches.join(', ') : '(none)'}"
                }
            }
        }

        stage('Checkout deploy source') {
            steps {
                deleteDir()
                script {
                    String branchToCheckout = (
                        selectedDeployBranch
                            ?: env.DEPLOY_BRANCH
                            ?: env.DEFAULT_DEPLOY_BRANCH
                            ?: defaultDeployBranchValue()
                    ).trim()

                    if (!branchToCheckout) {
                        error 'Checkout 대상 브랜치를 결정할 수 없습니다.'
                    }

                    git(
                        branch: branchToCheckout,
                        credentialsId: env.GIT_CREDENTIAL_ID,
                        url: env.REPO_URL
                    )

                    selectedDeployBranch = branchToCheckout
                    env.DEPLOY_BRANCH = branchToCheckout
                }
                echo "Checkout deploy branch: ${selectedDeployBranch ?: env.DEPLOY_BRANCH}"
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
                echo "Deploy target branch: ${selectedDeployBranch ?: env.DEPLOY_BRANCH ?: env.DEFAULT_DEPLOY_BRANCH ?: defaultDeployBranchValue()}"
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
