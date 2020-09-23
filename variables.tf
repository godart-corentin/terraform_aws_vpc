variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_name" {
  type        = string
  description = "name of vpc"
}

variable "cidr_block" {
  type = string
  default = "172.21.0.0/16"
  description = "cidr block"
}

variable "environement" {
  type = string
  default = "dev"
  description = "environnement"
}

variable "azs" {
  type = map(any)
  description = "Map of AZs avec leurs index"
  default = {
    "a" = 0,
    "b" = 1,
    "c" = 2
  }
}

variable "public_key" {
  type = string
  description = "Public Key"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgb4KJX+Rtdm4rfAllGeviFxt1ONlj8zwbHaaoCIbpBr52re3xT1LND/tiQyool0qL9iZQIjd89//EPXNzlvNPXM+XJhN5A2zgTmHanAoJt+6N6LDJRCUYfRI9ooJzkWsraB7IqAPe1/lxb8OH0LZjS+OYoGn/0zVzlEeKZlSJSSf+GF98AHKcWxvUVpU/E++Q7fmsHdCCYDzxf6SGpUzgVC+WiIJN/u+c2uAIF0ZJ/mdgBZhOi85ISuVfnXeYKvxVfZry7jsLjVCJrLOBBdWCY5twHgsCdjKWDqkfVRVNoam/2e+QKsJnyxg8ajlYLVrQCiIXgf9S6KjMc4VtvOqP"
}

variable "instance" {
  type = string
  description = "Instance type"
  default="t2.micro"
}