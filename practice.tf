# =============================================================================
# PRACTICE TERRAFORM AWS - FILL IN THE BLANKS
# =============================================================================
# Hãy điền vào các chỗ trống (________) để hoàn thành Terraform configuration
# Gợi ý: Xem learn.tf để tìm câu trả lời
# =============================================================================

________ {                                  // <-- TODO: Khai báo terraform block
  required_version = ">= ________"          // <-- TODO: 1.0
  required_providers {
    aws = {
      source  = "hashicorp/______"          // <-- TODO: aws
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.______"  // <-- TODO: tfstate
    region         = "us-east-1"
    encrypt        = ________                // <-- TODO: true
    dynamodb_table = "terraform-locks"
  }
}

// =============================================================================
// PROVIDER
// =============================================================================

provider "______" {                        // <-- TODO: aws
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "______"                // <-- TODO: Terraform
    }
  }
}

// Additional region provider
provider "aws" {
  alias  = "us_west_2"
  region = "us-______"                       // <-- TODO: west-2
}

// =============================================================================
// VARIABLES
// =============================================================================

variable "aws_region" {
  description = "AWS ________"              // <-- TODO: region
  type        = ________                    // <-- TODO: string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(______)               // <-- TODO: string
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "______"                    // <-- TODO: 10.0.0.0/16
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/____", "10.0.2.0/24", "10.0.3.0/24"]  // <-- TODO: 24
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.10.0/24", "______", "10.0.12.0/24"]  // <-- TODO: 10.0.11.0/24
}

variable "database_subnet_cidrs" {
  description = "Database subnet CIDRs"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.____/24"]  // <-- TODO: 21
}

// =============================================================================
// LOCALS
// =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.______}"  // <-- TODO: environment

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  selected_azs = slice(var.availability_zones, ____, 2)  // <-- TODO: 0
}

// =============================================================================
// DATA SOURCES
// =============================================================================

data "aws_caller_identity" "______" {}     // <-- TODO: current

data "aws_region" "current" {}

data "aws_ami" "amazon_linux_2023" {
  most_recent = ________                   // <-- TODO: true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-______"]  // <-- TODO: x86_64
  }

  filter {
    name   = "virtualization-______"        // <-- TODO: type
    values = ["hvm"]
  }
}

// =============================================================================
// SECTION 1: VPC
// =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = ________            // <-- TODO: true
  enable_dns_support   = true

  tags = ________(                             // <-- TODO: merge
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
}

// =============================================================================
// SECTION 2: INTERNET GATEWAY
// =============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.______               // <-- TODO: id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-______"    // <-- TODO: igw
    }
  )
}

// =============================================================================
// SECTION 3: SUBNETS
// =============================================================================

// Public subnets
resource "aws_subnet" "public" {
  count                   = length(local.selected_azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.______]  // <-- TODO: index
  availability_zone       = local.selected_azs[count.index]
  map_public_ip_on_launch = ________         // <-- TODO: true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-${count.index + 1}"
      Type = "______"                          // <-- TODO: public
    }
  )
}

// Private subnets
resource "aws_subnet" "private" {
  count             = length(local.selected_azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.selected_azs[count.______]  // <-- TODO: index

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-${count.index + 1}"
      Type = "private"
    }
  )
}

// Database subnets
resource "aws_subnet" "database" {
  count             = length(local.selected_azs)
  vpc_id            = aws_vpc.main.______     // <-- TODO: id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = local.selected_azs[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-database-${count.index + 1}"
      Type = "______"                          // <-- TODO: database
    }
  )
}

// =============================================================================
// SECTION 4: NAT GATEWAY
// =============================================================================

// Elastic IP
resource "aws_eip" "nat" {
  count  = length(local.selected_azs)
  domain = "______"                            // <-- TODO: vpc

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

// NAT Gateway
resource "aws_nat_gateway" "main" {
  count         = length(local.selected_azs)
  allocation_id = aws_eip.nat[count.index].______  // <-- TODO: id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-gw-${count.index + 1}"
    }
  )
}

// =============================================================================
// SECTION 5: ROUTE TABLES
// =============================================================================

// Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/____"              // <-- TODO: 0
    gateway_id = aws_internet_gateway.main.______  // <-- TODO: id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-rt"
    }
  )
}

// Private route tables
resource "aws_route_table" "private" {
  count  = length(local.selected_azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.______].id  // <-- TODO: index
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-rt-${count.index + 1}"
    }
  )
}

