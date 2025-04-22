# ---
# RDS
# ---
### parameter group
resource "aws_db_parameter_group" "rds_parametergp" {
  name   = "${var.project}-${var.environment}-rds-parametergp"
  family = "mysql8.0"

  tags = {
    Name    = "${var.project}-${var.environment}-rds-parametergp"
    Project = var.project
    Env     = var.environment
  }
}

### option group
resource "aws_db_option_group" "rds_optiongp" {
  name                 = "${var.project}-${var.environment}-rds-optiongp"
  engine_name          = "mysql"
  major_engine_version = "8.0"

  tags = {
    Name    = "${var.project}-${var.environment}-rds-optiongp"
    Project = var.project
    Env     = var.environment
  }
}

### subnet group
resource "aws_db_subnet_group" "rds_subnetgp" {
  name = "${var.project}-${var.environment}-rds-subnetgp"
  subnet_ids = [
    var.private_subnet_1a,
    var.private_subnet_1c
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-rds-subnetgp"
    Project = var.project
    Env     = var.environment
  }
}

### rds instance
resource "aws_db_instance" "rds_instance" {
  engine         = "mysql"
  engine_version = "8.0.40"
  identifier     = "${var.project}-${var.environment}-rds-instance"
  username       = var.rds_username
  password       = random_string.db_userpass.result
  instance_class = var.rds_instance_class

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp2"
  storage_encrypted     = false

  multi_az = true
  db_subnet_group_name   = aws_db_subnet_group.rds_subnetgp.name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false
  port                   = 3306

  name                 = var.rds_db_name
  parameter_group_name = aws_db_parameter_group.rds_parametergp.name
  option_group_name    = aws_db_option_group.rds_optiongp.name

  backup_window              = "03:00-04:00"
  backup_retention_period    = 0
  maintenance_window         = "Mon:01:00-Mon:03:00"
  auto_minor_version_upgrade = false

  deletion_protection = false
  skip_final_snapshot = true
  apply_immediately   = true

  tags = {
    Name    = "${var.project}-${var.environment}-rds-instance"
    Project = var.project
    Env     = var.environment
  }
}

### rds password generate
resource "random_string" "db_userpass" {
  length = 16

  special     = false
  lower       = true
  upper       = true
  numeric     = true
  min_lower   = 0
  min_upper   = 0
  min_numeric = 0
  min_special = 0
}

# ---
# RDS SSM
# ---
resource "aws_ssm_parameter" "ssm_db_hostname" {
  name        = "/${var.project}-${var.environment}/DB_HOST"
  description = "database host"
  type        = "String"
  value       = aws_db_instance.rds_instance.address

  tags = {
    Name    = "${var.project}-${var.environment}-rds-host"
    Project = var.project
    Env     = var.environment
  }
}
resource "aws_ssm_parameter" "ssm_db_database" {
  name        = "/${var.project}-${var.environment}/DB_DATABASE"
  description = "database name"
  type        = "String"
  value       = aws_db_instance.rds_instance.name

  tags = {
    Name    = "${var.project}-${var.environment}-rds-database"
    Project = var.project
    Env     = var.environment
  }
}
resource "aws_ssm_parameter" "ssm_db_username" {
  name        = "/${var.project}-${var.environment}/DB_USERNAME"
  description = "database username"
  type        = "SecureString"
  value       = aws_db_instance.rds_instance.username

  tags = {
    Name    = "${var.project}-${var.environment}-rds-username"
    Project = var.project
    Env     = var.environment
  }
}
resource "aws_ssm_parameter" "ssm_db_userpass" {
  name        = "/${var.project}-${var.environment}/DB_USERPASS"
  description = "database userpassword"
  type        = "SecureString"
  value       = aws_db_instance.rds_instance.password

  tags = {
    Name    = "${var.project}-${var.environment}-rds-userpass"
    Project = var.project
    Env     = var.environment
  }
}
