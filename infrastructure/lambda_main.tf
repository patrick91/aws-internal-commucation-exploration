# configuration for the lambda that runs the benchmark and acts as entry point

module "dependencies" {
  source            = "github.com/atistler/terraform-aws-lambda-layer-build.git"
  layer_name        = "lambda-dependencies"
  package_lock_file = "${path.cwd}/../app/poetry.lock"
  package_manager   = "poetry"
  runtime           = "python3.8"
}


resource "aws_iam_role" "app_role" {
  name = "lambda-main-app-role"

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

resource "aws_iam_role_policy" "app_role_policy" {
  role = aws_iam_role.app_role.id
  name = "lambda-main-app-role-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}


resource "aws_lambda_function" "main" {
  function_name    = "main"
  role             = aws_iam_role.app_role.arn
  handler          = "app.handler"
  runtime          = "python3.8"
  timeout          = 30
  memory_size      = 1024
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  layers = [
    module.dependencies.layer_arn
  ]

  vpc_config {
    subnet_ids = [
      aws_subnet.vpc_public_subnet_a.id,
      aws_subnet.vpc_public_subnet_b.id
    ]
    security_group_ids = [aws_security_group.security_group.id]
  }
}

data "archive_file" "lambda_zip" {
  type = "zip"
  source {
    content  = file("../app/app.py")
    filename = "app.py"
  }

  output_path = "lambda.zip"
}

resource "aws_lambda_alias" "main" {
  name             = "main"
  description      = ""
  function_name    = aws_lambda_function.main.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_permission" "allow_alb_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_alb_target_group.main.arn
}

resource "aws_lambda_permission" "allow_alb_to_invoke_lambda_internal" {
  statement_id  = "AllowExecutionFromALBInternal"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_alb_target_group.internal_main.arn
}