// Route table associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.______  // <-- TODO: id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.______)    // <-- TODO: private
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

// =============================================================================
// SECTION 6: SECURITY GROUPS
// =============================================================================

// Web security group
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security group for ________"    // <-- TODO: web servers
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = ____
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/______"]            // <-- TODO: 0
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = ____
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

// Application security group
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Security group for application servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from web servers only"
    from_port       = ____
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.______]  // <-- TODO: id
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/______"]            // <-- TODO: 0
  }

  tags = local.common_tags
}

// Database security group
resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database-sg"
  description = "Security group for databases"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from app servers"
    from_port       = ____
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = ____
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = local.common_tags
}

// =============================================================================
// SECTION 7: EC2 INSTANCES
// =============================================================================

resource "aws_instance" "web" {
  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux_2023.______  // <-- TODO: id
  instance_type          = var.instance_types[var.environment]
  subnet_id              = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids = [aws_security_group.web.______]  // <-- TODO: id

  user_data = <<-______                        // <-- TODO: EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
  EOF

  root_block_device {
    volume_type           = "______"           // <-- TODO: gp3
    volume_size           = 20
    delete_on_termination = true
    encrypted             = ________            // <-- TODO: true
  }

  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_type           = "gp3"
    volume_size           = ____
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "______"      // <-- TODO: required
    http_put_response_hop_limit = 1
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-web-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

// =============================================================================
// SECTION 8: KEY PAIR
// =============================================================================

resource "tls_private_key" "generated" {
  algorithm = "______"                          // <-- TODO: RSA
  rsa_bits  = ____
}

resource "aws_key_pair" "generated" {
  key_name   = "${local.name_prefix}-keypair"
  public_key = tls_private_key.generated.public_keyopenssh  // <-- TODO: _openssh

  tags = local.common_tags
}

// =============================================================================
// SECTION 9: LOAD BALANCER (ALB)
// =============================================================================

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = ________                // <-- TODO: false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].______  // <-- TODO: id

  enable_deletion_protection = false
  enable_http_two            = ________        // <-- TODO: true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb"
    }
  )
}

// Target group
resource "aws_lb_target_group" "web" {
  name        = "${local.name_prefix}-tg"
  port        = ____
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "______"                      // <-- TODO: instance

  health_check {
    enabled             = ________            // <-- TODO: true
    healthy_threshold   = 2
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = local.common_tags
}

// Attach instances
resource "aws_lb_target_group_attachment" "web" {
  count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.web.______  // <-- TODO: arn
  target_id        = aws_instance.web[count.index].id
  port             = ____
}

// Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.______      // <-- TODO: arn
  port              = 80
  protocol          = "______"                  // <-- TODO: HTTP

  default_action {
    type = "______"                            // <-- TODO: redirect
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

// =============================================================================
// SECTION 10: AUTO SCALING GROUP
// =============================================================================

resource "aws_launch_template" "web" {
  name_prefix   = "${local.name_prefix}-web-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_types[var.environment]

  key_name   = aws_key_pair.generated.______  // <-- TODO: key_name
  monitoring  = ________                       // <-- TODO: true

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web.id]
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Auto-scaled Instance</h1>" > /var/www/html/index.html
  EOF
}

resource "aws_autoscaling_group" "web" {
  desired_capacity    = ____
  max_size            = 5
  min_size            = 1
  vpc_zone_identifier = aws_subnet.public[*].______  // <-- TODO: id

  target_group_arns = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$______"                        // <-- TODO: Latest
  }

  tags = local.common_tags
}

// =============================================================================
// SECTION 11: S3 BUCKETS
// =============================================================================

resource "aws_s3_bucket" "website" {
  bucket = "${local.name_prefix}-______"        // <-- TODO: website

  tags = local.common_tags
}

// Website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "______."                          // <-- TODO: index.html
  }

  error_document {
    key = "error.______"                        // <-- TODO: html
  }
}

// Bucket versioning
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "______"                           // <-- TODO: Enabled
  }
}

// Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "______"                  // <-- TODO: AES256
    }
  }
}

// Bucket policy
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-______"                  // <-- TODO: 17
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:______"                // <-- TODO: GetObject
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
    ]
  })
}

// =============================================================================
// SECTION 12: RDS DATABASE
// =============================================================================

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].______  // <-- TODO: id

  tags = local.common_tags
}

