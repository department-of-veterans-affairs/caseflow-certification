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
         image: 'kube-registry.kube-system.svc.cluster.local:31000/caseflow',
         ttyEnabled: true,
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
                apt-get update
                apt-get install -y chromedriver pdftk xvfb
                cd ./client && npm install --no-optional
                bundle install --without production staging
                bundle exec rake db:create
                bundle exec rake db:schema:load
                export PATH=$PATH:/usr/lib/chromium-browser/
                sleep 2343423423423423423423432
                echo $PATH
                cd ..
                export DISPLAY=:99.0
                sh -e /etc/init.d/xvfb start
                sleep 3
                """
            }
        }

        stage('script') {
            container('ubuntu') {
                sh"""
                RAILS_ENV=test bundle exec rake spec
                RAILS_ENV=test bundle exec rake ci:other
                mv node_modules node_modules_bak && npm install --production --no-optional && npm run build:production
                - rm -rf node_modules && mv node_modules_bak node_modules
                """
            }
        }
    }
}