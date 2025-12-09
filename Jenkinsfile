pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-secret-key')
        SSH_KEY           = credentials('ssh-private-key-id')   // SSH private key
        SSH_KEY_USR       = "ec2-user"
    }

    stages {

        /*-----------------------------------------
         * 1. Clone Terraform Repo
         *-----------------------------------------*/
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/SurendraImmanni/myfirst-terraform-project.git'
            }
        }

        stage('Terraform Init') { steps { sh 'terraform init' } }
        stage('Terraform Validate') { steps { sh 'terraform validate' } }
        stage('Terraform Plan') { steps { sh 'terraform plan' } }
        stage('Terraform Apply') { steps { sh 'terraform apply -auto-approve' } }

        /*-----------------------------------------
         * 2. Fetch Output IPs
         *-----------------------------------------*/
        stage('Fetch Server IPs') {
            steps {
                script {
                    def docker_output  = sh(script: "terraform output -raw docker_server_public_ip", returnStdout: true).trim()
                    def ansible_output = sh(script: "terraform output -raw ansible_server_public_ip", returnStdout: true).trim()

                    env.DOCKER_IP  = docker_output
                    env.ANSIBLE_IP = ansible_output
                }
                echo "Docker Server IP: ${DOCKER_IP}"
                echo "Ansible Server IP: ${ANSIBLE_IP}"
            }
        }

        /*-----------------------------------------
         * 3. Wait for SSH Availability
         *-----------------------------------------*/
        stage('Wait for SSH Ready') {
            steps {
                script {
                    echo "Waiting for Ansible server SSH to become available..."
                    for (int i = 1; i <= 20; i++) {
                        def result = sh(script: "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${SSH_KEY_USR}@${ANSIBLE_IP} 'echo ok'", returnStatus:true)
                        if (result == 0) {
                            echo "SSH is ready!"
                            break
                        }
                        echo "SSH not ready → retrying in 20 sec (Attempt $i)"
                        sleep 20
                    }
                }
            }
        }

        /*-----------------------------------------
         * 4. Create Inventory & Copy Files
         *-----------------------------------------*/
        stage('Generate Inventory & Copy Files') {
            steps {
                script {
                    writeFile file: "inventory.ini", text: """
[docker_server]
${DOCKER_IP} ansible_user=${SSH_KEY_USR} ansible_ssh_private_key_file=/home/${SSH_KEY_USR}/.ssh/id_rsa
"""

                    sh """
                        echo "Copying inventory & app to Ansible Server..."
                        scp -o StrictHostKeyChecking=no -i ${SSH_KEY} inventory.ini ${SSH_KEY_USR}@${ANSIBLE_IP}:/home/${SSH_KEY_USR}/
                        scp -o StrictHostKeyChecking=no -i ${SSH_KEY} -r app ${SSH_KEY_USR}@${ANSIBLE_IP}:/home/${SSH_KEY_USR}/
                    """
                }
            }
        }

        /*-----------------------------------------
         * 5. Run Ansible Playbook
         *-----------------------------------------*/
        stage('Run Ansible Playbook') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${SSH_KEY_USR}@${ANSIBLE_IP} '
                    export PATH=/usr/local/bin:/usr/bin:/bin:/home/${SSH_KEY_USR}/.local/bin:\$PATH
                    ansible-playbook -i /home/${SSH_KEY_USR}/inventory.ini /home/${SSH_KEY_USR}/app/docker-creation.yml
                '
                """
            }
        }
    }

    post {
        always {
            cleanWs()
            echo "Workspace cleaned ✔"
        }
    }
}

