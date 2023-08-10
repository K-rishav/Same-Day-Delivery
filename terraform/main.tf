terraform {
  required_version = ">= 0.14.0"
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.42.0"
    }
     mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.10.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Configure the MongoDB Atlas Provider 
provider "mongodbatlas" {
  public_key  = var.mongodbatlas_public_key
  private_key = var.mongodbatlas_private_key
}


# resource "confluent_environment" "staging" {
#   display_name = "Staging"
# }

data "confluent_environment" "staging" {
  id = "env-prp8zm"
}

# Stream Governance and Kafka clusters can be in different regions as well as different cloud providers,
# but you should to place both in the same cloud and region to restrict the fault isolation boundary.
data "confluent_schema_registry_region" "essentials" {
  cloud   = "AWS"
  region  = "us-east-1"
  package = "ADVANCED"
}

resource "confluent_schema_registry_cluster" "essentials" {
  package = data.confluent_schema_registry_region.essentials.package

  environment {
    id = data.confluent_environment.staging.id
  }

  region {
    # See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
    id = data.confluent_schema_registry_region.essentials.id
  }
}

# Update the config to use a cloud provider and region of your choice.
# https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster
resource "confluent_kafka_cluster" "basic" {
  display_name = "inventory"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-1"
  basic {}
  environment {
    id = data.confluent_environment.staging.id
  }
}

resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name    = "orders"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

// 'app-manager' service account is required in this configuration to create 'orders' topic and grant ACLs
// to 'app-producer' and 'app-consumer' service accounts.
resource "confluent_service_account" "app-manager" {
  display_name = "app-manager"
  description  = "Service account to manage 'inventory' Kafka cluster"
}

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.basic.rbac_crn
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_environment.staging.id
    }
  }

  # The goal is to ensure that confluent_role_binding.app-manager-kafka-cluster-admin is created before
  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
  # confluent_kafka_topic, confluent_kafka_acl resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.app-manager-kafka-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_kafka_topic, confluent_kafka_acl resources instead.
  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}

resource "confluent_service_account" "app-consumer" {
  display_name = "app-consumer"
  description  = "Service account to consume from 'orders' topic of 'inventory' Kafka cluster"
}

resource "confluent_service_account" "app-connector" {
  display_name = "app-connector"
  description  = "Service account of mongo db Source Connector to consume from 'orders' topic of 'inventory' Kafka cluster"
}

resource "confluent_api_key" "app-consumer-kafka-api-key" {
  display_name = "app-consumer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-consumer' service account"
  owner {
    id          = confluent_service_account.app-consumer.id
    api_version = confluent_service_account.app-consumer.api_version
    kind        = confluent_service_account.app-consumer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_environment.staging.id
    }
  }
}

resource "confluent_service_account" "app-producer" {
  display_name = "app-producer"
  description  = "Service account to produce to 'orders' topic of 'inventory' Kafka cluster"
}

resource "confluent_api_key" "app-producer-kafka-api-key" {
  display_name = "app-producer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-producer' service account"
  owner {
    id          = confluent_service_account.app-producer.id
    api_version = confluent_service_account.app-producer.api_version
    kind        = confluent_service_account.app-producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_environment.staging.id
    }
  }
}


resource "confluent_kafka_acl" "app-connector-describe-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-connector.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-create-on-prefix-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "${local.topic_prefix}"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connector.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-write-on-prefix-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "${local.topic_prefix}"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connector.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-create-on-data-preview-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "data-preview.${local.database}.${local.collection}"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-connector.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-write-on-data-preview-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "data-preview.${local.database}.${local.collection}"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-connector.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}


# ------------------------------- mongodb -------------------------------# ------------------------------- mongodb -------------------------------
# Create a Project
resource "mongodbatlas_project" "atlas-project" {
  org_id = var.mongodbatlas_org_id
  name   = var.mongodbatlas_project_name
}

# Create MongoDB Atlas resources
resource "mongodbatlas_cluster" "demo-database-sameday" {
  project_id = mongodbatlas_project.atlas-project.id
  name       = "demo-db-sameday"

  # Provider Settings "block"
  provider_instance_size_name = "M0"
  provider_name               = "TENANT"
  backing_provider_name       = "AWS"
  provider_region_name        = var.mongodbatlas_region
}

resource "mongodbatlas_project_ip_access_list" "demo-database-sameday-ip" {
  project_id = mongodbatlas_project.atlas-project.id
  cidr_block = "0.0.0.0/0"
  comment    = "Allow connections from anywhere for demo purposes"
}

# Create a MongoDB Atlas Admin Database User
resource "mongodbatlas_database_user" "demo-database-sameday-db-user" {
  username           = var.mongodbatlas_database_username
  password           = var.mongodbatlas_database_password
  project_id         = mongodbatlas_project.atlas-project.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }
}

# ------------------------------- mongodb -------------------------------# ------------------------------- mongodb -------------------------------
resource "confluent_connector" "mongo-db-source" {
  environment {
    id = data.confluent_environment.staging.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  // Block for custom *sensitive* configuration properties that are labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-source.html#configuration-properties
  config_sensitive = {
    "connection.password" = var.mongodbatlas_database_password,
  }

  // Block for custom *nonsensitive* configuration properties that are *not* labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-source.html#configuration-properties
  config_nonsensitive = {
    "connector.class" = "MongoDbAtlasSource"
    "name" = "confluent-mongodb-source"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.app-connector.id
    "connection.host" = local.connection_host
    "connection.user" = local.connection_user
    "topic.prefix" = local.topic_prefix
    "database" = local.database
    "collection" = local.collection
    "poll.await.time.ms" = "5000"
    "poll.max.batch.size" = "1000"
    "copy.existing" = "true"
    "output.data.format" = "JSON"
    "tasks.max" = "1"
  }

  depends_on = [
    confluent_kafka_acl.app-connector-describe-on-cluster,
    confluent_kafka_acl.app-connector-create-on-prefix-topics,
    confluent_kafka_acl.app-connector-write-on-prefix-topics,
    confluent_kafka_acl.app-connector-create-on-data-preview-topics,
    confluent_kafka_acl.app-connector-write-on-data-preview-topics,
    mongodbatlas_database_user.demo-database-sameday-db-user,
  ]
}

locals {
  topic_prefix = "sample_topic_prefix"
  database = "sample_anlaytics"
  collection = "accounts"
  connection_host = replace(mongodbatlas_cluster.demo-database-sameday.connection_strings[0].standard_srv,"mongodb+srv://", "")
  connection_user = var.mongodbatlas_database_username
}

output "mongo-cluster-url1"{
    value = replace(mongodbatlas_cluster.demo-database-sameday.connection_strings[0].standard_srv,"mongodb+srv://", "")
}