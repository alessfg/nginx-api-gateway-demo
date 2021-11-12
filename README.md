# NGINX API Gateway Demo

## Overview

This demo uses Terraform to automate the setup of an NGINX Plus (and NGINX App Protect WAF) API gateway pseudo-production environment that includes a mock API backend database.

## Requirements

### Terraform

This demo has been developed and tested with Terraform `0.13`.

Instructions on how to install Terraform can be found in the [Terraform website](https://www.terraform.io/downloads.html).

### NGINX Plus & NGINX App Protect WAF

You will need to download the NGINX Plus (including NGINX App Protect WAF) license to a known location. You can specify the location of the license in the corresponding Terraform variables.

### AWS R53

You will need to create R53 hosted zone beforehand. You can specify the R53 hosted zone `id` as well as a FQDN for the NGINX Plus API gateway and backend API in the corresponding Terraform variables.

## Deployment

To use the provided Terraform scripts, you need to:

1. Export your AWS credentials as environment variables (or alternatively, tweak the AWS provider in [`provider.tf`](provider.tf)).
2. Set up default values for variables missing a value in [`variables.tf`](variables.tf) (you can find example values commented out in the file). Alternatively, you can input those variables at runtime.

Once you have configured your Terraform environment, you can either:

* Run [`./setup.sh`](setup.sh) to initialize the AWS Terraform provider and start a Terraform deployment on AWS.
* Run `terraform init` and `terraform apply`.

And finally, once you are done playing with NGINX Controller, you can destroy the AWS infrastructure by either:

* Run [`./cleanup.sh`](cleanup.sh) to destroy your Terraform deployment.
* Run `terraform destroy`.

## Demo Overview

You will find a series of NGINX configuration files in the `api_gateway_files` folder. The folder is divided into individual steps, meant to be copied into their respective directory in order. By default, the folder is uploaded to your NGINX API gateway instance. To then copy each step's configuration files, run `sudo cp -r api_gateway_files/step_<number>/* /etc/nginx`.

* Step 1 -- Defines the entry point of the NGINX API gateway
* Step 2 -- Defines default JSON error codes
* Step 3 -- Defines the API endpoints
* Step 4 -- Enables rate limiting
* Step 5 -- Sets up API Key authentication
* Step 6 -- Sets up JWT authentication
* Step 7 -- Sets up JSON body validation (using NJS)
* Step 8 -- Sets up NGINX App Protect WAF protection using an open API spec file.

## Author Information

[Alessandro Fael Garcia](https://github.com/alessfg)
