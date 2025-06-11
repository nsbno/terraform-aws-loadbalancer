locals {
  name = "${var.name_prefix}-${var.type == "network" ? "nlb" : "alb"}"
}

/*
 * == Security Groups
 */
resource "aws_security_group" "this" {
  count  = var.type == "application" ? 1 : 0
  name   = local.name
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      "Name" = local.name
    },
  )
  lifecycle {
    # To avoid recreation issues, we ignore changes to the name and description.
    ignore_changes = [name, description]
  }
}

/*
 * == Main Loadbalancer
 *
 * Sets up the loadbalancer itself.
 */
resource "aws_lb" "main" {
  name               = local.name
  load_balancer_type = var.type
  internal           = var.internal
  subnets            = var.subnet_ids
  security_groups    = aws_security_group.this.*.id
  idle_timeout       = var.idle_timeout

  access_logs {
    bucket  = lookup(var.access_logs, "bucket", "")
    prefix  = lookup(var.access_logs, "prefix", null)
    enabled = lookup(var.access_logs, "enabled", false)
  }

  tags = merge(
    var.tags,
    {
      "Name" = local.name
    },
  )
  lifecycle {
    ignore_changes = [
      # To avoid recreation issues with the name changing, we ignore changes to the name.
      name
    ]
  }
}

/*
 * == HTTP(S) Listeners
 *
 * Redirect HTTP to HTTPS, and tell users when they're lost (404).
 */
locals {
  main_certificate = var.certificate_arns[0]
  extra_certificates = (
    length(var.certificate_arns) > 1
    ? slice(var.certificate_arns, 1, length(var.certificate_arns))
    : []
  )
}

/*
 * === HTTPS
 */
resource "aws_lb_listener" "https" {
  count = var.type == "application" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = local.main_certificate
  ssl_policy        = var.ssl_policy

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Unknown Service"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_certificate" "extra" {
  for_each = { for idx, cert in local.extra_certificates : idx => cert }

  listener_arn    = aws_lb_listener.https[0].arn
  certificate_arn = each.value
}

resource "aws_security_group_rule" "allow_https" {
  security_group_id = aws_security_group.this[0].id
  type              = "ingress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

/*
 * === HTTPS Testing
 */
resource "aws_lb_listener" "https_test" {
  count = var.type == "application" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "8443"
  protocol          = "HTTPS"
  certificate_arn   = local.main_certificate
  ssl_policy        = var.ssl_policy

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Unknown Service"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_certificate" "test_extra" {
  for_each = { for idx, cert in local.extra_certificates : idx => cert }

  listener_arn    = aws_lb_listener.https_test[0].arn
  certificate_arn = each.value
}

resource "aws_security_group_rule" "allow_https_test" {
  security_group_id = aws_security_group.this[0].id
  type              = "ingress"
  from_port         = "8443"
  to_port           = "8443"
  protocol          = "tcp"

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

/*
 * === HTTP
 */
resource "aws_lb_listener" "http" {
  count = var.type == "application" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_security_group_rule" "allow_http" {
  security_group_id = aws_security_group.this[0].id
  type              = "ingress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
