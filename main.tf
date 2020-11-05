terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  access_key = var.iam_manager_access_key
  secret_key = var.iam_manager_secret_key
}

# Creating an IAM user for the tour. We'll eventually need
# to create one of these per tour workspace, but that comes later.
resource "aws_iam_user" "tfc_tour_taker" {
  name = "tfc_tour_taker"
}

# Generate non-temporary credentials for the IAM user.
# These will be kept secret and only used to generate
# time-limited credentials (per run, eventually).
resource "aws_iam_access_key" "tfc_tour_taker" {
  user = aws_iam_user.tfc_tour_taker.name
}

# All this user should be able to do is create, delete, and manage
# stuff in an S3 bucket with one very specific name.
resource "aws_iam_user_policy" "tfc_tour_taker" {
  name = "bucket-only"
  user = aws_iam_user.tfc_tour_taker.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}",
        "arn:aws:s3:::${var.bucket_name}/*"
      ]
    },
    {
      "Effect": "Deny",
      "NotAction": ["s3:*"],
      "NotResource": [
        "arn:aws:s3:::${var.bucket_name}",
        "arn:aws:s3:::${var.bucket_name}/*"
      ]
    }
  ]
}
EOF
}

# Generating temporary credentials for our bucket-limited user
# isn't something Terraform can do, so calling the aws cli.
resource "null_resource" "sts_request" {
  triggers = {
    change_this_when_you_want_new_credentials = "yes please"
  }

  provisioner "local-exec" {
    environment = {
      AWS_ACCESS_KEY_ID = aws_iam_access_key.tfc_tour_taker.id
      AWS_SECRET_ACCESS_KEY = aws_iam_access_key.tfc_tour_taker.secret
    }

    command = <<EOF
RESPONSE=$(aws sts get-session-token --duration-seconds=${var.ttl})
echo "Temporary access key id: $(jq '.Credentials.AccessKeyId' <<< $RESPONSE)"
echo "Temporary secret key: $(jq '.Credentials.SecretAccessKey' <<< $RESPONSE)"
echo "Temporary session token: $(jq '.Credentials.SessionToken' <<< $RESPONSE)"
EOF
  }
}
