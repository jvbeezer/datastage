pipeline {
    agent {
        label 'mettleci'
    }
    parameters {
        string(name: 'domainName', defaultValue: 'urease1.fyre.ibm.com:9443', description: 'DataStage Service Tier')
        string(name: 'serverName', defaultValue: 'UREASE1.FYRE.IBM.COM', description: 'DataStage Engine Tier')
        string(name: 'projectName', defaultValue: 'dstage1', description: 'Logical Project Name')
        string(name: 'environmentId', defaultValue: 'ci', description: 'Environment Identifer')
        string(name: 'prodProjectName', defaultValue: 'production', description: 'Logical Production  Project Name')
        string(name: 'prodEnvironmentId', defaultValue: 'prod', description: 'Production Environment Identifer')
    }
    environment {
        DATASTAGE_PROJECT = "${params.projectName}_${params.environmentId}"
        ENVIRONMENT_ID = "${params.environmentId}"
        METTLE_SHELL = "/usr/bin/mettleci"
        ISTOOL_SHELL = "/opt/IBM/InformationServer/Clients/istools/cli/istool.sh"
    }
    stages {
        stage("Deploy") {
            agent { label "mettleci" }

            steps {
                withCredentials([usernamePassword(credentialsId: 'mci-user', passwordVariable: 'datastagePassword', usernameVariable: 'datastageUsername')]) {

                    //sh label: 'Create DataStage Project', script: "${env.METTLE_SHELL} datastage create-project -domain ${params.domainName} -server ${params.serverName} -project ${env.DATASTAGE_PROJECT} -username ${datastageUsername} -password ${datastagePassword}"
                    
                    sh label: 'Substitute parameters in DataStage config', script: "${env.METTLE_SHELL} properties config -baseDir datastage -filePattern \"*.sh\" -filePattern \"DSParams\" -filePattern \"Parameter Sets/*/*\" -properties var.${params.environmentId} -outDir config"
                    //sh label: 'Transfer DataStage config and filesystem assets', script: "${env.METTLE_SHELL} remote upload -host ${params.serverName} -username ${datastageUsername} -password ${datastagePassword} -transferPattern \"filesystem/**/*,config/*\" -destination \"${env.BUILD_TAG}\""
                    //sh label: 'Deploy DataStage config and file system assets', script: "${env.METTLE_SHELL} remote execute -host ${params.serverName} -username ${datastageUsername} -password ${datastagePassword} -script \"config/deploy.sh\""

                    //sh label: 'Deploy DataStage project', script: "${env.METTLE_SHELL} datastage deploy -domain ${params.domainName} -server ${params.serverName} -project ${env.DATASTAGE_PROJECT} -username ${datastageUsername} -password ${datastagePassword} -assets datastage -parameter-sets \"config\\Parameter Sets\" -threads 8 -project-cache \"/opt/dm/mci/cache/${params.serverName}/${env.DATASTAGE_PROJECT}\""

                }
            }
            post {
                always {
                    junit testResults: 'log/**/mettleci_compilation.xml', allowEmptyResults: true
                    withCredentials([usernamePassword(credentialsId: 'urease1', passwordVariable: 'OSPassword', usernameVariable: 'OSUserName')]) {
                        sh label: 'Cleanup temporary files', script: "${env.METTLE_SHELL} remote execute -host ${params.serverName} -username ${OSUserName} -password ${OSPassword} -script \"config/cleanup.sh\""
                    }
                    deleteDir()
                }
            }
        }
        stage("Test") {
            parallel {
                stage('Static Analysis') {
                    agent { label "mettleci" }
                    
                    steps {
                        sh label: 'Perform static analysis', script: "${env.METTLE_SHELL} compliance test -assets datastage -report \"compliance_report.xml\" -junit -rules Compliance -project-cache \"/opt/dm/mci/cache/${params.serverName}/${env.DATASTAGE_PROJECT}\""
                    }
                    post {
                        always {
                            junit testResults: 'compliance_report.xml', allowEmptyResults: true
                            deleteDir()
                        }
                    }
                }
                stage('Unit Tests') {
                    agent { label "mettleci" }
                    
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'mci-user', passwordVariable: 'datastagePassword', usernameVariable: 'datastageUsername'),usernamePassword(credentialsId: 'urease1', passwordVariable: 'OSPassword', usernameVariable: 'OSUserName')]) {
                            //sh label: 'Upload unit test specs', script: "${env.METTLE_SHELL} remote upload -host ${params.serverName} -username ${datastageUsername} -password ${datastagePassword} -source \"unittest\" -transferPattern \"**/*\" -destination \"/opt/dm/mci/specs/${env.DATASTAGE_PROJECT}\""
                            sh label: 'Execute unit tests for changed DataStage jobs', script: "${env.METTLE_SHELL} unittest test -domain ${params.domainName} -server ${params.serverName} -project ${env.DATASTAGE_PROJECT} -username ${datastageUsername} -password ${datastagePassword} -specs unittest -reports test-reports -project-cache \"/opt/dm/mci/cache/${params.serverName}/${env.DATASTAGE_PROJECT}\""
                            sh label: 'Retrieve unit test results', script: "${env.METTLE_SHELL} remote download -host ${params.serverName} -username ${OSUserName} -password ${OSPassword} -source \"/opt/dm/mci/reports\" -transferPattern \"${env.DATASTAGE_PROJECT}/**/*.xml\" -destination \"test-reports\""
                        }
                    }
                    post {
                        always {
                            junit testResults: 'test-reports/**/*.xml', allowEmptyResults: true
                            deleteDir()
                        }
                    }
                }
            }
        }
        stage("Promote") {
            parallel {
                stage('1.Production') {
                    agent { label "mettleci" }
                    
                    environment {
                        DATASTAGE_PROJECT = "${prodProjectName}"
                        ENVIRONMENT_ID = "${prodEnvironmentId}"
                        ISX = "/Jobs/Mortgage_Demo_Assets/Mortgage_Join_Demo.isx"
                    }
                    steps {

                        withCredentials([usernamePassword(credentialsId: 'mci-user', passwordVariable: 'datastagePassword', usernameVariable: 'datastageUsername'),usernamePassword(credentialsId: 'urease1', passwordVariable: 'OSPassword', usernameVariable: 'OSUserName')]) {

                            //sh label: 'Create DataStage Project', script: "${env.METTLE_SHELL} datastage create-project -domain ${domainName} -server ${serverName} -project ${env.DATASTAGE_PROJECT} -username ${datastageUsername} -password ${datastagePassword}"
                            sh label: 'Substitute parameters in DataStage config', script: "${env.METTLE_SHELL} properties config -baseDir datastage -filePattern \"*.sh\" -filePattern \"DSParams\" -filePattern \"Parameter Sets/*/*\" -properties var.${params.environmentId} -outDir config"
                            sh label: 'Transfer DataStage config and filesystem assets', script: "${env.METTLE_SHELL} remote upload -host ${serverName} -username ${OSUserName} -password ${OSPassword} -transferPattern \"filesystem/**/*,config/*\" -destination \"${env.BUILD_TAG}\""
                            //sh label: 'Deploy DataStage config and file system assets', script: "${env.METTLE_SHELL} remote execute -host ${serverName} -username ${OSUserName} -password ${OSPassword} -script \"deploy.sh\""
                            
                            //Failing because it's running on Linux and can't compile!
                            //sh label: 'Deploy DataStage project', script: "${env.METTLE_SHELL} datastage deploy -domain ${domainName} -server ${serverName} -project ${env.DATASTAGE_PROJECT} -username ${datastageUsername} -password ${datastagePassword} -assets datastage -threads 8 -project-cache \"/opt/dm/mci/cache/${params.serverName}/${env.DATASTAGE_PROJECT}\""
                            //Use Import instead
                            sh label: 'Deploy DataStage project', script: "${env.METTLE_SHELL} isx import -domain ${domainName} -server ${serverName} -project ${env.DATASTAGE_PROJECT} -username ${datastageUsername} -password ${datastagePassword} -location datastage -threads 8"  
                            //Workbench doesn't import executables, will have to hardcode the import command for now
                            //sh label: 'Deploy DataStage project', script: "${env.METTLE_SHELL} import -domain ${domainName} -username ${datastageUsername} -password ${datastagePassword} -datastage ' \"${serverName}\/${env.DATASTAGE_PROJECT}\" ' -archive \"datastage\/${env.DATASTAGE_PROJECT}\\"
                        }
                    }
                    post {
                        always {
                            withCredentials([usernamePassword(credentialsId: 'urease1', passwordVariable: 'OSPassword', usernameVariable: 'OSUserName')]) {
                                sh label: 'Cleanup temporary files', script: "${env.METTLE_SHELL} remote execute -host ${serverName} -username ${OSUserName} -password ${OSPassword} -script \"config/cleanup.sh\""
                            }
                            deleteDir()
                        }
                    }
                }
            }
        }
    }
}