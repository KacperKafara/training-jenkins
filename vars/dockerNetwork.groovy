def call(body) {
  def config = [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = config
  body()

  if (!config.terragrunt?.regions) {
    echo "${config}"
    echo "${config.terragrunt}"
    error "Missing required property: terragrunt.regions"
  }

  def regions = config.terragrunt.regions

  node {
    timestamps {
      stage("test") {
        echo "${regions}"
        echo "${config}"
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