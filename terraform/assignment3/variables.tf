 variable "aws_access_key" {
	default = "AKIAJUDGJSYMJNUK36WA" 
}
	
variable "aws_secret_key" {
	default = "XVCVOup0MFi9iH+h7NpqhSPYf1D2ruubeJo0/Lio"
}
	
variable "region" {
	default = "us-west-2" 
}
	
variable "aws_key_name" {
	default = "cit360"
}

variable "vpc_id" {
	description = "VPC ID for usage throughout the build process"
	default = "vpc-4813d72f"
}

variable "db_username" {
  description = "Username for DB"
  default = "username"
}

variable "db_password" {
  type = "string"
  description = "password for db"
  default = "password"
}

variable "vpc_cidr" {
  default = "172.16.0.0/16"
}
