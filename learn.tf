# =============================================================================
# LEARN TERRAFORM AWS - COMPLETE GUIDE FROM ZERO TO EXPERT (2025)
# =============================================================================
# Hướng dẫn đầy đủ Infrastructure as Code với Terraform cho AWS
# Mọi AWS resources phổ biến đều được cover
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# =============================================================================
# AWS PROVIDER - MULTI-REGION
# =============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Additional region for multi-region deployment
provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Region      = "us-west-2"
    }
  }
}

# =============================================================================
# VARIABLES - AWS SPECIFIC
# =============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^us-", var.aws_region))
    error_message = "Region must start with 'us-'."
  }
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnet_cidrs" {
  description = "Database subnet CIDRs"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "domain_name" {
  description = "Domain name for Route53"
  type        = string
  default     = "example.com"
}

variable "enable_cloudfront" {
  description = "Enable CloudFront CDN"
  type        = bool
  default     = true
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  # Select 2 AZs from availability_zones
  selected_azs = slice(var.availability_zones, 0, 2)
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Get current AWS account info
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Get latest Amazon Linux AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get existing VPC (if using existing VPC)
# data "aws_vpc" "existing" {
#   id = var.vpc_id
# }

# =============================================================================
# SECTION 1: VPC (VIRTUAL PRIVATE CLOUD)
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_classiclink   = false

  # Enable IPv6 (optional)
  # assign_generated_ipv6_cidr_block = true

  tags = merge(
    local.common_tags,
    {
      Name  = "${local.name_prefix}-vpc"
      Type  = "main-vpc"
    }
  )
}

# VPC IPv6 CIDR (if enabled)
# resource "aws_vpc_ipv6_cidr_block_association" "main" {
#   vpc_id     = aws_vpc.main.id
#   ipv6_cidr_block = one(aws_vpc.main.ipv6_cidr_block).ipv6_cidr_block
# }

# =============================================================================
# SECTION 2: INTERNET GATEWAY
# =============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
}

# =============================================================================
# SECTION 3: SUBNETS
# =============================================================================

# Public subnets
resource "aws_subnet" "public" {
  count                   = length(local.selected_azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.selected_azs[count.index]
  map_public_ip_on_launch = true

  # IPv6 addressing (optional)
  # assign_ipv6_address_on_creation = true
  # ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-${count.index + 1}"
      Type = "public"
    }
  )
}

# Private subnets (app tier)
resource "aws_subnet" "private" {
  count             = length(local.selected_azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.selected_azs[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-${count.index + 1}"
      Type = "private"
    }
  )
}

# Private subnets (database tier - isolated)
resource "aws_subnet" "database" {
  count             = length(local.selected_azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = local.selected_azs[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-database-${count.index + 1}"
      Type = "database"
    }
  )
}

# =============================================================================
# SECTION 4: NAT GATEWAY (for private subnets internet access)
# =============================================================================

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = length(local.selected_azs)
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count         = length(local.selected_azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-gw-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# SECTION 5: ROUTE TABLES
# =============================================================================

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # IPv6 route (optional)
  # route {
  #   ipv6_cidr_block = "::/0"
  #   gateway_id      = aws_internet_gateway.main.id
  # }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-rt"
    }
  )
}

# Private route tables (with NAT gateway)
resource "aws_route_table" "private" {
  count  = length(local.selected_azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-rt-${count.index + 1}"
    }
  )
}

# Database route table (isolated - no internet access)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-database-rt"
    }
  )
}

# Route table associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "database" {
  count          = length(aws_subnet.database)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# =============================================================================
# SECTION 6: SECURITY GROUPS & NACLs
# =============================================================================

# Security group for web servers
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "HTTP from IPv6"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for application servers
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from web servers only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# Security group for databases
resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database-sg"
  description = "Security group for databases"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from application servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description     = "PostgreSQL from application servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = local.common_tags
}

# Security group for ALB
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# Network ACLs (Stateless firewall)
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  ingress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-nacl"
    }
  )
}

# =============================================================================
# SECTION 7: EC2 INSTANCES
# =============================================================================

