terraform {
    backend "s3" {
    bucket = "tfstate-1231231412312-hr"
    key    = "dev/terraform.tfstate"
    region = "us-west-2"
  }
}