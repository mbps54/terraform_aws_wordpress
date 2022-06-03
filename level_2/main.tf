data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "creds"
}


locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)
}