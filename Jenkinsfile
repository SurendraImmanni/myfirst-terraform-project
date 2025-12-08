pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-secret-key')
        SSH_KEY           = credentials('ssh-private-key-id')   // private key from credentials
        SSH_KEY_USR       = "ec2-user"                          // <--- Add username here
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
        stage('Terraform Plan') { steps { sh 'terraform plan -out=newtfplan' } }
        stage('Terraform Apply') { steps { sh 'terraform apply -auto-approve newtfplan' } }


        /*-----------------------------------------
         * 2. Fetch Output IPs
         *-----------------------------------------*/
        stage('Fetch Server IPs') {
            steps {
                script {
                    DOCKER_IP  = sh(script: "terraform output -raw docker_server_public_ip", returnStdout: true).trim()
                    ANSIBLE_IP = sh(script: "terraform output -raw ansible_server_public_ip", returnStdout: true).trim()
                }
                echo "Docker Server IP: ${DOCKER_IP}"
                echo "Ansible Server IP: ${ANSIBLE_IP}"
            }
        }

        /*-----------------------------------------
         * 2.5 Wait for SSH Availability
         *-----------------------------------------*/
        stage('Wait for SSH Ready') {
            steps {
                script {
                    echo "Waiting for Ansible server SSH to become available..."
                    for (int i = 1; i <= 20; i++) {
                        def result = sh(script: "ssh -o StrictHostKeyChecking=no -i $SSH_KEY ${SSH_KEY_USR}@${ANSIBLE_IP} 'echo ok' || true", returnStatus:true)
                        if (result == 0) {
                            echo "SSH is ready!"
                            break
                        }
                        echo "SSH not ready, retrying in 20 sec... attempt $i"
                        sleep 20
                    }
                }
            }
        }

        /*-----------------------------------------
         * 3. Create inventory.ini & Copy Files
         *-----------------------------------------*/
        stage('Generate Inventory & Copy Files') {
            steps {
                script {

                    writeFile file: "inventory.ini", text: """
[docker_server]
${DOCKER_IP} ansible_user=${SSH_KEY_USR} ansible_ssh_private_key_file=/home/${SSH_KEY_USR}/.ssh/id_rsa
"""

                    sh """
                        echo "Copying inventory & app folder to Ansible server..."
                        scp -o StrictHostKeyChecking=no -i $SSH_KEY inventory.ini ${SSH_KEY_USR}@${ANSIBLE_IP}:/home/${SSH_KEY_USR}/
                        scp -o StrictHostKeyChecking=no -i $SSH_KEY -r app ${SSH_KEY_USR}@${ANSIBLE_IP}:/home/${SSH_KEY_USR}/
                    """
                }
            }
        }

        /*-----------------------------------------
         * 4. Run Ansible Playbook on Ansible Server
         *-----------------------------------------*/
        stage('Run Ansible Playbook') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no -i $SSH_KEY ${SSH_KEY_USR}@${ANSIBLE_IP} \
                "ansible-playbook -i /home/${SSH_KEY_USR}/inventory.ini /home/${SSH_KEY_USR}/app/docker-creation.yml"
                """
            }
        }
    }

    /*-----------------------------------------
     * 5. Cleanup
     *-----------------------------------------*/
    post {
        always {
            cleanWs()
            echo "Workspace cleaned ✔"
        }
    }
}
