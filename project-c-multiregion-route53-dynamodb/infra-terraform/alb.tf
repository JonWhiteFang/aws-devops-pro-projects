# Security Groups
resource "aws_security_group" "alb_a" {
  provider    = aws.a
  name        = "${var.project}-alb-sg"
  vpc_id      = aws_vpc.a.id
  description = "ALB security group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_b" {
  provider    = aws.b
  name        = "${var.project}-alb-sg"
  vpc_id      = aws_vpc.b.id
  description = "ALB security group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB Region A
resource "aws_lb" "a" {
  provider           = aws.a
  name               = "${var.project}-alb-a"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_a.id]
  subnets            = [aws_subnet.a_public_1.id, aws_subnet.a_public_2.id]
}

resource "aws_lb_target_group" "a" {
  provider    = aws.a
  name        = "${var.project}-tg-a"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "a" {
  provider         = aws.a
  target_group_arn = aws_lb_target_group.a.arn
  target_id        = aws_lambda_function.a.arn
  depends_on       = [aws_lambda_permission.a]
}

resource "aws_lb_listener" "a" {
  provider          = aws.a
  load_balancer_arn = aws_lb.a.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.a.arn
  }
}

# ALB Region B
resource "aws_lb" "b" {
  provider           = aws.b
  name               = "${var.project}-alb-b"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_b.id]
  subnets            = [aws_subnet.b_public_1.id, aws_subnet.b_public_2.id]
}

resource "aws_lb_target_group" "b" {
  provider    = aws.b
  name        = "${var.project}-tg-b"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "b" {
  provider         = aws.b
  target_group_arn = aws_lb_target_group.b.arn
  target_id        = aws_lambda_function.b.arn
  depends_on       = [aws_lambda_permission.b]
}

resource "aws_lb_listener" "b" {
  provider          = aws.b
  load_balancer_arn = aws_lb.b.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.b.arn
  }
}
