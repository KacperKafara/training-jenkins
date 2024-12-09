def call(def pipelineParams = [:]) {
  pipeline {
    agent any

    options {
      lock(resource: "azure-terragrunt-lock")
    }

    stages {
        stage('Hello') {
            steps {
                echo "$pipelineParams.msg"
            }
        }
    }
  }
}