resource "aws_db_instance" "mysql" {
  identifier           = "${local.name_prefix}-mysql"
  engine               = "______"                // <-- TODO: mysql
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_encrypted    = true

  db_name  = "myapp"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = var.environment == "prod" ? __ : 7  // <-- TODO: 30

  tags = local.common_tags
}

// =============================================================================
// SECTION 13: ELASTICACHE (REDIS)
// =============================================================================

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-cache-subnet"
  subnet_ids = aws_subnet.____[*].id         // <-- TODO: private

  tags = local.common_tags
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${local.name_prefix}-redis"
  node_type                     = "cache.t3.micro"
  number_cache_clusters         = length(local.selected_azs)
  subnet_group_name             = aws_elasticache_subnet_group.main.name
  security_group_ids            = [aws_security_group.app.id]

  automatic_failover_enabled = ________       // <-- TODO: true
  port           = ____
  engine         = "redis"
  engine_version = "7.0"

  tags = local.common_tags
}

// =============================================================================
// SECTION 14: DYNAMODB
// =============================================================================

resource "aws_dynamodb_table" "users" {
  name           = "${local.name_prefix}-users"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = ____
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "______"                            // <-- TODO: S
  }

  global_secondary_index {
    name            = "UserNameIndex"
    hash_key        = "UserName"
    projection_type = "ALL"
    read_capacity   = 2
    write_capacity  = 2
  }

  point_in_time_recovery {
    enabled = ________                         // <-- TODO: true
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.common_tags
}

// =============================================================================
// SECTION 15: LAMBDA FUNCTIONS
// =============================================================================

resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.______"   // <-- TODO: com
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_lambda_function" "example" {
  function_name = "${local.name_prefix}-lambda"
  role          = aws_iam_role.lambda.______    // <-- TODO: arn
  runtime       = "python3.11"
  handler       = "index.lambda_handler"
  timeout       = ____
  memory_size   = 256

  filename = "lambda_function_payload.zip"

  source_code_hash = filebase64______("lambda_function_payload.zip")  // <-- TODO: sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = "______"                    // <-- TODO: INFO
    }
  }

  tags = local.common_tags
}

// =============================================================================
// SECTION 16: API GATEWAY
// =============================================================================

resource "aws_apigatewayv2_api" "main" {
  name          = "${local.name_prefix}-api"
  protocol_type = "______"                      // <-- TODO: HTTP

  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.example.______  // <-- TODO: arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "example" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /______"                      // <-- TODO: example
  target   = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

// =============================================================================
// SECTION 17: SQS QUEUES
// =============================================================================

resource "aws_sqs_queue" "main" {
  name                      = "${local.name_prefix}-queue"
  message_retention_seconds = ____
  max_message_size           = 256000
  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.______  // <-- TODO: arn
    maxReceiveCount     = 5
  })

  tags = local.common_tags
}

// Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name = "${local.name_prefix}-______"           // <-- TODO: dlq

  tags = local.common_tags
}

// =============================================================================
// SECTION 18: SNS TOPICS
// =============================================================================

resource "aws_sns_topic" "notifications" {
  name = "${local.name_prefix}-______"           // <-- TODO: notifications

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notifications.id
  protocol  = "______"                           // <-- TODO: email
  endpoint  = var.notification_email
}

// =============================================================================
// SECTION 19: CLOUDFRONT
// =============================================================================

resource "aws_cloudfront_distribution" "main" {
  count = var.enable_cloudfront ? __ : 0        // <-- TODO: 1

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "${local.name_prefix}-s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main[0].cloudfront_access_identity_path
    }
  }

  enabled             = ________                // <-- TODO: true
  is_ipv6_enabled     = true
  default_root_object = "index.______"           // <-- TODO: html

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "______"]         // <-- TODO: HEAD
    target_origin_id = "${local.name_prefix}-s3-origin"

    viewer_protocol_policy = "______-to-https"   // <-- TODO: redirect
    compress               = ________            // <-- TODO: true
  }

  tags = local.common_tags
}

// =============================================================================
// SECTION 20: ROUTE53
// =============================================================================

resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = local.common_tags
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "__"                                // <-- TODO: A

  alias {
    name                   = aws_cloudfront_distribution.main[0].domain_name
    zone_id                = aws_cloudfront_distribution.main[0].hosted_zone_id
    evaluate_target_health = ________           // <-- TODO: true
  }
}

