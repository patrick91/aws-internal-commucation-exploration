resource "aws_alb" "external_load_balancer" {
  name            = "load-balancer"
  internal        = false
  security_groups = [aws_security_group.security_group.id]
  subnets = [
    aws_subnet.vpc_public_subnet_a.id,
    aws_subnet.vpc_public_subnet_b.id
  ]
}

resource "aws_alb_listener" "http_external" {
  load_balancer_arn = aws_alb.external_load_balancer.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.main.id
  }
}

resource "aws_alb_target_group" "main" {
  name        = "p-main-target-group"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_alb_target_group.main.arn
  target_id        = aws_lambda_function.main.arn
  depends_on       = [aws_lambda_permission.allow_alb_to_invoke_lambda]
}

output "load_balancer_dns" {
  value = aws_alb.external_load_balancer.dns_name
}