resource "aws_instance" "web" {
  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_types[var.environment]
  subnet_id              = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids = [aws_security_group.web.id]

  # User data script
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd php mysql
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
              EOF

  # Root block device
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
    throughput            = 125
    iops                  = 3000
  }

  # Additional EBS volume
  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true
  }

  # IMDSv2 (more secure)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Monitoring
  monitoring = var.enable_monitoring

  # Placement tenancy
  # tenancy = "dedicated"  # For dedicated instances

  tags = merge(
    local.common_tags,
    {
      Name  = "${local.name_prefix}-web-${count.index + 1}"
      Type  = "web-server"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# SECTION 8: KEY PAIR
# =============================================================================

resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  key_name   = "${local.name_prefix}-keypair"
  public_key = tls_private_key.generated.public_key_openssh

  tags = local.common_tags
}

resource "local_file" "private_key" {
  content  = tls_private_key.generated.private_key_pem
  filename = "${local.name_prefix}-private_key.pem"

  provisioner "local-exec" {
    command = "chmod 400 ${self.filename}"
  }
}

# =============================================================================
# SECTION 9: LOAD BALANCERS
# =============================================================================

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false
  enable_http_two            = true
  idle_timeout               = 60
  drop_invalid_header_fields = true

  # Access logs
  # access_logs {
  #   bucket  = aws_s3_bucket.logs.id
  #   prefix  = "alb-logs"
  #   enabled = true
  # }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb"
    }
  )
}

# ALB Target group
resource "aws_lb_target_group" "web" {
  name        = "${local.name_prefix}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  stickiness {
    type        = "lb_cookie"
    cookie_duration = 86400
    enabled     = true
  }

  tags = local.common_tags
}

# Attach instances to target group
resource "aws_lb_target_group_attachment" "web" {
  count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# ALB Listener (HTTP)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB Listener (HTTPS)
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 443
#   protocol          = "HTTPS"
#   certificate_arn   = aws_acm_certificate.main.arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web.arn
#   }
# }

# =============================================================================
# SECTION 10: AUTO SCALING GROUP
# =============================================================================

# Launch template
resource "aws_launch_template" "web" {
  name_prefix   = "${local.name_prefix}-web-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_types[var.environment]

  key_name   = aws_key_pair.generated.key_name
  monitoring  = true

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web.id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name = "${local.name_prefix}-web-asg"
      }
    )
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Auto-scaled Instance</h1>" > /var/www/html/index.html
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  desired_capacity    = 2
  max_size            = 5
  min_size            = 1
  vpc_zone_identifier = aws_subnet.public[*].id

  target_group_arns = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-asg"
    propagate_at_launch = true
  }

  health_check_type   = "ELB"
  health_check_grace_period = 300
}

# Auto Scaling policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${local.name_prefix}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${local.name_prefix}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# CloudWatch alarms for auto scaling
# resource "aws_cloudwatch_metric_alarm" "high_cpu" {
#   alarm_name          = "${local.name_prefix}-high-cpu"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = "300"
#   statistic           = "Average"
#   threshold           = "80"
#   alarm_description   = "This metric monitors EC2 CPU utilization"
#   alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
#
#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.web.name
#   }
# }

# =============================================================================
# SECTION 11: S3 BUCKETS
# =============================================================================

resource "aws_s3_bucket" "website" {
  bucket = "${local.name_prefix}-website"

  tags = local.common_tags
}

# Website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access (for security)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for website
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
    ]
  })
}

# S3 bucket for logging
resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-logs"

  tags = local.common_tags
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log-expiration"
    status = "enabled"

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# =============================================================================
# SECTION 12: RDS DATABASE
# =============================================================================

# DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = local.common_tags
}

# RDS MySQL instance
resource "aws_db_instance" "mysql" {
  identifier           = "${local.name_prefix}-mysql"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_encrypted    = true
  storage_type         = "gp2"

  db_name  = "myapp"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  multi_az               = false
  publicly_accessible    = false

  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  final_snapshot_identifier = "${local.name_prefix}-mysql-final-snapshot"
  skip_final_snapshot       = var.environment != "prod"

  performance_insights_enabled = true

  tags = local.common_tags
}

# RDS Read Replica (for multi-AZ)
# resource "aws_db_instance" "mysql_replica" {
#   identifier             = "${local.name_prefix}-mysql-replica"
#   replicate_source_db     = aws_db_instance.mysql.identifier
#   instance_class          = "db.t3.micro"
#   availability_zone       = "us-east-1b"
#
#   skip_final_snapshot = true
#
#   tags = local.common_tags
# }

