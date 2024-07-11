def trivy_scan(String imageName) {
                sh "docker run --name trivy-test -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/Library/Caches:/root/.cache/ aquasec/trivy:0.53.0 image ${imageName} -f template --template '@contrib/html.tpl' -o /report.html"
                sh "docker cp trivy-test:/report.html ."
                sh "docker rm trivy-test"
                sh "cat report.html"
                archiveArtifacts artifacts: 'report.html', followSymlinks: false
}
