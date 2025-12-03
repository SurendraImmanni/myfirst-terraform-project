data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "my-terraform-files-131225"
    key    = "networking/terraform.tfstate"
    region = "ap-south-1"
  }
}
