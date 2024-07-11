def isDockerNetworkExists(String networkName) {
  return sh(script: "docker network inspect ${networkName} > /dev/null 2>&1", returnStatus: true)
}
