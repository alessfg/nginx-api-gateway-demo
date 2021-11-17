# NGINX API Gateway Demo

## Overview

This demo uses Terraform to automate the setup of an NGINX Plus (and NGINX App Protect WAF) API gateway pseudo-production environment that includes a mock API backend database.

A PDF containing accompanying slides for this demo can also be found under the name of `Deploy and Secure Your API Gateway with NGINX.pdf`.

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

You will find a series of NGINX configuration files in the `nginx_api_gateway_config` folder. The folder is divided into individual steps, meant to be copied into their respective directory in order. By default, the folder is uploaded to your NGINX API gateway instance.

A deployment script to help you copy the configuration files, [`deploy.sh`](nginx_api_gateway_config/deploy.sh), is also provided. To run the script, use the step number as a parameter, e.g. `./deploy.sh 1` for step 1.

### Step 1 -> Define the entry point of the NGINX API gateway

To test:

`curl -s http://localhost:8080`

Expected response:

```html
<html>
<head><title>400 Bad Request</title></head>
<body>
<center><h1>400 Bad Request</h1></center>
<hr><center>nginx/1.19.5</center>
</body>
</html>
```

### Step 2 -> Define default JSON error codes

To test:

`curl -s http://localhost:8080`

Expected response:

```json
{"status":400,"message":"Bad request"}
```

### Step 3 -> Define the API endpoints and upstream/backend servers

To test:

`curl -s http://localhost:8080/api/f1/drivers/hamilton | jq`

Expected response:

```json
{"MRData": {
    "xmlns": "http://ergast.com/mrd/1.4",
    "series": "f1",
    "url": "http://ergast.com/api/f1/drivers/hamilton",
    "limit": "30",
    "offset": "0",
    "total": "1",
    "DriverTable": {
      "driverId": "hamilton",
      "Drivers": [{
          "driverId": "hamilton",
          "permanentNumber": "44",
          "code": "HAM",
          "url": "http://en.wikipedia.org/wiki/Lewis_Hamilton",
          "givenName": "Lewis",
          "familyName": "Hamilton",
          "dateOfBirth": "1985-01-07",
          "nationality": "British"
      }]
    }
}}
```

### Step 4 -> Enable rate limiting

To test (run multiple times in quick succession):

`curl -s http://localhost:8080/api/f1/drivers/hamilton`

Expected response:

```json
{"status":429,"message":"API rate limit exceeded"}
```

### Step 5 -> Set up API Key authentication

To test (unauthorized requests):

`curl -s http://localhost:8080/api/f1/drivers/hamilton`

Expected response:

```json
{"status":401,"message":"Unauthorized"}
```

To test (authorized requests):

`curl -sH "apikey: 7B5zIqmRGXmrJTFmKa99vcit" http://localhost:8080/api/f1/drivers/hamilton`

Expected response:

```json
{"MRData":{"xmlns":"http://ergast.com/mrd/1.4","series":"f1","url":"http://ergast.com/api/f1/drivers/hamilton"...
```

### Step 6 -> Set up JWT authentication

To test (unauthorized requests):

`curl -s http://localhost:8080/api/f1/drivers/hamilton`

Expected response:

```json
{"status":401,"message":"Unauthorized"}
```

To test (authorize request):

`curl -sH "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZX0.kFplw9Kkg-6DLFGfVZAPIuWgGPMY9nnMZMQ2iIRN8_s" -X DELETE http://localhost:8080/api/f1/drivers/hamilton`

Expected response:

```json
{"MRData":{"xmlns":"http:\/\/ergast.com\/mrd\/1.4","series":"f1","url":"http://ergast.com/api/f1/drivers/hamilton"...
```

To test (missing JWT claims):

`curl -sH "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6ZmFsc2V9.i7o5c8MEGZWD223IWFIs-Qn6f8FBe_DjvZWn-xBzcvI" -X DELETE http://localhost:8080/api/f1/drivers/hamilton`

Expected response:

```json
{"status":405,"message":"Method not allowed"}
```

### Step 7 -> Set up JSON body validation (using NJS)

To test (incorrect JSON):

`curl -sH "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZX0.kFplw9Kkg-6DLFGfVZAPIuWgGPMY9nnMZMQ2iIRN8_s" -i -X POST -d 'garbage123' http://localhost:8080/api/f1/seasons`

Expected response:

```text
HTTP/1.1 415 Unsupported Media Type
```

To test (correct JSON):

`curl -sH "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZX0.kFplw9Kkg-6DLFGfVZAPIuWgGPMY9nnMZMQ2iIRN8_s" -i -X POST -d '{"season":"2020"}' http://localhost:8080/api/f1/seasons`

Expected response:

```text
HTTP/1.1 200 OK
```

### Step 8 -> Set up NGINX App Protect WAF protection using an OpenAPI spec file

To test:

`curl -sH "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6dHJ1ZX0.kFplw9Kkg-6DLFGfVZAPIuWgGPMY9nnMZMQ2iIRN8_s" -i -X POST -d 'garbage123' http://localhost:8080/api/f1/seasons`

Expected response:

```json
HTTP/1.1 403 Forbidden
{"supportID": "4839869788531770938"}
```

To check logs:

`sudo cat /var/log/app_protect/security.log`

Expected response:

```text
attack_type="HTTP Parser Attack”... support_id="4839869788531771448”...
```

## Author Information

[Alessandro Fael Garcia](https://github.com/alessfg)
