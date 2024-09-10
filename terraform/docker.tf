resource "aws_instance" "docker" {
  ami           = "ami-0182f373e66f89c85" # Ensure this AMI is valid in your region
  instance_type = "t2.xlarge"

  tags = {
    Name = "docker_server"
  }

  # Security group for Jenkins
  vpc_security_group_ids = [aws_security_group.docker_sg.id]

  # User data script to install Jenkins, Maven, Git, and Java
  user_data = <<-EOF
              #!/bin/bash
              set -e  # Exit on any error

              # Update and install Java (required for Jenkins)
              sudo yum update -y

              # Add Jenkins repo and install Jenkins
              yum install -y docker

              # Start Jenkins service
              sudo systemctl start docker
              sudo systemctl enable docker
              EOF
}

resource "aws_security_group" "docker_sg" {
  name        = "docker_sg"
  description = "Allow Jenkins inbound traffic and all outbound traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Be careful with this; it opens SSH to the entire internet.
  }
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Be careful; it opens the Jenkins port to the entire internet.
  }

  ingress {
    from_port   = 8081
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Be careful; it opens the Jenkins port to the entire internet.
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "jenkins_sg"
  }
}
