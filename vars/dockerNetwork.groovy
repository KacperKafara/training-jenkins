def call(body) {
  def regions = body.terragrunt.regions
  body()

  node {
    timestamps {
      stage("test") {
        echo "test"
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