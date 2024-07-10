def trivy_scan(String imageName) {
                sh "docker run --name ${imageName} -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/Library/Caches:/root/.cache/ aquasec/trivy:0.53.0 image training_app -f template --template '@contrib/html.tpl' -o /report.html"
                sh "docker cp ${imageName}:/report.html ."
                sh "docker rm ${imageName}"
                sh "cat report.html"
                archiveArtifacts artifacts: 'report.html', followSymlinks: false
}
