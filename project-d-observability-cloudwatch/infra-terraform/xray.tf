# X-Ray Sampling Rule
resource "aws_xray_sampling_rule" "main" {
  rule_name      = "demo-app"
  priority       = 1000
  version        = 1
  reservoir_size = 5
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"
}

# X-Ray Group for filtering traces
resource "aws_xray_group" "errors" {
  group_name        = "errors"
  filter_expression = "responsetime > 2 OR error = true"
}

resource "aws_xray_group" "slow_requests" {
  group_name        = "slow-requests"
  filter_expression = "responsetime > 1"
}
