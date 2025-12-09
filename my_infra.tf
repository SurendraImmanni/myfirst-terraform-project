# .................................
# ANSIBLE server
# .................................

resource "aws_instance" "ansible_server" {
  ami           = "ami-0d176f79571d18a8f"        # Amazon Linux 2 (ap-south-1)
  instance_type = "t3.small"

  # Use subnet from Jenkins VPC
  subnet_id = data.terraform_remote_state.network.outputs.subnet_id

  # Use Jenkins SG
  vpc_security_group_ids = [
    data.terraform_remote_state.network.outputs.security_group_id
  ]

  # Use Jenkins key pair
  key_name = data.terraform_remote_state.network.outputs.key_name

 user_data = <<-EOT
#!/bin/bash
sudo dnf update -y
sudo dnf install -y python3

# Install pip (works for Amazon Linux 2023)
curl -O https://bootstrap.pypa.io/get-pip.py
sudo python3 get-pip.py

# Install ansible
sudo pip3 install ansible

echo "Ansible Installed Successfully" > /home/ec2-user/ansible_installed.txt
EOT


  tags = {
    Name = "ansible-server"
  }
}

# ...............................
# DOCKER SERVER
# ...............................

resource "aws_instance" "docker_server" {
  ami           = "ami-0d176f79571d18a8f"
  instance_type = "t3.small"

  subnet_id = data.terraform_remote_state.network.outputs.subnet_id

  vpc_security_group_ids = [
    data.terraform_remote_state.network.outputs.security_group_id
  ]

  key_name = data.terraform_remote_state.network.outputs.key_name


  tags = {
    Name = "docker-server"
  }
}

# ................................
# OUTPUTS
# ................................

output "ansible_server_public_ip" {
  value = aws_instance.ansible_server.public_ip
}

output "docker_server_public_ip" {
  value = aws_instance.docker_server.public_ip
}