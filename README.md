# Azure HD Insights to Confluent Cloud - Transactional and Analytics

In today's fast-paced business environment, companies rely heavily on technology to streamline their operations and stay ahead of the competition. One such company, ABC grocery delivery, faced several challenges with their Kafka implementation on Azure HDInsights, including a lack of expertise and operational knowledge to maintain their Kafka environment. To overcome these challenges and ensure high availability and reliability for their core operations, they decided to migrate to Confluent Cloud, a managed Kafka solution that offers several features to support their business needs.
This demo walks you through data pipeline where data originates from Mongodb , stored and transformed in confluent cloud and sinked in databricks .

## Architecture Diagram

<div align="center"> 
  <img src="images/Solution.png" width =100% heigth=100%>
</div>

---

# Requirements

In order to successfully complete this demo you need to install few tools before getting started.

- If you don't have a Confluent Cloud account, sign up for a free trial [here](https://www.confluent.io/confluent-cloud/tryfree).
- Install terraform by following the instructions [here](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

## Prerequisites

### Confluent Cloud

1. Sign up for a Confluent Cloud account [here](https://www.confluent.io/get-started/).
1. After verifying your email address, access Confluent Cloud sign-in by navigating [here](https://confluent.cloud).
1. When provided with the _username_ and _password_ prompts, fill in your credentials.

   > **Note:** If you're logging in for the first time you will see a wizard that will walk you through the some tutorials. Minimize this as you will walk through these steps in this guide.

1. Create Confluent Cloud API keys by following [this](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/guides/sample-project#summary) guide.
   > **Note:** This is different than Kafka cluster API keys.

### MongoDB Atlas

1. Sign up for a free MongoDB Atlas account [here](https://www.mongodb.com/).

1. Create an API key pair so Terraform can create resources in the Atlas cluster. Follow the instructions [here](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs#configure-atlas-programmatic-access).

### Databricks

1. Sign up for a free Databricks account [here](https://www.databricks.com/).

## Setup

1. This demo uses Terraform to spin up resources that are needed.

1. Clone and enter this repository.

   ```bash
   git clone https://github.com/K-rishav/Same-Day-Delivery.git
   cd Same-Day-Delivery
   ``` 

1. Edit the setup.properties file to manage all the values you'll need through the setup

1. Source the setup.properties file 

   ```bash
   source setup.properties
   ``` 

### Build your cloud infrastructure

1. Navigate to the repo's terraform directory.
   ```bash
   cd terraform
   ```
1. Log into your AWS account through command line.

1. Initialize Terraform within the directory.
   ```bash
   terraform init
   ```
1. Create the Terraform plan.
   ```bash
   terraform plan
   ```
1. Apply the plan to create the infrastructure.

   ```bash
   terraform apply
   ```
1. Load the sample dataset in mongodb 

   > **Note:** Read the `main.tf` configuration file [to see what will be created](./terraform/main.tf).

---

## CONGRATULATIONS

# Teardown

You want to delete any resources that were created during the demo so you don't incur additional charges.

   ```bash
   terraform destroy
   ```

# References

1. Peering Connections in Confluent Cloud [doc](https://docs.confluent.io/cloud/current/networking/peering/index.html)
2. MongoDB Atlas Sink Connector for Confluent Cloud [doc](https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink.html)
3. Stream Governance [page](https://www.confluent.io/product/stream-governance/) and [doc](https://docs.confluent.io/cloud/current/stream-governance/overview.html)
