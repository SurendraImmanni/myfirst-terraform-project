pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        SSH_KEY               = credentials('ssh-private-key-id')
    }

    stages {

        /* --------------------------------------
         * 1. Checkout from GitHub
         * -------------------------------------- */
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/SurendraImmanni/myfirst-terraform-project.git'
            }
        }

        /* --------------------------------------
         * 2. Terraform Init
         * -------------------------------------- */
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        /* --------------------------------------
         * 3. Terraform Validate
         * -------------------------------------- */
        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        /* --------------------------------------
         * 4. Terraform Plan
         * -------------------------------------- */
        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        /* --------------------------------------
         * 5. Terraform Apply
         * -------------------------------------- */
        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }

        /* --------------------------------------
         * 6. Fetch Docker Server IP
         * -------------------------------------- */
        stage('Fetch Outputs') {
            steps {
                sh 'terraform output -json docker_server_public_ip > docker_ip.json'
            }
        }

        /* --------------------------------------
         * 7. Generate Ansible Inventory
         * -------------------------------------- */
        stage('Generate Inventory') {
            steps {
                script {
                    def ip = sh(script: "cat docker_ip.json | jq -r '.'", returnStdout: true).trim()

                    writeFile file: 'inventory.ini', text: """
[docker_server]
${ip} ansible_user=ec2-user ansible_ssh_private_key_file=${SSH_KEY}
"""
                }

                sh "cat inventory.ini"
            }
        }

        /* --------------------------------------
         * 8. Run Ansible Playbook (Inside dockerfiles/ folder)
         * -------------------------------------- */
        stage('Run Ansible Playbook') {
            steps {
                sh """
                    ansible-playbook -i inventory.ini docker-creation.yml \
                    --private-key ${SSH_KEY} \
                    --ssh-extra-args='-o StrictHostKeyChecking=no'
                """
            }
        }
    }
}
