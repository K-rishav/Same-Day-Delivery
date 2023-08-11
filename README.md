# Azure HD Insights to Confluent Cloud - Transactional and Analytics

In today's fast-paced business environment, companies rely heavily on technology to streamline their operations and stay ahead of the competition. One such company, ABC grocery delivery, faced several challenges with their Kafka implementation on Azure HDInsights, including a lack of expertise and operational knowledge to maintain their Kafka environment. To overcome these challenges and ensure high availability and reliability for their core operations, they decided to migrate to Confluent Cloud, a managed Kafka solution that offers several features to support their business needs.
This demo walks you through data pipeline where data originates from Mongodb , stored in confluent cloud and sinked to databricks .

## Architecture Diagram

<div align="center"> 
  <img src="images/Architecture.png" width =100% heigth=100%>
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
    > **Note:** Read the `main.tf` configuration file [to see what will be created](./terraform/main.tf).
1. Load the sample dataset in Mongodb database that is just created using terraform.
   
   <div align="center"> 
   <img src="images/load_sample_dataset.png" width =100% heigth=100%>
   </div> 

Hurray! Mongodb data is offloaded to Confluent topic. Thanks to Mongo Atlas Source Connector. Now let's setup Databricks Sink Connector.

---

## Connect Databricks Sink to Confluent Cloud

You can create the Databricks Sink connector either through CLI or Confluent Cloud web UI.

<details>
    <summary><b>CLI</b></summary>

1. Run the following command to create the MongoDB Atlas Sink connector.

   ```bash
   confluent connect cluster create --config-file confluent/actual_databricks_sink.json
   ```

</details>
<br>

<details>
    <summary><b>Confluent Cloud Web UI</b></summary>

1. On the navigation menu, select **Connectors** and **+ Add connector**.
1. In the search bar search for **Databricks** and select the **Databricks delta lake Sink** which is a fully-managed connector.
1. Create a new Databricks delta lake Sink connector and complete the required fields using `actual_databricks_sink.json` file.

</details>
<br>

Once the connector is in **Running** state navigate to Databricks page and verify messages are showing up correctly.

Refer to our [documentation](https://docs.confluent.io/cloud/current/connectors/cc-databricks-delta-lake-sink/cc-databricks-delta-lake-sink.html) for detailed instructions about this connector.

## Confluent Cloud Stream Governance

Confluent offers data governance tools such as Stream Quality, Stream Catalog, and Stream Lineage in a package called Stream Governance. These features ensure your data is high quality, observable and discoverable. Learn more about **Stream Governance** [here](https://www.confluent.io/product/stream-governance/) and refer to the [docs](https://docs.confluent.io/cloud/current/stream-governance/overview.html) page for detailed information.

1.  Navigate to https://confluent.cloud
1.  Use the left hand-side menu and click on **Stream Lineage**.
    Stream lineage provides a graphical UI of the end to end flow of your data. Both from the a bird’s eye view and drill-down magnification for answering questions like:

    - Where did data come from?
    - Where is it going?
    - Where, when, and how was it transformed?

    In the bird's eye view you see how one stream feeds into another one. As your pipeline grows and becomes more complex, you can use Stream lineage to debug and see where things go wrong and break.

---
## CONGRATULATIONS

Congratulations on building your streaming data pipelines for streaming data to cloud databases in Confluent Cloud! Your complete pipeline should resemble the following one.

### TODO Add the stream lineage ss

# Teardown

You want to delete any resources that were created during the demo so you don't incur additional charges.

   ```bash
   terraform destroy
   ```

# References

1. Peering Connections in Confluent Cloud [doc](https://docs.confluent.io/cloud/current/networking/peering/index.html)
2. MongoDB Atlas Sink Connector for Confluent Cloud [doc](https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink.html)
3. Databricks deltalake [page](https://docs.confluent.io/cloud/current/connectors/cc-databricks-delta-lake-sink/cc-databricks-delta-lake-sink.html) 
