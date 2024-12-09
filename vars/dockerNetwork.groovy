def call(def pipelineParams = [:]) {
  def regions = pipelineParams.regions

  pipeline {
    agent any

    options {
      lock(resource: "azure-terragrunt-lock")
    }

    stages {
        stage('elo') {
          steps {
            script {
              echo "elo"
            }
          }
        }

        stage('operations') {
          steps {
            script {
              parallel {
                script {
                  regions.each { region ->
                    stage("init-$region") {
                      steps {
                        script {
                          echo "init-$region"
                        }
                      }
                    }
                    stage("plan-$region") {
                      steps {
                        script {
                          echo "plan-$region"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
    }
  }
}