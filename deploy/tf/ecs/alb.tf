resource "aws_lb_target_group" "app" {
  name        = "sample-django-app"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.params.vpc_id

  health_check {
    enabled = true
    path    = "/health"
  }
}

resource "aws_route53_record" "app" {
  for_each = toset(var.app_hostnames)
  zone_id  = local.params.dns_zone_id
  name     = each.value
  type     = "A"

  alias {
    name                   = local.params.alb_dns_name
    zone_id                = local.params.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_listener_rule" "app_fgate" {
  for_each     = toset(var.app_hostnames)
  listener_arn = local.params.alb_https_listener

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    host_header {
      values = [aws_route53_record.app[each.value].fqdn]
    }
  }
}
