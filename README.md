# Terraform infra for prometheus alertmanager and grafana
Docker hosts and containers monitoring with Prometheus, Grafana, custum node exporter and AlertManager

[![open-issues](https://img.shields.io/github/issues-raw/ghalwash/terransible-aws-ec2-prometheus?style=for-the-badge)](https://github.com/ghalwash/terransible-aws-ec2-prometheus/issues)
[![open-pr](https://img.shields.io/github/issues-pr-raw/ghalwash/terransible-aws-ec2-prometheus?style=for-the-badge)](https://github.com/ghalwash/terransible-aws-ec2-prometheus/pulls)

## Features
This module contains sample Terraform configurations and automation scripts that can be used to create two aws instances in the same VPC with one security group. The First server uses [dockprom](https://github.com/stefanprodan/dockprom) to run prometheus, grafana and alertmanager on docker containers. The second is a monitoring hub to extract icon-network metrics using custumized [icon-exporter](https://github.com/ghalwash/icon-prometheus-exporter) of different nodes. 

## Terraform Versions

For Terraform v0.12.0+

## Infrastructure
![GitHub Logo](https://github.com/ghalwash/terransible-aws-ec2-prometheus/blob/master/Infra.PNG)

## Quick start

Note: These examples deploy resources into your AWS account. The used resources need to be changed if you want to go with  free tire servers.

    Install Terraform.
    Set your AWS credentials as the environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
    cd into one of the example folders.
    Run terraform init.
    Run terraform apply.
    To clean up and delete all resources after you're done, run terraform destroy.


`
## Examples

- [defaults](https://github.com/ghalwash/terransible-aws-ec2-prometheus/tree/master/examples/defaults)

## Setup CLUSTER
(1 nodes) EC2 nodes m4.large ( 3 docker Container running Prometheus, AlertManager and grafana) 
(2 node) EC2 nodes m4.large monitoring hub

## Testing
This module has been packaged with terratest tests

To run them:

1. Install Go
2. Run `make test-init` from the root of this repo
3. Run `make test` again from root

## Authors

Module managed by [ghalwash](https://github.com/ghalwash)

## Credits

- [Anton Babenko](https://github.com/antonbabenko)
- [Stefan Prodan](https://github.com/stefanprodan)


## License

Apache 2 Licensed. See LICENSE for full details.# terransible-aws-ec2-prometheus
