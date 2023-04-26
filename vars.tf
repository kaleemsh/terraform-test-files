# variables for subnets
variable "subnet-1a" {
  type = string
  default = "ap-south-1a"
  
}

variable "subnet-1a-cidr-block" {
  type = string
  default = "10.10.1.0/24"
  
}


# variables for instances
variable "ami" {
  type = string
  default = "ami-052cb5e834ea3eece"
  
}

variable "instance-type" {
  type = string
  default = "t2.micro"
  
}

variable "key-name" {
  type = string
  default = "central ansible"
  
}

# variable for multiple instances
variable "desired-machine-count" {
    type = string
    default = "1"
  
}


