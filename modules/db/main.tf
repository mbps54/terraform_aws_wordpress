resource "aws_db_subnet_group" "private" {
  name       = "private"
  subnet_ids = var.private_subnet_id
}

resource "aws_db_instance" "dbmysql" {
  storage_type             = "gp2"
  allocated_storage        = 20
  engine                   = "mysql"
  engine_version           = "5.7"
  instance_class           = "db.t2.micro"
  name                     = "dbmysql"
  username                 = var.username
  password                 = var.password
  parameter_group_name     = "default.mysql5.7"
  skip_final_snapshot      = true
  multi_az                 = true
  db_subnet_group_name     = aws_db_subnet_group.private.name
  backup_retention_period  = 1
  delete_automated_backups = true
  vpc_security_group_ids   = [aws_security_group.rds-sg.id]
}

resource "aws_security_group" "rds-sg" {
  name   = "rds-sg"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "inbound_rule" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.rds-sg.id
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["10.0.0.0/8"]
}

resource "aws_security_group_rule" "outbound_rule" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds-sg.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
