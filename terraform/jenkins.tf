resource "aws_instance" "jenkins" {
  ami           = "ami-0182f373e66f89c85" # Ensure this AMI is valid in your region
  instance_type = "t2.xlarge"

  tags = {
    Name = "jenkins_server"
  }

  # Security group for Jenkins
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  # User data script to install Jenkins, Maven, Git, and Java
  user_data = <<-EOF
              #!/bin/bash
              set -e  # Exit on any error

              # Update and install Java (required for Jenkins)
              sudo yum update -y

              # Add Jenkins repo and install Jenkins
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              sudo yum install -y java-11-amazon-corretto
              sudo yum install -y jenkins
              sudo yum install -y git

              # Install Maven manually to /opt/maven
              MAVEN_VERSION=3.9.5
              wget https://dlcdn.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
              sudo tar -xvzf apache-maven-$MAVEN_VERSION-bin.tar.gz -C /opt
              sudo ln -s /opt/apache-maven-$MAVEN_VERSION /opt/maven

              # Set up Maven environment variables
              echo "export M2_HOME=/opt/maven" | sudo tee /etc/profile.d/maven.sh
              echo "export PATH=\$M2_HOME/bin:\$PATH" | sudo tee -a /etc/profile.d/maven.sh

              # Apply environment variables for the current session
              source /etc/profile.d/maven.sh

              # Start Jenkins service
              sudo systemctl start jenkins
              sudo systemctl enable jenkins

              # Verify Maven installation
              mvn -version
              EOF
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
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
