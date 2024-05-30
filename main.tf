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

resource "aws_ecs_cluster" "this" {
  name = "app-cluster-challenge"
}

resource "aws_ecs_task_definition" "this" {
  family = "app-task"
  container_definitions = jsonencode([
    [
      {
        "name": "app",
        "imageUri": "${aws_ecr_repository.example.repository_url}:0.0.1-SNAPSHOT",
        "portMappings": [
          {
            "containerPort": 8080,
            "hostPort": 8080
          }
        ]
      }
    ]])
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