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

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "hotel-app"

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

module "iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "ecr-push-policy"
  path        = "/"
  description = "My example policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:CompleteLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:InitiateLayerUpload",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage"

      ],
      "Effect": "Allow",
      "Resource": "${module.ecr.repository_arn}"
    },
    {
            "Effect": "Allow",
            "Action": "ecr:GetAuthorizationToken",
            "Resource": "*"
    }
  ]
}
EOF
}

module "iam_github_oidc_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"

  # This should be updated to suit your organization, repository, references/branches, etc.
  subjects = ["celtic01/hotel-app:*"]

  policies = {
    ECRPUSH = "${module.iam_policy.arn}"
  }

  tags = {
    Environment = "test"
  }
}

module "iam_github_oidc_provider" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"

  tags = {
    Environment = "test"
  }
}