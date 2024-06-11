module "vpc" {
  source                  = "./modules/vpc"
  vpc_id                  = module.vpc.vpc_id
  region                  = var.region
  project_name            = var.project_name
  vpc_cidr                = var.vpc_cidr
  public_subnet_az1_cidr  = var.public_subnet_az1_cidr
  public_subnet_az2_cidr  = var.public_subnet_az2_cidr
  public_subnet_az3_cidr  = var.public_subnet_az3_cidr
  private_subnet_az1_cidr = var.private_subnet_az1_cidr
  private_subnet_az2_cidr = var.private_subnet_az2_cidr
  private_subnet_az3_cidr = var.private_subnet_az3_cidr
  enable_nat_gateway      = var.enable_nat_gateway
}


module "smackdab_dev_key" {
  source          = "./modules/key_pair"
  key_name        = var.key_name
  public_key_path = "./smackdab_dev.pub"
}

# Find AWS AMI ID For Ubuntu & Amazon Linux AMI 2
data "aws_ami" "ami2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"] # Canonical
}


module "bastion_security_group" {
  source       = "./modules/security_group"
  project_name = var.project_name
  module_name  = "bastion"
  description  = "ssh access"
  vpc_id       = module.vpc.vpc_id
  ingress_access = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["103.215.158.90/32"]
    }
  ]
  egress_access = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}




module "bastion_host" {
  module_name                 = "bastion-host"
  project_name                = var.project_name
  instance_use                = "bastion-for-ssh"
  source                      = "./modules/ec2"
  security_groups             = [module.bastion_security_group.id]
  ami                         = data.aws_ami.ami2.id
  type                        = "t3.micro"
  keyname                     = module.smackdab_dev_key.smackdab_dev_key
  instance_tags               = var.instance_tags
  subnets                     = module.vpc.public_subnet_az1 #change the subnet according to the ec2 configuration example vpc.private_subnet_az1
  vpc_id                      = module.vpc.vpc_id
  associate_public_ip_address = true
  root_volume_size            = var.root_volume_size
}


module "citus_dev_security_group" {
  source       = "./modules/security_group"
  project_name = var.project_name
  module_name  = "citus-dev"
  description  = "Citus Dev Serveres For Postgres"
  vpc_id       = module.vpc.vpc_id
  ingress_access = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${module.bastion_host.private_ip}/32"]
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["103.215.158.90/32"]
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [var.private_subnet_az1_cidr, var.private_subnet_az2_cidr, var.private_subnet_az3_cidr]
    }
  ]
  egress_access = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

resource "aws_eip" "bastion_ip" {
  domain   = "vpc"
  instance = module.bastion_host.id
}



module "citus_security_group" {
  source       = "./modules/security_group"
  project_name = var.project_name
  module_name  = "citus"
  description  = "citus port access to private subnet only"
  vpc_id       = module.vpc.vpc_id
  ingress_access = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${module.bastion_host.private_ip}/32"]
    }
  ]
  egress_access = [
    {
      description = "All outbound trafic allowed in private subnet"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "citus_coordinator" {
  module_name                 = "citus-coordinator"
  project_name                = var.project_name
  instance_use                = "co-ordniator"
  source                      = "./modules/ec2"
  security_groups             = [module.citus_security_group.id]
  ami                         = "ami-042e9f66108f5ba1a"
  type                        = "m7a.medium"
  keyname                     = module.smackdab_dev_key.smackdab_dev_key
  instance_tags               = var.instance_tags
  subnets                     = module.vpc.private_subnet_az1 #change the subnet according to the ec2 configuration example vpc.private_subnet_az1
  vpc_id                      = module.vpc.vpc_id
  associate_public_ip_address = var.associate_public_ip_address
  root_volume_size            = var.root_volume_size
}

module "citus_worker_1" {
  module_name                 = "citus-worker-1"
  project_name                = var.project_name
  instance_use                = "worker"
  source                      = "./modules/ec2"
  security_groups             = [module.citus_security_group.id]
  ami                         = "ami-042e9f66108f5ba1a"
  type                        = "r7a.medium"
  keyname                     = module.smackdab_dev_key.smackdab_dev_key
  instance_tags               = var.instance_tags
  subnets                     = module.vpc.private_subnet_az2 #change the subnet according to the ec2 configuration example vpc.private_subnet_az1
  vpc_id                      = module.vpc.vpc_id
  associate_public_ip_address = var.associate_public_ip_address
  root_volume_size            = var.root_volume_size
}

module "citus_worker_2" {
  module_name                 = "citus-worker-2"
  project_name                = var.project_name
  instance_use                = "worker"
  source                      = "./modules/ec2"
  security_groups             = [module.citus_security_group.id]
  ami                         = "ami-042e9f66108f5ba1a"
  type                        = "r7a.medium"
  keyname                     = module.smackdab_dev_key.smackdab_dev_key
  instance_tags               = var.instance_tags
  subnets                     = module.vpc.private_subnet_az3 #change the subnet according to the ec2 configuration example vpc.private_subnet_az1
  vpc_id                      = module.vpc.vpc_id
  associate_public_ip_address = var.associate_public_ip_address
  root_volume_size            = var.root_volume_size
}


module "dev_eks_cluster" {
  source        = "./modules/eks"
  module_name   = "eks_dev_cluster"
  project_name  = var.project_name
  subnet_ids    = [module.vpc.private_subnet_az1, module.vpc.public_subnet_az1, module.vpc.public_subnet_az2, module.vpc.private_subnet_az2, module.vpc.public_subnet_az3, module.vpc.private_subnet_az3]
  eks_version   = "1.29"
  desired_size  = var.desired_size
  min_size      = var.min_size
  max_size      = var.max_size
  instance_type = "m6a.xlarge"
  usage_label   = "dev_node"
}

module "alb_helm_release" {
  source        = "./modules/alb"
  project_name  = var.project_name
  region        = var.region
  cluster_name  = module.dev_eks_cluster.ekscluster_name
  cluster_state = module.dev_eks_cluster.ekscluster_name
}

# module "karpenter" {
#   source           = "./modules/Karpenter"
#   project_name     = var.project_name
#   region           = var.region
#   public_subnet_a1 = module.vpc.public_subnet_az1
#   public_subnet_a2 = module.vpc.public_subnet_az2
#   public_subnet_a3 = module.vpc.public_subnet_az3
#   instance_profile = module.dev_eks_cluster.eks_cluster_profile
#   cluster_name     = module.dev_eks_cluster.ekscluster_name
# }


# module "test_citus_patroni" {
#   module_name                 = "citus-patroni"
#   project_name                = var.project_name
#   instance_use                = "co-ordniator"
#   source                      = "./modules/ec2"
#   security_groups             = [module.citus_security_group.id]
#   ami                         = data.aws_ami.ubuntu.id
#   type                        = "t3.micro"
#   keyname                     = module.smackdab_dev_key.smackdab_dev_key
#   instance_tags               = var.instance_tags
#   subnets                     = module.vpc.private_subnet_az1 #change the subnet according to the ec2 configuration example vpc.private_subnet_az1
#   vpc_id                      = module.vpc.vpc_id
#   associate_public_ip_address = var.associate_public_ip_address
#   root_volume_size            = var.root_volume_size
# }

# module "extra_storage" {
#   source            = "./modules/block_storage"
#   project_name      = var.project_name
#   final_snapshot    = false
#   instance_id       = module.test_citus_patroni.id
#   volume_size       = 30
#   availability_zone = module.vpc.private_az1
#   depends_on        = [module.test_citus_patroni]
# }
