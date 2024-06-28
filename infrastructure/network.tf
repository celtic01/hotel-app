module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "main"
  cidr = local.vpc_cidr

  azs = local.azs
  private_subnets     = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets      = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  database_subnets    = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]

  create_database_subnet_group  = true
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

}

resource "aws_network_acl" "db_nacl" {
  vpc_id = module.vpc.vpc_id

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action = "allow"
    cidr_block = module.vpc.private_subnets_cidr_blocks[0]
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action = "allow"
    cidr_block = module.vpc.private_subnets_cidr_blocks[1]
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    rule_no    = 120
    protocol   = "-1"
    action = "deny"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }
  
    egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0" 
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_network_acl_association" "db_subnets" {
  for_each = local.db_subnets_map

  subnet_id       = each.value
  network_acl_id  = aws_network_acl.db_nacl.id
}