resource "aws_instance" "web" {
  ami           = "ami-0becc523130ac9d5d"
  instance_type = "t3.micro"
  tags = {
    Name = "HelloWorld"
  }
}


resource "aws_eip" "lb" {
  instance = aws_instance.web.id
  domain   = "vpc"
}
