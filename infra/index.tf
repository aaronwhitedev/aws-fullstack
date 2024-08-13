data "archive_file" "index_arch" {
  type        = "zip"
  source_file = "${path.module}/lambdas/index.js"
  output_path = "${path.module}/lambdas/index.zip"
}

resource "aws_lambda_function" "index" {
  function_name    = "${var.project}_index"
  filename         = "lambdas/index.zip"
  runtime          = "nodejs18.x"
  handler          = "index.handler"
  timeout          = 10
  source_code_hash = data.archive_file.index_arch.output_base64sha256
  role             = aws_iam_role.index_iam_role.arn
  architectures    = ["arm64"]

  # environment {
  #   variables = {
  #     TO_index = var.to_index
  #     PROJECT  = var.project
  #   }
  # }
}

resource "aws_lambda_permission" "index_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.index.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "index_cwlg" {
  name              = "/aws/lambda/${aws_lambda_function.index.function_name}"
  retention_in_days = 1
}

resource "aws_iam_role" "index_iam_role" {
  name = "${var.project}_index"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Sid       = ""
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "index_policy" {
  name = "${var.project}_index_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid : "logs",
        Effect : "Allow",
        Action : [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource : "arn:aws:logs:*:*:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "index_perm" {
  policy_arn = aws_iam_policy.index_policy.arn
  role       = aws_iam_role.index_iam_role.name
}

resource "aws_apigatewayv2_integration" "index_int" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_uri    = aws_lambda_function.index.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "index_rte" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.index_int.id}"
}
