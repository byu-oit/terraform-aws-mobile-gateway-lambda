output "lambda_role" {
  value = aws_iam_role.iam_for_lambda
}

output "api_gateway" {
  value = aws_api_gateway_rest_api.api
}

output "lambda" {
  value = aws_lambda_function.lambda
}

output "api_methods" {
  value = aws_api_gateway_method.method
}

output "api_resources" {
  value = aws_api_gateway_resource.resource
}