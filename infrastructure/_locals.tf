
locals {
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)
  vpc_cidr = "10.0.0.0/16"
  tags = {
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-ecs"
  }
  region = "us-west-2"
  container_name = "hotel-app"
  container_port = 8080 
  name= "hotel-app"
  private_subnet_cidrs = flatten([for cidr in module.vpc.private_subnets : [cidr]])
  database_subnet_ids = toset(module.vpc.database_subnets)
  db_subnets_map = {
    for idx, subnet_id in module.vpc.database_subnets : idx => subnet_id
  }
  domain_name="bortas.ro"
}

