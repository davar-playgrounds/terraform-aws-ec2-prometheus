# Specify that we're using AWS, using the aws_region variable
provider "aws" {
  region  = var.aws_region
#   version = "~> 2.43.0"
}

# module "ami" {
#   source = "github.com/insight-infrastructure/terraform-aws-ami.git?ref=master"
# }

# module "label" {
#   source = "github.com/robc-io/terraform-null-label.git?ref=0.16.1"
#   name = var.name
#   tags = {
#     NetworkName = var.network_name
#     Owner       = var.owner
#     Terraform   = true
#     VpcType     = "main"
#   }
#   environment = var.environment
#   namespace   = var.namespace
#   stage       = var.stage
# }
/* 
Configuration to make a very simple sandbox VPC for a few instances
For more details and options on the AWS vpc module, visit:
https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.21.0
 */
module "sandbox_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name = "${var.fellow_name}-vpc"
  cidr           = var.cidr
  azs            = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets = ["10.0.0.0/28"]
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_s3_endpoint = true
  tags = {
    Owner       = var.fellow_name
    Environment = "dev"
    Terraform   = "true"
  }
}
/*
#Configuration for a security group within our configured VPC sandbox,
open to standard SSH port from your local machine only.
For more details and options on the AWS sg module, visit:
https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/3.3.0
Check out all the available sub-modules at:
https://github.com/terraform-aws-modules/terraform-aws-security-group/tree/master/modules
 */

module "ssh_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.3.0"

  name        = "ssh_sg"
  description = "Security group for instances"
  vpc_id      = "${module.sandbox_vpc.vpc_id}"
  
  ingress_cidr_blocks      = ["10.0.0.0/28"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = "68.184.19.170/32"
    }
  ]  
  egress_cidr_blocks      = ["10.0.0.0/28"]
  egress_with_cidr_blocks = [
    {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
   tags = {
    Owner       = "${var.fellow_name}"
    Environment = "dev"
    Terraform   = "true"
  }
}
resource "tls_private_key" "sskeygen_execution" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Configuration for a "master" instance
resource "aws_instance" "Prometheus_master" {
  ami           = var.amis[var.aws_region]
  instance_type = var.instance_type
  key_name      = var.keypair_name
  # tags = module.label.tags
  vpc_security_group_ids      = [module.ssh_sg.this_security_group_id]
  subnet_id                   = module.sandbox_vpc.public_subnets[0]
  associate_public_ip_address = true
    root_block_device {
    volume_size = var.root_volume_size
  }
  tags = {
    Name        = "Prometheus-master"
    Owner       = var.fellow_name
    Environment = "dev"
    Terraform   = "true"
  }
#   iam_instance_profile = aws_iam_instance_profile.this.id
  # key_name             = var.public_key_path == "" ? var.key_name : aws_key_pair.this.*.key_name[0]
connection {
    user     = "ubuntu"
    host = self.public_ip
    private_key = tls_private_key.sskeygen_execution.private_key_pem
  }

provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt -y install apt-transport-https ca-certificates curl software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable'",
      "sudo apt update",
      "sudo apt -y install docker-ce",
      "git clone https://github.com/stefanprodan/dockprom",
      "cd dockprom",
      "ADMIN_USER=admin ADMIN_PASSWORD=admin docker-compose up -d"
    ]
  }
provisioner "local-exec" {
    command = "echo '${tls_private_key.sskeygen_execution.private_key_pem}'"
  }
}
# # Configuration for an Elastic IP to add to nodes
resource "aws_eip" "elastic_ips_for_instances" {
  vpc = true
  instance = aws_instance.Prometheus_master.id
  tags = {
    NetworkName = var.network_name
    Owner       = var.owner
    Terraform   = true
    VpcType     = "main"
  }
}

resource "aws_eip_association" "elastic_ips_association" {
  instance_id = aws_instance.Prometheus_master.id
  public_ip   = aws_eip.elastic_ips_for_instances.public_ip
}
# module "ansible" {
#   source           = "github.com/insight-infrastructure/terraform-aws-ansible-playbook.git?ref=master"
#   ip               = aws_eip_association.this.public_ip
#   user             = "ubuntu"
#   private_key_path = var.private_key_path
#   playbook_file_path = "${path.module}/ansible/main.yml"
#   playbook_vars = {
#     ansible_host = var.root_domain_name == "" ? aws_eip.this.public_ip : join("", aws_route53_record.this.*.fqdn)
#   }
#   playbook_vars_file = var.playbook_vars_file
#   requirements_file_path = "${path.module}/ansible/requirements.yml"
# }

# #------------------------------------------------------------------
# resource "aws_ebs_volume" "ebs" {
#   availability_zone = data.availability_zone.availability_zone.

#   count = var.ebs_volume_size > 0 ? 1 : 0
#   availability_zone = aws_instance.this.availability_zone[0]
#   size = var.ebs_volume_size
#   type = "gp2"
#   tags = merge({ Mount : "data" }, module.label.tags)
# }
# resource "aws_volume_attachment" "this" {
#   count = var.ebs_volume_size > 0 ? 1 : 0
#   device_name = var.volume_path
#   volume_id = aws_ebs_volume.this.*.id[0]
#   instance_id  = aws_instance.this.id
#   force_detach = true
# }
# #------------------------------------------------------------------
# data "aws_caller_identity" "this" {}
# #------------------------------------------------------------------
# resource "aws_s3_bucket" "logs" {
#   bucket = "logs-${data.aws_caller_identity.this.account_id}-${random_pet.this.id}"
#   acl    = "private"
#   tags   = module.label.tags
# }
# #------------------------------------------------------------------
# resource "aws_key_pair" "this" {
#   count      = var.public_key_path == "" ? 0 : 1
#   public_key = file(var.public_key_path)
#   tags = module.label.tags
# }
# #------------------------------------------------------------------
# # internet gatway
# resource "aws_internet_gateway" "internet_gatway" {
#     vpc_id = "${sandbox_vpc.name.id}"
#     tags {
#         name = "igw"
#     } 
# }
# # Route Table
# resource "aws_route_table" "route_table" {
#   vpc_id = "${sandbox_vpc.name.id}"
#   route{
#       cidr_block = "0.0.0.0/0"
#       gateway_id = "${aws_internet_gateway.internet_gatway.id}"
#   }
#   tags{
#       name = "rout_table"
#   }
# }
/* 
# #------------------------------------------------------------------
/* 
For all the arguments and options, visit:
https://www.terraform.io/docs/providers/aws/r/instance.html
Note: You don't need the below resources for using the Pegasus tool
 */
# # Configuration for an Elastic IP to add to nodes
# resource "aws_eip" "elastic_ips_for_instances" {
#   vpc = true
#   instance = element(
#     concat(
#       aws_instance.Prometheus_master.*.id,
#     ),
#     count.index,
#   )
#   count = length(aws_instance.Prometheus_master) 
# }
# data "aws_route53_zone" "selected" {
#   # count = var.root_domain_name == "" ? 0 : 1
#   name  = "${var.root_domain_name}."
# }

# resource "aws_route53_record" "www" {
#   # count = var.root_domain_name == "" ? 0 : 1
#   zone_id = data.aws_route53_zone.selected.zone_id
#   name = ".${data.aws_route53_zone.selected.name}"
#   type = "A"
#   ttl  = "300"
#   records = ["${aws_eip.elastic_ips_for_instances.public_ip}"]
# }
