module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = "eks-vpc"
  cidr    = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  enable_nat_gateway = true
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets
  security_groups  = [aws_security_group.nlb_sg.id]
}
# Creating 2 target groups for 2 services
resource "aws_lb_target_group" "test1" {
  name     = "tf-example-lb-tg-nginx"
  port     = 30080
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_target_group" "test2" {
  name     = "tf-example-lb-tg-apache"
  port     = 30081
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}
# Attach instances to Target Groups (uncomment when nodes is created)
#resource "aws_lb_target_group_attachment" "nginx_group" {
#  for_each = toset(var.instances)
#  target_group_arn = aws_lb_target_group.test1.arn
#  target_id        = each.value
#  port             = 30080
#}

#resource "aws_lb_target_group_attachment" "apache_group" {
#  for_each = toset(var.instances)
#  target_group_arn = aws_lb_target_group.test2.arn
#  target_id        = each.value
#  port             = 30081
#}
# Listeners for Load balancer ports
resource "aws_lb_listener" "nginx" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "TCP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test1.arn
  }
}

resource "aws_lb_listener" "apache" {
  load_balancer_arn = aws_lb.test.arn
  port              = "81"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test2.arn
  }
}

# This security group will allowe traffic for nodes ports that have applications
resource "aws_security_group" "worker_sg" {
  name        = "k8s-worker-sg"
  vpc_id      =  module.vpc.vpc_id

  ingress {
    from_port        = 30000
    to_port          = 31000
    protocol         = "tcp"
    security_groups  = [aws_security_group.nlb_sg.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
# Full access to Network Load Balancer from internet
resource "aws_security_group" "nlb_sg" {
  name        = "nlb-sg"
  vpc_id      =  module.vpc.vpc_id

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


output "vpc"{
  value = module.vpc.vpc_id
}
output "sub"{
  value = module.vpc.private_subnets
}
output "worker_sg"{
  value = aws_security_group.worker_sg.id
}
