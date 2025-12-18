data "aws_route53_zone" "zone" {
  count        = var.enable_route53 ? 1 : 0
  name         = "${var.domain_name}."
  private_zone = false
}

# Health Checks
resource "aws_route53_health_check" "a" {
  count             = var.enable_route53 ? 1 : 0
  fqdn              = aws_lb.a.dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30

  tags = { Name = "${var.project}-health-a" }
}

resource "aws_route53_health_check" "b" {
  count             = var.enable_route53 ? 1 : 0
  fqdn              = aws_lb.b.dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30

  tags = { Name = "${var.project}-health-b" }
}

# Failover Routing
resource "aws_route53_record" "app_primary" {
  count          = var.enable_route53 ? 1 : 0
  zone_id        = data.aws_route53_zone.zone[0].zone_id
  name           = "app.${var.domain_name}"
  type           = "A"
  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = aws_lb.a.dns_name
    zone_id                = aws_lb.a.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.a[0].id
}

resource "aws_route53_record" "app_secondary" {
  count          = var.enable_route53 ? 1 : 0
  zone_id        = data.aws_route53_zone.zone[0].zone_id
  name           = "app.${var.domain_name}"
  type           = "A"
  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_lb.b.dns_name
    zone_id                = aws_lb.b.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.b[0].id
}

# Latency-based routing example (alternative)
resource "aws_route53_record" "app_latency_a" {
  count          = var.enable_route53 ? 1 : 0
  zone_id        = data.aws_route53_zone.zone[0].zone_id
  name           = "app-latency.${var.domain_name}"
  type           = "A"
  set_identifier = "region-a"

  latency_routing_policy {
    region = var.region_a
  }

  alias {
    name                   = aws_lb.a.dns_name
    zone_id                = aws_lb.a.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.a[0].id
}

resource "aws_route53_record" "app_latency_b" {
  count          = var.enable_route53 ? 1 : 0
  zone_id        = data.aws_route53_zone.zone[0].zone_id
  name           = "app-latency.${var.domain_name}"
  type           = "A"
  set_identifier = "region-b"

  latency_routing_policy {
    region = var.region_b
  }

  alias {
    name                   = aws_lb.b.dns_name
    zone_id                = aws_lb.b.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.b[0].id
}
