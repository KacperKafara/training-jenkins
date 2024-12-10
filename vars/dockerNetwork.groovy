def call(body) {
  def pipelineParams= [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = pipelineParams
  body()

  def regions = pipelineParams.regions

  node {
    timestamps {
      stage("test") {
        echo "${pipelineParams}"
      }

      parallel regions.collectEntries { region ->
        ["$region": {
          def workingDir = region
          lock(resource: "terragrunt-${region}") {
            stage("Init - $region") {
              echo "Init - $region"
            }
            stage("Plan - $region") {
              echo "Plan - $region"
            }
          }
        }]
      }
    }
  }
}