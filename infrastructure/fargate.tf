resource "aws_ecs_cluster" "main" {
  name = "main-cluster"
}

resource "aws_ecs_task_definition" "main" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
    name      = "main-container"
    image     = "nginxdemos/hello:latest"
    essential = true
    portMappings = [{
      protocol      = "tcp"
      containerPort = 80
      hostPort      = 80
  }] }])

}

resource "aws_iam_role" "ecs_task_role" {
  name = "main-ecsTaskRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "main-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "main" {
  name                               = "main-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups = [aws_security_group.security_group.id]
    subnets = [
      aws_subnet.vpc_public_subnet_a.id,
      aws_subnet.vpc_public_subnet_b.id
    ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.fargate.arn
    container_name   = "main-container"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}


# resource "aws_lb_target_group_attachment" "fargate" {
#   target_group_arn =
#   target_id        = aws_lambda_function.fargate.arn
#   depends_on       = [aws_lambda_permission.allow_alb_to_invoke_lambda]
# }
