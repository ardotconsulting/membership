# Backend Configuration
# https://opentofu.org/docs/language/settings/backends/s3/

terraform {
  backend "s3" {
    bucket       = "ardotconsulting-tfstate"
    key          = "repositories/tfstate.json"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}