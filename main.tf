#############################################################################
# TERRAFORM CONFIG
#############################################################################

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0.0"
    }
  }
}

#############################################################################
# VARIABLES
#############################################################################

variable "location" {
  type = string
  default = "us-east-2"
}

variable "ecr_repository" {
  type = string
  default = "hansel"
}

variable "image_tag" {
  type = string
  default = "0.0.1-SNAPSHOT"
}

variable "vpc_cidr" {
  description = "CIDR block for main"
  type = string
  default = "10.0.0.0/16"
}
#############################################################################
# PROVIDERS
#############################################################################

provider "aws" {
  region = var.location
  #features {}
}

#############################################################################
# RESOURCES
#############################################################################

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    name = "main"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  map_public_ip_on_launch = true
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "subnet2" {
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
  map_public_ip_on_launch = true
  availability_zone = "us-east-2b"
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    name = "internet_gateway"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "subnet_route" {
  subnet_id = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet2_route" {
  subnet_id = aws_subnet.subnet2.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "lb_sg" {
  name = "ecs-security-group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "any"
  }
  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "any"
  }
}

//abl

resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.subnet.id, aws_subnet.subnet2.id]
  tags               = {
    Environment = "dev"
  }
}

resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn  = aws_lb.ecs_alb.arn
  port               = 80
  protocol           = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "lb-target-group1"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path = "/"
  }
}

//cluster

resource "aws_ecs_cluster" "this" {
  name = "app-cluster-challenge"
}

//auto-scaling

#resource "aws_autoscaling_group" "autoscaling_group" {
#  vpc_zone_identifier = [aws_subnet.subnet.id, aws_subnet.subnet2.id]
#  desired_capacity = 2
#  max_size = 3
#  min_size = 1

#  launch_template {
#    id = aws_launch
#  }
#}

#resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
#  name = "test1"
#  auto_scaling_group_provider {
#    auto_scaling_group_arn = ""
#  }
#}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family       = "app-task"
  network_mode = "awsvpc"
  cpu          = "256"
  memory       = "512"
  execution_role_arn = "arn:aws:iam::211125585534:role/ecsTaskExecutionRole"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  container_definitions = jsonencode([
      {
        name: "container-app",
        image: "public.ecr.aws/f9n5f1l7/dgs:latest",
        portMappings: [
          {
            containerPort: 80,
            hostPort: 80,
            protocol: "tcp"
          }
        ]
      }
    ])
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "container-app"
    container_port   = 80
  }

  network_configuration {
    subnets         = [ aws_subnet.subnet.id, aws_subnet.subnet2.id ]
    security_groups = [aws_security_group.lb_sg.id]
    //assign_public_ip = true
  }
}

#############################################################################
# OUTPUT
#############################################################################

#output "" {
#  value = ""
#}