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

        // Jenkins Credentials에 등록한 Tomcat 서버 SSH private-key credential ID로 변경하세요.
        TOMCAT_SSH_CREDENTIAL_ID = 'tomcat-server-ssh-key'
        TOMCAT_SSH_HOST = 'tomcat.example.internal'
        TOMCAT_SSH_USER = 'deploy'
        TOMCAT_SSH_PORT = '22'

        // 별도 health endpoint가 없을 때의 Tomcat connector 확인용 URL 예시입니다.
        // 실제 애플리케이션 context root가 있다면 그 URL로 바꾸는 편이 더 좋습니다.
        HEALTHCHECK_URL = 'http://127.0.0.1:8080/'
        // 대형 WAR의 첫 기동 시간을 고려한 예시값입니다.
        HEALTHCHECK_INITIAL_DELAY_SEC = '15'
        HEALTHCHECK_RETRY_INTERVAL_SEC = '10'
        HEALTHCHECK_TIMEOUT_SEC = '300'
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
                    writeFile file: '.deploy-branch', text: "${deployBranch}\n"
                    stash name: 'deploy-branch-meta', includes: '.deploy-branch'

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
                unstash 'deploy-branch-meta'
                script {
                    String resolvedDeployBranch = fileExists('.deploy-branch')
                        ? readFile('.deploy-branch').trim()
                        : ''
                    String branchToCheckout = (
                        resolvedDeployBranch
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

                    env.DEPLOY_BRANCH = branchToCheckout
                    writeFile file: '.deploy-branch', text: "${branchToCheckout}\n"

                    echo "Checkout deploy branch: ${branchToCheckout}"
                }
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
                script {
                    String deployTargetBranch = fileExists('.deploy-branch')
                        ? readFile('.deploy-branch').trim()
                        : ((env.DEPLOY_BRANCH ?: env.DEFAULT_DEPLOY_BRANCH ?: defaultDeployBranchValue()).trim())

                    env.DEPLOY_BRANCH = deployTargetBranch
                    echo "Deploy target branch: ${deployTargetBranch}"
                }
                sh '''
                    if [ -f dist/pilot.war ]; then
                      echo "Deploying dist/pilot.war from ${DEPLOY_BRANCH}"
                    else
                      echo "No dist/pilot.war found; replace this block with the real deployment command."
                    fi
                '''
            }
        }

        stage('Health check') {
            steps {
                script {
                    sshagent(credentials: [env.TOMCAT_SSH_CREDENTIAL_ID]) {
                        sh '''
                            # curl은 Tomcat 서버 안에서 실행한다.
                            # 따라서 127.0.0.1은 Jenkins agent가 아니라 Tomcat 서버 자신을 가리킨다.
                            ssh -p "${TOMCAT_SSH_PORT}" \
                                -o BatchMode=yes \
                                -o ConnectTimeout=10 \
                                -o StrictHostKeyChecking=yes \
                                "${TOMCAT_SSH_USER}@${TOMCAT_SSH_HOST}" \
                                "HEALTHCHECK_URL='${HEALTHCHECK_URL}' HEALTHCHECK_INITIAL_DELAY_SEC='${HEALTHCHECK_INITIAL_DELAY_SEC}' HEALTHCHECK_RETRY_INTERVAL_SEC='${HEALTHCHECK_RETRY_INTERVAL_SEC}' HEALTHCHECK_TIMEOUT_SEC='${HEALTHCHECK_TIMEOUT_SEC}' bash -s" <<'REMOTE'
                            # 첫 기동은 WAR 확장, Spring 초기화, 캐시 준비 등으로 느릴 수 있으므로
                            # 즉시 실패시키지 않고, 전체 제한 시간 안에서 재시도한다.
                            set -u

                            echo "Waiting ${HEALTHCHECK_INITIAL_DELAY_SEC}s before health check: ${HEALTHCHECK_URL}"
                            sleep "${HEALTHCHECK_INITIAL_DELAY_SEC}"

                            deadline=$(( $(date +%s) + HEALTHCHECK_TIMEOUT_SEC ))
                            attempt=1

                            while true; do
                              http_code="$(curl --silent --show-error --output /tmp/healthcheck-response.txt \
                                --write-out '%{http_code}' --connect-timeout 3 --max-time 10 \
                                "${HEALTHCHECK_URL}" || true)"

                              # 별도 health endpoint가 없을 때는 404/401/403도 Tomcat HTTP Connector가
                              # 응답한 것으로 보고 기동 성공으로 처리한다. 앱 context URL을 쓰는 경우에는
                              # 이 조건을 2xx 또는 3xx로 좁혀도 된다.
                              case "${http_code}" in
                                2*|3*|401|403|404)
                                  echo "Health check passed on attempt ${attempt}: HTTP ${http_code} (${HEALTHCHECK_URL})"
                                  cat /tmp/healthcheck-response.txt || true
                                  exit 0
                                  ;;
                              esac

                              now=$(date +%s)
                              if [ "${now}" -ge "${deadline}" ]; then
                                echo "Health check failed: no HTTP response from ${HEALTHCHECK_URL} within ${HEALTHCHECK_TIMEOUT_SEC}s."
                                echo "Last HTTP code: ${http_code:-curl connection failure}"
                                exit 1
                              fi

                              remaining=$(( deadline - now ))
                              echo "Health check attempt ${attempt} failed (HTTP ${http_code:-000}); retrying in ${HEALTHCHECK_RETRY_INTERVAL_SEC}s (${remaining}s remaining)."
                              attempt=$(( attempt + 1 ))
                              sleep "${HEALTHCHECK_RETRY_INTERVAL_SEC}"
                            done
REMOTE
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'dist/pilot.war', allowEmptyArchive: true
        }
    }
}
