output "api" {
  value = aws_api_gateway_rest_api.api
}

output "lambda" {
  value = aws_lambda_function.lambda
}