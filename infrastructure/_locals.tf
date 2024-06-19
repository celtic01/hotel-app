
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
  domain_name="bortas.ro"
}

