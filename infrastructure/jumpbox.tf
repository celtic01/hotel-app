module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"
  name = local.name

  instance_type          = "t2.micro"

  subnet_id              = element(module.vpc.private_subnets, 0)
  vpc_security_group_ids = [module.security_group_instance.security_group_id]

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

module "security_group_instance" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-ec2"
  description = "Security Group for EC2 Instance Egress"

  vpc_id = module.vpc.vpc_id

  egress_rules = ["all-all"]

  tags = local.tags
}