// =============================================================================
// SECTION 21: CLOUDWATCH
// =============================================================================

resource "aws_cloudwatch_log_group" "application" {
  name              = "${local.name_prefix}-application"
  retention_in_days = var.environment == "prod" ? 30 : __

  tags = local.common_tags
}

resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${local.name_prefix}-error-metric"
  log_group_name = aws_cloudwatch_log_group.application.______

  pattern        = "[timestamp=* level=ERROR*, timestamp=* level=ERROR]"
  metric_transformation {
    name      = "ErrorCount"
    namespace = "${local.name_prefix}"
    value     = "__"
  }
}

// =============================================================================
// SECTION 22: KMS
// =============================================================================

resource "aws_kms_key" "main" {
  description             = "${local.name_prefix} KMS key"
  deletion_window_in_days = ____
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.main.key_id
}

// =============================================================================
// SECTION 23: SECRETS MANAGER
// =============================================================================

resource "aws_secretsmanager_secret" "database" {
  name = "${local.name_prefix}/______"          // <-- TODO: database

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

// =============================================================================
// SECTION 24: PARAMETER STORE
// =============================================================================

resource "aws_ssm_parameter" "app_config" {
  name  = "/${local.name_prefix}/app/config"
  type  = "______"                              // <-- TODO: String
  value = jsonencode({
    environment = var.environment
    log_level    = "INFO"
  })

  tags = local.common_tags
}

// =============================================================================
// SECTION 25: ECS
// =============================================================================

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-ecs"

  setting {
    name  = "containerInsights"
    value = "______"                             // <-- TODO: enabled
  }

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["______"]         // <-- TODO: FARGATE
  cpu                      = 512
  memory                   = ____

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = ________                       // <-- TODO: true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "______"                     // <-- TODO: FARGATE

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = ________                  // <-- TODO: false
  }

  tags = local.common_tags
}

resource "aws_ecr_repository" "app" {
  name                 = "${local.name_prefix}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = ________                     // <-- TODO: true
  }

  tags = local.common_tags
}

// =============================================================================
// OUTPUTS
// =============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].______    // <-- TODO: id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.web[*].______    // <-- TODO: id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.______            // <-- TODO: dns_name
}

output "database_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.mysql.endpoint
  sensitive   = ________                        // <-- TODO: true
}

output "s3_website_url" {
  description = "S3 website URL"
  value       = "http://${aws_s3_bucket.website.id}.s3-website-${data.aws_region.current.name}.amazonaws.com"
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.main[0].domain_name : ________
                                            // <-- TODO: null
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.example.______
                                        // <-- TODO: function_name
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.main.id
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.notifications.______
                                            // <-- TODO: arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
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

// =============================================================================
// CHECKLIST - ĐÁNH DẤU X KHI HOÀN THÀNH
// =============================================================================
// [ ] Terraform block
// [ ] Provider (multi-region)
// [ ] Variables (AWS-specific)
// [ ] Locals
// [ ] Data sources (caller_identity, region, AMI)
// [ ] VPC
// [ ] Internet Gateway
// [ ] Subnets (public, private, database)
// [ ] NAT Gateway (EIP, NAT Gateway)
// [ ] Route Tables (public, private, associations)
// [ ] Security Groups (web, app, database)
// [ ] EC2 Instances (with EBS, metadata options)
// [ ] Key Pair (TLS)
// [ ] Load Balancer (ALB, target group, listener)
// [ ] Auto Scaling Group (launch template, ASG, policies)
// [ ] S3 Buckets (website, versioning, encryption, policy)
// [ ] RDS (MySQL, subnet group)
// [ ] ElastiCache (Redis)
// [ ] DynamoDB (table, GSI, encryption)
// [ ] Lambda (function, IAM role, log group)
// [ ] API Gateway (API, integration, route)
// [ ] SQS Queues (main + DLQ)
// [ ] SNS Topics (topic + subscriptions)
// [ ] CloudFront (distribution, OAI)
// [ ] Route53 (zone + records)
// [ ] CloudWatch (log group, metric filter)
// [ ] KMS (key + alias)
// [ ] Secrets Manager (secret + version)
// [ ] Parameter Store (SSM parameter)
// [ ] ECS (cluster, task definition, service, ECR)
// [ ] Outputs
// =============================================================================
