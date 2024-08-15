#!/bin/bash

if [ -d ./web ]; then
	rm -r ./web
fi

if [ -d ./dist ]; then
	rm -r ./dist
fi

cd ../web/
npm run build 2>&1
cd ../infra

domain=''
# Prevent last line from being ignored
while IFS= read -r line || [[ -n "$line" ]]; do
	if [[ $line = *'domain='* ]]; then
		domain=$(echo "${line//domain=/}" | tr -d '"')
	fi
done < "./terraform.tfvars"

if [ ! -d ../web/dist ]; then
	echo "Web app build doesn't exist"
	exit
fi
cd ../web/dist
aws s3 sync ./ s3://www.${domain} --exclude=".git*"
cd ../
rm -r dist
cd ../infra

cf_dist=$(terraform state show aws_cloudfront_distribution.www_cloudfront | grep arn:aws:cloudfront::)
IFS='/'
read -ra array <<< "$cf_dist"
cf_dist_id=$(echo ${array[1]//[^[:alnum:]]})
unset

aws cloudfront create-invalidation --distribution-id ${cf_dist_id} --paths "/index.html" &> '/dev/null'