resource "aws_lb_target_group" "target-group-1" {
  health_check {
    interval            = 120
    path                = "/"
    protocol            = "HTTP"
    timeout             = 100
    healthy_threshold   = 5
    unhealthy_threshold = 3
  }

  name        = "${var.project}-target-group-1"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
}

resource "aws_lb" "alb-1" {
  name     = "${var.project}-alb-1"
  internal = false

  security_groups = [
    aws_security_group.sg2.id,
  ]

  subnets = var.subnet_id

  tags = {
    Name = "${var.project}-alb-1"
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

resource "aws_lb_listener" "alb-listner-1" {
  load_balancer_arn = aws_lb.alb-1.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group-1.arn
  }
}

resource "aws_security_group" "sg2" {
  name   = "sg2"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.sg2.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.sg2.id
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_https" {
  from_port         = 433
  protocol          = "tcp"
  security_group_id = aws_security_group.sg2.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.sg2.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_acm_certificate" "default" {
  domain_name       = "tasucu.click"
  validation_method = "DNS"
}

data "aws_route53_zone" "external" {
  name = "tasucu.click"
}

resource "aws_route53_record" "validation" {
  allow_overwrite = true
  name    = tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_type
  zone_id = data.aws_route53_zone.external.zone_id
  records = [ tolist(aws_acm_certificate.default.domain_validation_options)[0].resource_record_value ]
  ttl     = "60"
}

resource "aws_acm_certificate_validation" "default" {
  certificate_arn = "${aws_acm_certificate.default.arn}"

  validation_record_fqdns = [
    "${aws_route53_record.validation.fqdn}",
  ]
}

resource "aws_route53_record" "record-1" {
  zone_id = "Z0864870176T1RW93BUL9"
  name    = "tasucu.click"
  type    = "A"

  alias {
    name                   = aws_lb.alb-1.dns_name
    zone_id                = aws_lb.alb-1.zone_id
    evaluate_target_health = true
  }
}

#for HTTPS
resource "aws_lb_listener" "alb-listner-2" {
  load_balancer_arn = aws_lb.alb-1.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = "${aws_acm_certificate.default.arn}"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group-1.arn
  }
}
