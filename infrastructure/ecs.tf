
################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  cluster_name = "main-cluster" 

  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    group_1 = {
      auto_scaling_group_arn         = module.autoscaling["group_1"].autoscaling_group_arn
      managed_termination_protection = "DISABLED"

      managed_scaling = {
        maximum_scaling_step_size = 1 
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 100
      }

      default_capacity_provider_strategy = {
        weight = 1
        base   = 1
      }
    }
  }

}

################################################################################
# Service
################################################################################

module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = local.name
  cluster_arn = module.ecs_cluster.arn
  force_delete = true
  requires_compatibilities = ["EC2"]

  capacity_provider_strategy = {
    group_1 = {
      capacity_provider = module.ecs_cluster.autoscaling_capacity_providers["group_1"].name
      weight            = 1 
      base              = 1
    }
  }
 cpu = 256
 memory = 512

  container_definitions = {
    (local.container_name) = {
      cpu       = 256
      memory    = 512
      image = "151389984452.dkr.ecr.us-west-2.amazonaws.com/hotel-app:latest"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name = "DB_CREDS"
          valueFrom = "${module.db.db_instance_master_user_secret_arn}"
        } 
      ]
      environment = [
         {
          name  = "IN_PROD"
          value = "true"
        },
        {
          name  = "DB_HOST"
          value = module.db.db_instance_address
        },
        {
          name  = "DB_NAME"
          value = module.db.db_instance_name
        }
      ]

      readonly_root_filesystem = false

      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/aws/ecs/${local.name}/${local.container_name}-svc"
      cloudwatch_log_group_retention_in_days = 7

      log_configuration = {
        logDriver = "awslogs"
      }
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["ecs_hotel"].arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    svc_http_ingress = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb.security_group_id
    },
   svc_http_egress = {
    type        = "egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Outbound traffic for service port"
    cidr_blocks = ["0.0.0.0/0"]
  }
  }

  tags = local.tags
}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = "hotel-alb"

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.acm_certificate_arn

      forward = {
        target_group_key = "ecs_hotel"
      }
  }
  }
  target_groups = {
    ecs_hotel = {
      backend_protocol                  = "HTTP"
      backend_port                      = local.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = false

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
    }
  }


}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5"

  for_each = {
    group_1 = {
      instance_type              = "t3.medium"
      use_mixed_instances_policy = false
      mixed_instances_policy     = {}
      user_data                  = <<-EOT
        #!/bin/bash

        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${"main-cluster"}
        ECS_LOGLEVEL=debug
        ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(local.tags)}
        ECS_ENABLE_TASK_IAM_ROLE=true
        EOF
      EOT
    }
  }

  name = "asg-${each.key}"

  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type = each.value.instance_type

  security_groups                 = [module.autoscaling_sg.security_group_id]
  user_data                       = base64encode(each.value.user_data)
  ignore_desired_capacity_changes = false 

  create_iam_instance_profile = true
  iam_role_name               = "ecs-instance-role-${each.key}"
  iam_role_description        = "ECS role for ${each.key} instances"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 2 
  desired_capacity    = 1

  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  protect_from_scale_in = false 

  tags = local.tags
}

module "autoscaling_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "asg-sg"
  description = "Autoscaling group security group"
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]

  tags = local.tags
}

module "acm" {
 source  = "terraform-aws-modules/acm/aws"
  version = "5.0.1"

  domain_name = local.domain_name
  zone_id     = data.cloudflare_zone.this.id

  subject_alternative_names = [
    "*.${local.domain_name}"
  ]

  create_route53_records  = false
  validation_method       = "DNS"
  validation_record_fqdns = cloudflare_record.validation[*].hostname

  tags = {
    Name = local.domain_name
  }
}

resource "cloudflare_record" "validation" {
  count = length(module.acm.distinct_domain_names)

  zone_id = data.cloudflare_zone.this.id
  name    = element(module.acm.validation_domains, count.index)["resource_record_name"]
  type    = element(module.acm.validation_domains, count.index)["resource_record_type"]
  value   = trimsuffix(element(module.acm.validation_domains, count.index)["resource_record_value"], ".")
  ttl     = 60
  proxied = false

  allow_overwrite = true
}

data "cloudflare_zone" "this" {
  name = local.domain_name
}

resource "cloudflare_record" "hotel-bortas" {
  zone_id = data.cloudflare_zone.this.id
  name    = "hotel-app.${local.domain_name}"
  value   = "${module.alb.dns_name}"
  type    = "CNAME"
  ttl     = 3600
}


