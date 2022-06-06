module "vpc" {
  source          = "../modules/vpc/"
  project         = "WordPress"
  public_cidr     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidr    = ["10.0.11.0/24", "10.0.12.0/24"]
  admin_addresses = ["0.0.0.0/0"]
}
