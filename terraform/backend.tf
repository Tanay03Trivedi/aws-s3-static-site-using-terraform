terraform {
  backend "s3" {
    bucket = "tf-remote-backend-tanay"
    key    = "global/terrafrom-s3-site-tanay/terraform.tfstate"
    region = "ap-south-1"
  }
}
