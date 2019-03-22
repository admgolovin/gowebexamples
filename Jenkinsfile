def branch
def revision
def currentSlot
def tagVar
def userInput

pipeline {
    agent {
        kubernetes {
            label 'build-service-pod'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    job: build-service
spec:
  containers:
  - name: helm
    image: alpine/helm
    command: ["cat"]
    tty: true
  - name: hugo
    image: ubuntu
    command: ["cat"]
    tty: true
  - name: docker
    image: docker:18.09.2
    command: ["cat"]
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }
    options {
        skipDefaultCheckout true
    }
    
        stage ('checkout') {
            steps{
                script{
                    print "Checkout stage is launched"
                    def mycommit = checkout scm
                    for (val in mycommit) {
                        print "key = ${val.key}, value = ${val.value}"
                    }
                    revision = sh(script: 'git log -1 --format=\'%h.%ad\' --date=format:%Y%m%d-%H%M | cat', returnStdout: true).trim()

                }
            }
        }
        stage ('compile') {
            steps {
                container('hugo') {
                    sh 'apt-get update && apt-get install -y hugo'
                    sh 'hugo'
                }
            }
        }
        stage ('build artifact') {
            steps {
                container('docker') {
                    script {
                        registryIp= "818353068367.dkr.ecr.eu-central-1.amazonaws.com/tony"
                        sh "docker build . -t ${registryIp}:${revision} --build-arg REVISION=${revision}"
                        docker.withRegistry("https://818353068367.dkr.ecr.eu-central-1.amazonaws.com", "ecr:eu-central-1:antons-aws") {
                            sh "docker push ${registryIp}:${revision}"
                        }
                    }
                }
            }
        }
        stage ('Deploy') {
            steps {
                container('helm') {
                    script {
                        currentSlot = sh(script: "helm get values --all hello-go | grep 'productionSlot:' | cut -d ' ' -f2 | tr -d '[:space:]'", returnStdout: true).trim()
                        sh "echo ${currentSlot}"
                        if (currentSlot == "blue") {
                                newSlot="green"
                                tagVar="imageGreen"
                        } else if (currentSlot == "green") {
                                newSlot="blue"
                                tagVar="imageBlue"
                        } else {
                            sh "helm install -n hello-go go-hello-world --set imageBlue.tag=${revision},blue.enabled=true"
                            return
                        }
                        sh "helm upgrade hello-go go-hello-world --set ${tagVar}.tag=${revision},${newSlot}.enabled=true --reuse-values"
                        userInput = input(message: 'Switch productionSlot? y\\n', parameters: [[$class: 'TextParameterDefinition', defaultValue: 'uat', description: 'Environment', name: 'env']])
                        if (userInput == "y") {
                            sh "helm upgrade hello-go go-hello-world --set productionSlot=${newSlot} --reuse-values"
                        }
                        userInput = input(message: 'Delete old deployment? y\\n', parameters: [[$class: 'TextParameterDefinition', defaultValue: 'uat', description: 'Environment', name: 'env']])
                        if (userInput == "y") {
                            sh "helm upgrade hello-go go-hello-world --set ${currentSlot}.enabled=false --reuse-values"
                        }
                    }
                }
            }
        }
    }
}
