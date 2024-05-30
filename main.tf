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
  cidr_block = "cidrsubnet(aws_vpc.main.cidr_block,8,1)"
  map_public_ip_on_launch = true
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "subnet2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "cidrsubnet(aws_vpc.main.cidr_block,8,2)"
  map_public_ip_on_launch = true
  availability_zone = "us-east-2b"
}

resource "aws_ecs_cluster" "this" {
  name = "app-cluster-challenge"
}

resource "aws_ecs_task_definition" "this" {
  family = "app-task"
  container_definitions = jsonencode([
      {
        "name": "app",
        "imageUri": "public.ecr.aws/f9n5f1l7/dgs:latest",
        "portMappings": [
          {
            "containerPort": 8080,
            "hostPort": 8080
          }
        ]
      }
    ])
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu          = "256"
  memory       = "512"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

resource "aws_ecr_repository" "example" {
  name = "hansel"
}

resource "aws_ecs_service" "this" {
  name            = "app-challenge-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [ "subnet-123456", "subnet-789012" ]
    assign_public_ip = true
  }
}