terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      version = "2.5.2"
    }
  }
  backend "s3" {
      endpoints                   = {s3 = "https://us-east-1.linodeobjects.com"}
      bucket                      = "terraform-backend-testing"
      key                         = "kafka-ansible-terraform.tfstate"
      region                      = "us-east-1"
      shared_credentials_file     = "./s3-credentials"
      skip_s3_checksum            = true
      skip_credentials_validation = true
      skip_requesting_account_id  = true
  }
}

provider "linode" {
  token = var.token
}

resource "linode_instance" "kafka-client" {
        image = "linode/ubuntu20.04"
        label = "Kafka-Client"
        group = var.group
        region = var.region
        type = "g6-standard-1"
        swap_size = 1024
        authorized_keys = [var.authorized_keys]
        root_pass = var.root_pass
}

resource "linode_instance" "kafka-server" {
        image = "linode/ubuntu20.04"
        label = "Kafka-Server"
        group = var.group
        region = var.region
        type = "g6-standard-1"
        swap_size = 1024
        authorized_keys = [var.authorized_keys]
        root_pass = var.root_pass
}

resource "linode_instance" "elastic-search" {
        image = "linode/ubuntu20.04"
        label = "elastic-search"
        group = var.group
        region = var.region
        type = "g6-standard-6"
        swap_size = 1024
        authorized_keys = [var.authorized_keys]
        root_pass = var.root_pass
}

resource "local_file" "ansible_inventory" {
    content = templatefile("${local.templates_dir}/ansible-inventory.tpl", 
    { 
      kafkaclients=[for host in linode_instance.kafka-client.*: "${host.ip_address}"],
      kafkaservers=[for host in linode_instance.kafka-server.*: "${host.ip_address}"] 
      elasticsearch=[for host in linode_instance.elastic-search.*: "${host.ip_address}"] 
    })
    filename = "${local.root_dir}/../ansible/inventory.ini"
}

resource "linode_firewall" "kafka_firewall" {
  label = "kafka_firewall"

  inbound_policy = "ACCEPT"

  outbound {
    label    = "reject-http"
    action   = "DROP"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]
    ipv6     = ["::/0"]
  }

  outbound_policy = "ACCEPT"

  linodes = [linode_instance.kafka-client.id,linode_instance.kafka-server.id]
}

resource "linode_domain" "kafka_domain" {
    type = "master"
    domain = "linodekafkacicd.dev"
    soa_email = "admin@linodekafkacicd.dev"
}

resource "linode_domain_record" "kafka_server_domain_record" {
    domain_id = linode_domain.kafka_domain.id
    name = "server"
    record_type = "A"
    target = linode_instance.kafka-server.ip_address
    ttl_sec = 30
}

resource "linode_domain_record" "kafka_client_domain_record" {
    domain_id = linode_domain.kafka_domain.id
    name = "client"
    record_type = "A"
    target = linode_instance.kafka-client.ip_address
    ttl_sec = 30
}