output "DB_secret_password" {
  value = local.db_creds
  sensitive = true
}