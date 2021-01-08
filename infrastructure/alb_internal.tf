resource "aws_alb" "internal_load_balancer" {
  name            = "int-load-balancer"
  internal        = true
  security_groups = [aws_security_group.security_group.id]
  subnets = [
    aws_subnet.vpc_public_subnet_a.id,
    aws_subnet.vpc_public_subnet_b.id
  ]
}

resource "aws_alb_listener" "internal_http" {
  load_balancer_arn = aws_alb.internal_load_balancer.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.internal_main.id
  }
}

resource "aws_alb_target_group" "internal_main" {
  name        = "int-main-target-group"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "internal_main" {
  target_group_arn = aws_alb_target_group.internal_main.arn
  target_id        = aws_lambda_function.main.arn
  depends_on       = [aws_lambda_permission.allow_alb_to_invoke_lambda]
}


resource "aws_alb_target_group" "fargate" {
  name        = "int-fargate-target-group"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
}


resource "aws_lb_listener_rule" "fargate" {
  listener_arn = aws_alb_listener.internal_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.fargate.arn
  }

  condition {
    path_pattern {
      values = ["/fargate/*", "/fargate"]
    }
  }
}
