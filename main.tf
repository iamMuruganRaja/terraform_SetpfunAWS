# Configure the AWS provider with variables for access key and secret key
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "ap-south-1" # Specify your desired AWS region here
}

# Define the IAM role for Step Functions
resource "aws_iam_role" "step_function_role" {
  name               = "step-function-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Define the Step Functions state machine
resource "aws_sfn_state_machine" "my_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "A description of my state machine",
    StartAt = "Choice",
    States = {
      Choice = {
        Type = "Choice",
        Choices = [
          {
            Variable     = "$.type",
            StringEquals = "PURCHASE",
            Next         = "PurchaseHandler"
          },
          {
            Variable     = "$.type",
            StringEquals = "REFUND",
            Next         = "RefundHandler"
          }
        ]
      },                                                                                                                                                                                                                                   
      PurchaseHandler = {
        Type       = "Task",
        Resource   = "arn:aws:states:::lambda:invoke",
        OutputPath = "$.Payload",
        Parameters = {
          "Payload.$"    = "$",
          FunctionName   = "arn:aws:lambda:ap-south-1:236835462847:function:Purchasehandler:$LATEST"
        },
        Retry = [
          {
            ErrorEquals    = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "Lambda.TooManyRequestsException"],
            IntervalSeconds= 1,
            MaxAttempts    = 3,
            BackoffRate    = 2
          }
        ],
        Next       = "ResultHandler"
      },
      ResultHandler = {
        Type       = "Task",
        Resource   = "arn:aws:states:::lambda:invoke",
        OutputPath = "$.Payload",
        Parameters = {
          "Payload.$"    = "$",
          FunctionName   = "arn:aws:lambda:ap-south-1:236835462847:function:ResultHandler:$LATEST"
        },
        Retry = [
          {
            ErrorEquals    = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "Lambda.TooManyRequestsException"],
            IntervalSeconds= 1,
            MaxAttempts    = 3,
            BackoffRate    = 2
          }
        ],
        End = true
      },
      RefundHandler = {
        Type       = "Task",
        Resource   = "arn:aws:states:::lambda:invoke",
        OutputPath = "$.Payload",
        Parameters = {
          "Payload.$"    = "$",
          FunctionName   = "arn:aws:lambda:ap-south-1:236835462847:function:refundhandler:$LATEST"
        },
        Retry = [
          {
            ErrorEquals    = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "Lambda.TooManyRequestsException"],
            IntervalSeconds= 1,
            MaxAttempts    = 3,
            BackoffRate    = 2
          }
        ],
        Next   