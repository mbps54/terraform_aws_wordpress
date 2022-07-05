## WordPress App for a customer web site

### Description
Terraform allows to provision full infrastructure for WordPress web site.
## level 0 (terraform, DB dump)
- S3 bucket for Terraform remote state
- DynamoDB database for Terraform remote state locking
- S3 bucket for MySQL database dump reserve copy

## level 1 (network infrastructure):
- VPC
- Subnets
- Routes
- Inbternet gateway
- NAT gateways

## level 2 (wordpress):
- SecretManager
- SecurityGroups
- MySQL database
- Bastion host
- ASG and Launch template
- Certificate Manager
- ELB
- Route53

### Release notes
In version 1.1.1 public modules are used.

### This git direcory contains:
1. Terraform HCL manifests for AWS
2. Userdata with bash script for ec2 instances
3. Network diagram
4. Security diagram

### Usage options:
1. Terraform apply from level0 directory
2. Terraform apply from level1 directory
3. Terraform apply from level2 directory
```
cd level0
terraform apply
cd ../level1
terraform apply
cd ../level2
terraform apply
```
