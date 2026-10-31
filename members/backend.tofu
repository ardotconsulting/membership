# Backend Configuration
# https://opentofu.org/docs/language/settings/backends/s3/

terraform {
  backend "s3" {
    bucket       = "ardotconsulting-tofu-state"
    key          = "members/tfstate.json"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}