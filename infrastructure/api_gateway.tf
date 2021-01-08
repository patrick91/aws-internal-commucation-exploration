data "aws_vpc_endpoint_service" "main" {
  service = "execute-api"
}

resource "aws_vpc_endpoint" "main" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = data.aws_vpc_endpoint_service.main.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = [aws_subnet.vpc_public_subnet_a.id, aws_subnet.vpc_public_subnet_b.id]
  security_group_ids = [aws_security_group.security_group.id]
}

data "aws_iam_policy_document" "private_api_policy_document" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["*"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpc"
      values   = [aws_vpc.vpc.id]
    }
  }
}

resource "aws_api_gateway_rest_api" "main" {
  name = "Private-API"

  policy = data.aws_iam_policy_document.private_api_policy_document.json

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.main.id]
  }
}


resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}


resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = "dev"
}

resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.main.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

output "api-url" {
  value = "https://${aws_api_gateway_rest_api.main.id}-${aws_vpc_endpoint.main.id}.execute-api.us-east-1.amazonaws.com/dev"
}
