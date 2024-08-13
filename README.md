# AWS Fullstack App using Terraform

This repo requires a domain name in Route 53. It scaffolds out all the infrastructure necessary for your web app and API including DNS records, multiple ACM Certs for apex domain and sub domains, S3 buckets, CloudFront distributions, API Gateway, and a Lambda function.

The `apex` domain (`domain-name.com` for example) is redirected to the `www` version (`www.your-domain.com`) of the site. The API will be at `api.your-domain.com`.

## Who this repo is inteded for:

Simple fullstack apps in a single enviornment where you typically only need a few API endpoints and Lamdba functions.

# What you'll deploy

### Front-End SPA (Single Page Application) using React, Vite, and Tailwind.

![SPA App](https://raw.githubusercontent.com/aaronwht/aws-fullstack/main/readme/aws-spa.png)

### API uses JavaScript and TypeScript with logging and associated permissions.

![API](https://raw.githubusercontent.com/aaronwht/aws-fullstack/main/readme/lambda-basic.png)

## Tech Stack

AWS, Bash, Terraform, JavaScript, TypeScript, React, Vite, and Tailwind.

# Configuration:

You need an AWS account and an IAM role with an Access Key that has `AdministratorAccess`.

Dowload the [AWS CLI](https://aws.amazon.com/cli/) or install using Homebrew `brew install awscli`

Download [Node.js](https://nodejs.org) or install using Homebrew `brew install node`

Download [Terraform](https://www.terraform.io/) or install using Homebrew:

```
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew update
brew upgrade hashicorp/tap/terraform
```

Download [jq](https://jqlang.github.io/jq/) or install using Homebrew `brew install jq`

## Permissions to run the scripts

Give the scripts execute permissions:

```
chmod +x ./infra/setup.sh ./infra/build.sh ./infra/deploy.sh ./infra/web.sh
```

Change into your `infra` folder to continue:  
`cd infra`  

Run the setup using the below:
`./setup.sh your-domain-name.com`

Provided everything works, run:
`./deploy.sh`

### Terraform

The scripts should import your Hosted Zone into terraform state seemlessly. If there are any issues you can reference the Hosted Zone Id of your domain in `infra/config/aws-hosted-zone-id.txt`.

If you need to manually import your domain run `terraform import aws_route53_zone.hosted_zone YOUR_HOSTED_ZONE_ID`.

If you need to destroy Terraform state run `terraform state rm aws_route53_zone.hosted_zone` prior to `terraform destroy` and comment out the `hosted_zone` in `infra/main.tf`
