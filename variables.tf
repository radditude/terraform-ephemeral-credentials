variable "bucket_name" {
  description = "Name of the s3 bucket our limited user will be able to create and manage. Must be globally unique."
  type = string
}

variable "iam_manager_access_key" {
  description = "Access key id for an AWS user with permissions to create and delete IAM users"
  type = string
}

variable "iam_manager_secret_key" {
  description = "Secret key for an AWS user with permissions to create and delete IAM users"
  type = string
}

variable "ttl" {
  description = "How long the temporary credentials should be valid for, in seconds"
  type = number
  # 15 minutes
  default = 900
}