# =============================================================================
# SECTION 13: ELASTICACHE (REDIS)
# =============================================================================

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-cache-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = local.common_tags
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${local.name_prefix}-redis"
  replication_group_description = "Redis cluster"
  node_type                     = "cache.t3.micro"
  number_cache_clusters         = length(local.selected_azs)
  subnet_group_name             = aws_elasticache_subnet_group.main.name
  security_group_ids            = [aws_security_group.app.id]

  automatic_failover_enabled = true
  multi_az_enabled            = true

  port           = 6379
  engine         = "redis"
  engine_version = "7.0"

  snapshot_retention_limit = var.environment == "prod" ? 30 : 7
  snapshot_window       = "03:00-05:00"

  tags = local.common_tags
}

# =============================================================================
# SECTION 14: DYNAMODB
# =============================================================================

resource "aws_dynamodb_table" "users" {
  name           = "${local.name_prefix}-users"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "UserName"
    type = "S"
  }

  global_secondary_index {
    name            = "UserNameIndex"
    hash_key        = "UserName"
    projection_type = "ALL"
    read_capacity   = 2
    write_capacity  = 2
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.common_tags
}

# DynamoDB Autoscaling
# resource "aws_appautoscaling_target" "dynamodb_read" {
#   max_capacity       = 100
#   min_capacity       = 5
#   resource_id        = "table/${aws_dynamodb_table.users.name}"
#   scalable_dimension = "dynamodb:table:ReadCapacityUnits"
#   service_namespace  = "dynamodb"
# }
#
# resource "aws_appautoscaling_policy" "dynamodb_read" {
#   name               = "${local.name_prefix}-dynamodb-read-autoscaling"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.dynamodb_read.resource_id
#   scalable_dimension = aws_appautoscaling_target.dynamodb_read.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.dynamodb_read.service_namespace
#
#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }
#     target_value = 70
#   }
# }

# =============================================================================
# SECTION 15: LAMBDA FUNCTIONS
# =============================================================================

# Lambda IAM role
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Lambda IAM policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function
resource "aws_lambda_function" "example" {
  function_name = "${local.name_prefix}-lambda"
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.11"
  handler       = "index.lambda_handler"
  timeout       = 30
  memory_size   = 256

  filename = "lambda_function_payload.zip"

  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = "INFO"
    }
  }

  tags = local.common_tags
}

# Lambda function code (index.py)
# def lambda_handler(event, context):
#     return {
#         'statusCode': 200,
#         'body': json.dumps('Hello from Lambda!')
#     }

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.example.function_name}"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = local.common_tags
}

# =============================================================================
# SECTION 16: API GATEWAY
# =============================================================================

resource "aws_apigatewayv2_api" "main" {
  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"
  description   = "API Gateway for ${var.project_name}"

  tags = local.common_tags
}

resource "aws_apigatewayv2_vpc_link" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  subnet_ids  = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.app.id]
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.example.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "example" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /example"
  target   = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# API Gateway deployment
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format         = jsonencode({
      requestId = "$context.requestId"
      ip         = "$context.identity.sourceIp"
      requestTime = "$context.requestTime"
      httpMethod = "$context.httpMethod"
      routeKey   = "$context.routeKey"
      status     = "$status"
      protocol   = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = local.common_tags
}

# =============================================================================
# SECTION 17: SQS QUEUES
# =============================================================================

resource "aws_sqs_queue" "main" {
  name                      = "${local.name_prefix}-queue"
  message_retention_seconds = 86400  # 1 day
  max_message_size           = 256000  # 256 KB
  visibility_timeout_seconds = 30
  receive_wait_time_seconds = 20     # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })

  tags = local.common_tags
}

# Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name = "${local.name_prefix}-dlq"

  tags = local.common_tags
}

# =============================================================================
# SECTION 18: SNS TOPICS
# =============================================================================

resource "aws_sns_topic" "notifications" {
  name = "${local.name_prefix}-notifications"

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main.arn
}

# =============================================================================
# SECTION 19: CLOUDFRONT (CDN)
# =============================================================================

resource "aws_cloudfront_distribution" "main" {
  count = var.enable_cloudfront ? 1 : 0

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "${local.name_prefix}-s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main[0].cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.name_prefix}-s3-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  price_class = "PriceClass_100"  // US, Canada, Europe

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.common_tags
}

resource "aws_cloudfront_origin_access_identity" "main" {
  count  = var.enable_cloudfront ? 1 : 0
  comment = "${local.name_prefix} OAI"
}

# =============================================================================
# SECTION 20: ROUTE53
# =============================================================================

resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = local.common_tags
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main[0].domain_name
    zone_id                = aws_cloudfront_distribution.main[0].hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "CNAME"

  alias {
    name                   = aws_apigatewayv2_api.main.api_endpoint
    zone_id                = aws_apigatewayv2_api.main.execution_arn
    evaluate_target_health = true
  }
}

