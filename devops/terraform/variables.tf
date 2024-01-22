variable "token" {}
variable "authorized_keys" {}
variable "root_pass" {}
variable "region" {
  default = "us-east"
}
variable "group" {
  default = "my-kafka-client"
}