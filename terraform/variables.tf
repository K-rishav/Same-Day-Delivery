variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}
variable "mongodbatlas_public_key" {
  description = "The public API key for MongoDB Atlas"
  type        = string
}

variable "mongodbatlas_private_key" {
  description = "The private API key for MongoDB Atlas"
  type        = string
}

# Atlas Organization ID 
variable "mongodbatlas_org_id" {
  type        = string
  description = "MongoDB Atlas Organization ID"
}

# Atlas Project Name
variable "mongodbatlas_project_name" {
  type        = string
  description = "MongoDB Atlas Project Name"
}

variable "mongodbatlas_region" {
  description = "MongoDB Atlas region https://www.mongodb.com/docs/atlas/reference/amazon-aws/#std-label-amazon-aws"
  type        = string
}

variable "mongodbatlas_database_username" {
  description = "MongoDB Atlas database username. You can change it through command line"
  type        = string
}

variable "mongodbatlas_database_password" {
  description = "MongoDB Atlas database password. You can change it through command line"
  type        = string
}

variable "mongodb_source_connector_topic_prefix" {
  description = "Your connector will publish to kafka topics using the prefix provided. The connector automatically creates Kafka topics using the naming convention: <prefix>.<database-name>.<collection-name>."
  type        = string
  default = "demo"
}

variable "mongodb_source_connector_database_name" {
  description = "MongoDB Atlas database name that needs to be watched by mongodb source connector"
  type        = string
  default = "sample_supplies"
}
variable "mongodb_source_connector_collection" {
  description = "MongoDB Atlas collection name that needs to be watched by mongodb source connector"
  type        = string
  default = "sales"
}

variable "region" {
  default     = "us-east-2"
  description = "AWS region"
}

variable "db_password" {
  description = "RDS root user password"
  default = "admin123"
  sensitive   = true
}