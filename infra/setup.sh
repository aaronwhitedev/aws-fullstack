#!/bin/bash

# Prompt for domain if params don't exist
if [ $# -eq 0 ]
  then
	read -p "Enter Domain: " input
else
	input=$1
fi

# convert domain to lower case
domain=$(echo "$input" | tr '[:upper:]' '[:lower:]')

# Remove www. if exists
if [[ $domain == www.* ]]; then
	domain="${domain:4}"
fi

region="us-west-2"

# split domain a '.'
IFS="."

# make variable named array
read -ra array <<< "$domain"
declare -i domain_elements
domain_elements=${#array[@]}

# Must be apex domain
if [ "$domain_elements" -ne "2" ]; then
	echo "Domain not valid"
	exit
fi

project="${array[0]}"
unset IFS

# Query AWS for your domain, use jq to parse the Hosted Zone Id
hosted_zone_info=$(aws route53 list-hosted-zones-by-name --max-items 1 --dns-name $domain)
hosted_zone=$(echo "${hosted_zone_info}" | grep \"Id\")
domain_info=$(echo "${hosted_zone_info}" | grep \"DNSName\")

IFS='/hostedzone/'
read -ra array <<< "$hosted_zone"

hosted_zone_id=''
for val in "${array[@]}";
do
	if [[ ! "$val" = "" ]]; then
		line=$(echo ${val} | tr -d ' ')
		if [[ ${#line} -gt "5" ]]; then
			hosted_zone_id="${line//[^[:alnum:].]/}"
		fi
	fi
done
unset IFS
IFS=':'
read -ra array <<< "$domain_info"

aws_domain=${array[1]//[^[:alnum:].]/}
unset IFS

if [ "${aws_domain}" != "${domain}" ]; then
	echo "Domain doesn't exist"
	exit
fi

if [ -d ./config ]; then
	rm -r ./config
fi

mkdir config

# Save hosted zone id in text file
echo "${hosted_zone_id}" > "./config/aws-hosted-zone-id.txt"

# Create the S3 bucket for the infra
bucket_created=$(aws s3api create-bucket --bucket infra.${domain} --create-bucket-configuration LocationConstraint=${region} 2>&1)

if [[ $bucket_created = *'error'* ]]; then
	if [[ $bucket_created != *'BucketAlreadyOwnedByYou'* ]]; then
    	echo "Bucket exists in another account"
	fi
fi

export TF_VAR_domain=${domain}
export TF_VAR_project=${project}
export TF_VAR_region=${region}

printf "bucket=\"infra.${domain}\"\nkey=\"terraform.tfstate\"\nregion=\"${region}\"" > "./config/terraform-config.txt"
printf "domain=\"${domain}\"\nproject=\"${project}\"\nregion=\"${region}\"" > "./terraform.tfvars"

terraform init &> '/dev/null'

# SETUP WEB Front-End
######################################################################

cd ../
if [ -d ./web ]; then
	echo "web folder must be removed to continue"
	exit
fi

npm create vite@latest web -- --template react-ts 2>&1
cd web && npm i react-router-dom 2>&1
npm install -D tailwindcss postcss autoprefixer 2>&1
npx tailwind init -p 2>&1

rm ./src/App.tsx ./src/App.css ./src/index.css ./public/vite.svg ./src/assets/react.svg ./tailwind.config.js
cd ../infra

cp ./tailwind/Home.tsx ../web/src/Home.tsx
cp ./tailwind/main.tsx ../web/src/main.tsx
cp ./tailwind/Nav.tsx ../web/src/Nav.tsx
cp ./tailwind/ErrorPage.tsx ../web/src/ErrorPage.tsx
cp ./tailwind/index.css ../web/src/index.css
cp ./tailwind/tailwind.config.js ../web/tailwind.config.js
cp ./tailwind/eslint.config.js ../web/eslint.config.js

printf "VITE_API=\"https://api.${domain}\"" > "../web/.env"
######################################################################
/bin/bash ./api.sh

terraform init --backend-config=./config/terraform-config.txt 2>&1
zone_exists=$(terraform state show aws_route53_zone.hosted_zone -no-color 2>&1)

if [[ "$zone_exists" = *'No instance'* || "$zone_exists" = *'No state file'* ]]; then
	terraform import aws_route53_zone.hosted_zone ${hosted_zone_id} -no-color 2>&1

	# Double check the zone was imported
	verify_zone_exists=$(terraform state show aws_route53_zone.hosted_zone -no-color 2>&1)
	if [[ "$verify_zone_exists" = *'No instance'* || "$verify_zone_exists" = *'No state file'* ]]; then
		echo "Domain wasn't imported"
		echo "Run terraform import aws_route53_zone.hosted_zone ${hosted_zone_id} to continue"
		exit
	fi
fi