//TODO: maybe move to single repo using github pages
module "acs" {
  source = "github.com/byu-oit/terraform-aws-acs-info.git?ref=v1.1.0"
  env = var.env
  vpc_vpn_to_campus = true
}

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.app-name}-api"
}

resource "aws_api_gateway_deployment" "stage" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = var.env
  stage_description = md5(file(var.swagger-path))
}

# Create only if root-resource is not empty
resource "aws_api_gateway_method" "root_method" {
  count = var.root-resource == true ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = var.root-resource-method
  authorization = var.root-resource-authorization
  request_parameters = var.root-resource-request-params

}

resource "aws_api_gateway_integration" "root_method_integration" {
  count = var.root-resource == true ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_rest_api.api.root_resource_id
  http_method = var.root-resource-method
  integration_http_method = var.root-resource-method
  type = "AWS_PROXY"
  uri = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_resource" "resource" {
  count = length(var.method-paths)
  path_part = var.method-paths[count.index]
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  count = length(var.method-paths)
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[count.index].id
  http_method = var.method-types[count.index]
  authorization = var.resource-authorization
  request_parameters = var.resource-request-params
}

resource "aws_api_gateway_integration" "integration" {
  count = length(var.method-paths)
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource[count.index].id
  http_method = aws_api_gateway_method.method[count.index].http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = aws_api_gateway_rest_api.api.execution_arn
}

resource "aws_api_gateway_domain_name" "api_domain" {
  domain_name = "${var.dns-name}.${substr(module.acs.route53_zone.name, 0, length(module.acs.route53_zone.name)-1)}"
  regional_certificate_arn = module.acs.certificate.arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "path_mapping" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_deployment.stage.stage_name
  domain_name = aws_api_gateway_domain_name.api_domain.domain_name
}

resource "aws_route53_record" "a_record" {
  name = aws_api_gateway_domain_name.api_domain.domain_name
  type = "A"
  zone_id = module.acs.route53_zone.zone_id

  alias {
    evaluate_target_health = false
    name = aws_api_gateway_domain_name.api_domain.regional_domain_name
    zone_id = aws_api_gateway_domain_name.api_domain.regional_zone_id
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.app-name}-lambda"
  permissions_boundary = "arn:aws:iam::${var.account-id}:policy/iamRolePermissionBoundary"
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

resource aws_iam_policy "ec2-network-interface-policy" {
  name = "${var.app-name}-ec2"
  description = "A policy to allow create, describe, and delete network interfaces"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2-network-interface-policy-attachment" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.ec2-network-interface-policy.arn
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
    cidr_blocks = [
      "0.0.0.0/0"
    ]
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
    security_group_ids = [
      aws_security_group.vpc_sec.id]
    subnet_ids = module.acs.private_subnet_ids
  }
  environment {
    variables = var.lambda-environment-variables
  }
}
