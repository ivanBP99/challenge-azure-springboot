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
# DATA
#############################################################################

#data "aws_ecr_repository" "this" {
#  name = var.ecr_repository
#}

#data "aws_ecr_image" "this" {
#  repository_name  = data.aws_ecr_repository.this.name
#  image_id         = data.aws_ecr_image_version.this.image_id
#}

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

resource "aws_security_group" "security_group" {
  name = "ecs-security-group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 0
    protocol = -1
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "any"
  }
  egress {
    from_port = 0
    protocol = -1
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "any"
  }
}

resource "aws_ecs_cluster" "this" {
  name = "app-cluster-challenge"
}

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
            containerPort: 8080,
            hostPort: 8080,
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
  task_definition  = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [ aws_subnet.subnet.id, aws_subnet.subnet2.id ]
    security_groups = [aws_security_group.security_group.id]
    //assign_public_ip = true
  }
}