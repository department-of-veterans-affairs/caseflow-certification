podTemplate(cloud:'minikube', label:'caseflow-pod', containers: [
    containerTemplate(
        name: 'postgres', 
        image: 'postgres:9.5',
        ttyEnabled: true,
        privileged: false,
        alwaysPullImage: false
        ),
    containerTemplate(
        name: 'redis', 
        image: 'redis:3.2.9-alpine', 
        ttyEnabled: true,
        privileged: false,
        alwaysPullImage: false
    ),
     containerTemplate(
         name: 'ubuntu',
         image: 'kube-registry.kube-system.svc.cluster.local:31000/caseflow-pr-image-alan:1',
         ttyEnabled: true,
         alwaysPullImage: true,
         command: 'cat'
    )]){
    node('caseflow-pod') {

        stage('Clone repository') {
            container('ubuntu') {
                checkout scm
            }
        }

        stage('Test Setup') {
            container('ubuntu') {
                sh """
                Xvfb :99 -screen 0 1024x768x16 &
                export DISPLAY=:99
                cd ./client && npm install --no-optional
                bundle install --without production staging
                RAILS_ENV=test bundle exec rake db:create
                RAILS_ENV=test bundle exec rake db:schema:load
                """
            }
        }

        stage('Execute Tests') {
            container('ubuntu') {
                sh"""
                sleep 2343423423423423423423432
                RAILS_ENV=test bundle exec rake spec
                RAILS_ENV=test bundle exec rake ci:other
                """
            }
        }
    }
}