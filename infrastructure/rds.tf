module "db" {
   source  = "terraform-aws-modules/rds/aws"
  version = "6.6.0"

  identifier = "postgresql-hotel" 

  engine               = "postgres"
  engine_version       = "14"
  family               = "postgres14" 
  major_engine_version = "14"        
  instance_class       = "db.t4g.small"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "hotelreservationproduction"
  username = "hotelapp"
  port     = 5432

  manage_master_user_password_rotation              = true
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(15 days)"

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]

  skip_final_snapshot     = true
  deletion_protection     = false

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = local.tags
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "complete_postgresql"
  description = "Complete PostgreSQL example security group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}