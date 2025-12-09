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

 user_data = <<-EOF
#!/bin/bash
set -e

sudo dnf update -y
sudo dnf install -y python3 git

# Install pip using get-pip.py
curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
sudo python3 /tmp/get-pip.py

# Use the pip that get-pip.py just installed (usually /usr/local/bin/pip3)
if [ -x /usr/local/bin/pip3 ]; then
  PIP_BIN=/usr/local/bin/pip3
else
  PIP_BIN=$(command -v pip3 || echo "")
fi

if [ -z "$PIP_BIN" ]; then
  echo "pip3 not found after get-pip.py" > /home/ec2-user/ansible_setup.log
  exit 1
fi

sudo "$PIP_BIN" install --upgrade pip
sudo "$PIP_BIN" install ansible

# Ensure ansible is visible on default PATH
if [ -x /usr/local/bin/ansible-playbook ]; then
  sudo ln -sf /usr/local/bin/ansible-playbook /usr/bin/ansible-playbook
  sudo ln -sf /usr/local/bin/ansible /usr/bin/ansible
fi

echo "SETUP COMPLETE" > /home/ec2-user/ansible_setup.log
EOF


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