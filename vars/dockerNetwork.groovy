def call(def pipelineParams = [:]) {
  pipeline {
    agent any

    stages {
        stage('Hello') {
            steps {
                echo "$pipelineParams.msg"
            }
        }
    }
  }
}