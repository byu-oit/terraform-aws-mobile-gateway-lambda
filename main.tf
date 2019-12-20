//TODO: maybe move to single repo using github pages
module "acs" {
  source = "git@github.com:byu-oit/terraform-aws-acs-info.git?ref=v1.0.4"
  env = var.env
  vpc_vpn_to_campus = true
}

resource "aws_elb" "elb" {
  name               = "${var.app-name}-elb"
  availability_zones = ["us-west-2a", "us-west2b"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 443
    instance_protocol = "https"
    lb_port           = 443
    lb_protocol       = "https"
    ssl_certificate_id = module.acs.certificate
  }
}

resource "aws_route53_record" "www" {
  zone_id = module.acs.route53_zone
  name    = var.dns-name
  type    = "A"

  alias {
    name                   = "${aws_elb.elb.dns_name}"
    zone_id                = "${aws_elb.elb.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = module.acs.route53_zone
  name    = var.dns-name
  type    = "AAAA"

  alias {
    name                   = "${aws_elb.elb.dns_name}"
    zone_id                = "${aws_elb.elb.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = var.app-name
  description = var.api-description
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_security_group" "vpc_sec" {
  name = "${var.app-name}-sg"
  description = "${var.app-name}-sg"
  vpc_id = module.acs.vpc.id

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_lambda_function "lambda" {
  function_name = var.app-name
  filename = var.path-to-jar
  memory_size = var.memory
  description = var.lambda-description
  role = aws_iam_role.iam_for_lambda.arn
  handler = var.handler
  runtime = var.runtime
  timeout = var.timeout
  vpc_config {
    security_group_ids = ["${aws_security_group.vpc_sec.id}"]
    subnet_ids = module.acs.private_subnets
  }
}
