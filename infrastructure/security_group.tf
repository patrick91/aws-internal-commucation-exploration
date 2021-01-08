resource "aws_security_group" "security_group" {
  name   = "security-group"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "ingress_rule_http" {
  type              = "ingress"
  description       = "HTTP"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "ingress_rule_https" {
  type              = "ingress"
  description       = "HTTPS"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "egress_rule" {
  security_group_id = aws_security_group.security_group.id
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
