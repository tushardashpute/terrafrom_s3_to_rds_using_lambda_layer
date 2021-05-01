provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "C:\\Users\\tdashpute\\.aws\\credentials"
  #profile                 = "customprofile"
}

variable "function_name" {
    default = ""
}
variable "handler_name" {
    default = ""
}
variable "runtime" {
    default = ""
 }
variable "timeout" {
   default = ""
}

variable "s3BucketName" {
   default = ""
}

## IAM ROLE CREATION

resource "aws_iam_role" "lambda_ec2_role" {
  name = "lambda_ec2_role"

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

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "cwl_policy" {
  name = "cwl_policy"
  role = aws_iam_role.lambda_ec2_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Action": [
        "cloudwatch:*",
        "ec2:*",
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

##################
# Creating s3 resource for invoking to lambda function
##################
resource "aws_s3_bucket" "bucket" {
  bucket = "tusharbucket12345"
  acl    = "private"
  tags = {
    Name   = "My bucket"
  }
}

##################
# Adding S3 bucket as trigger to my lambda and giving the permissions
##################
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.bucket.id
  lambda_function {
  lambda_function_arn = aws_lambda_function.readS3ToRDS.arn
  events              = ["s3:ObjectCreated:*"]
  filter_prefix       = "csvdata/"
  filter_suffix       = "csv"
  }
}
resource "aws_lambda_permission" "test" {
statement_id  = "AllowS3Invoke"
action        = "lambda:InvokeFunction"
function_name = aws_lambda_function.readS3ToRDS.function_name
principal = "s3.amazonaws.com"
source_arn = "arn:aws:s3:::${aws_s3_bucket.bucket.id}"
}



data "archive_file" "readS3ToRDS" {
  type        = "zip"
  source_dir = "readS3ToRDS/"
  output_path = "readS3ToRDS.zip"
}

resource "aws_s3_bucket_object" "object" {

  bucket = "tusharbucket12345"
  key    = "readS3ToRDS.zip"
  acl    = "private"  # or can be "public-read"
  source = data.archive_file.readS3ToRDS.output_path
  etag = filemd5("readS3ToRDS.zip")

}

resource "aws_lambda_function" "readS3ToRDS" {
  
  function_name = "readS3ToRDS"
  s3_bucket     =  aws_s3_bucket.bucket.id
  s3_key        = "readS3ToRDS.zip"
  role          = aws_iam_role.lambda_ec2_role.arn
  handler       = "readS3ToRDS.lambda_handler"
  runtime       = "python3.6"
  layers        = [aws_lambda_layer_version.lambda_layer.arn]
}

##################
# Create Lambda Layer to impport mysql.connector
# Use the below format to create the lambda layer
# Create folder "python/lib/python3.8/site-packages"
# mkdir -p python/lib/python3.8/site-packages
# Install mysql-connector module using "pip"
# pip install mysql-connector-python -t python/lib/python3.8/site-packages
# create a zip of python folder and upload it
##################

resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = "python.zip"
  layer_name = "mysql_lambda_layer"

  compatible_runtimes = ["python3.6","python3.7"]
}