# =============================================================================
# SECTION 21: CLOUDWATCH
# =============================================================================

resource "aws_cloudwatch_log_group" "application" {
  name              = "${local.name_prefix}-application"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = local.common_tags
}

resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${local.name_prefix}-error-metric"
  log_group_name = aws_cloudwatch_log_group.application.name

  pattern        = "[timestamp=* level=ERROR*, timestamp=* level=ERROR]"
  metric_transformation {
    name      = "ErrorCount"
    namespace = "${local.name_prefix}"
    value     = "1"
  }
}

# Dashboard
# resource "aws_cloudwatch_dashboard" "main" {
#   dashboard_name = "${local.name_prefix}-dashboard"
#
#   dashboard_body = jsonencode([
#     {
#       type   = "metric"
#       x_axis = {
#         label = "Time"
#       }
#       y_axis = {
#         label = "CPU %"
#       }
#       metrics = [
#         {
#           namespace = "AWS/EC2"
#           name      = "CPUUtilization"
#           dimensions = {
#             AutoScalingGroupName = aws_autoscaling_group.web.name
#           }
#           stat      = "Average"
#           period    = 300
#           id        = "e1"
#           return_data = false
#         }
#       ]
#       region = "us-east-1"
#     }
#   ])
# }

# =============================================================================
# SECTION 22: KMS ENCRYPTION
# =============================================================================

resource "aws_kms_key" "main" {
  description             = "${local.name_prefix} KMS key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.main.key_id
}

# =============================================================================
# SECTION 23: SECRETS MANAGER
# =============================================================================

resource "aws_secretsmanager_secret" "database" {
  name = "${local.name_prefix}/database"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id     = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.mysql.endpoint
    dbname   = aws_db_instance.mysql.db_name
  })
}

# =============================================================================
# SECTION 24: PARAMETER STORE
# =============================================================================

resource "aws_ssm_parameter" "app_config" {
  name  = "/${local.name_prefix}/app/config"
  type  = "String"
  value = jsonencode({
    environment = var.environment
    log_level    = "INFO"
    debug        = false
  })

  tags = local.common_tags
}

# =============================================================================
# SECTION 25: ECS (ELASTIC CONTAINER SERVICE)
# =============================================================================

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-ecs"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.application.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.database.arn
        }
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "app"
    container_port   = 80
  }

  tags = local.common_tags
}

# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "${local.name_prefix}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.common_tags
}

# ECS IAM roles
resource "aws_iam_role" "ecs_execution" {
  name = "${local.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# =============================================================================
# SECTION 26: EKS (ELASTIC KUBERNETES SERVICE)
# =============================================================================

# VPC for EKS (more complex networking)
# resource "aws_eks_cluster" "main" {
#   name     = "${local.name_prefix}-eks"
#   role_arn  = aws_iam_role.eks_cluster.arn
#   version  = "1.28"
#
#   vpc_config {
#     subnet_ids              = aws_subnet.private[*].id
#     security_group_ids      = [aws_security_group.eks.id]
#     endpoint_private_access = true
#     endpoint_public_access  = true
#   }
#
#   enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
#
#   tags = local.common_tags
# }
#
# resource "aws_eks_node_group" "main" {
#   cluster_name    = aws_eks_cluster.main.name
#   node_group_name = "${local.name_prefix}-nodes"
#   node_role_arn   = aws_iam_role.eks_nodes.arn
#   subnet_ids      = aws_subnet.private[*].id
#
#   scaling_config {
#     desired_size = 2
#     max_size     = 4
#     min_size     = 1
#   }
#
#   instance_types = ["t3.medium"]
#
#   labels = {
#     Environment = var.environment
#   }
#
#   tags = local.common_tags
# }

# =============================================================================
# OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "EC2 instance public IPs"
  value       = aws_instance.web[*].public_ip
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = aws_lb.main.zone_id
}

output "database_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.mysql.endpoint
  sensitive   = true
}

output "s3_website_url" {
  description = "S3 website URL"
  value       = "http://${aws_s3_bucket.website.id}.s3-website-${data.aws_region.current.name}.amazonaws.com"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].id : null
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].domain_name : null
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.example.function_name
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.main.id
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.notifications.arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "key_name" {
  description = "EC2 key pair name"
  value       = aws_key_pair.generated.key_name
}

output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.main.id
}

output "secret_manager_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.database.arn
  sensitive   = true
}

# =============================================================================
# END OF TERRAFORM AWS FILE
# =============================================================================
