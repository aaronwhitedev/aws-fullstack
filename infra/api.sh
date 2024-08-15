#!/bin/bash

if [ -d /lambdas ]; then
	rm /lambdas/*.zip
fi

cd ../api/

if [ ! -f ./tsconfig.json ]; then
	tsc --init -outDir '../infra/lambdas' &> '/dev/null'
fi

if [ ! -d ./api/node_modules ]; then
	npm init -y --loglevel silent &> '/dev/null'
	npm i -D @types/aws-lambda &> '/dev/null'
fi

if [ ! -d ../infra/lambdas ]; then
	cd ../infra
	mkdir ./lambdas
	cd ../api
fi

tsc && cd ../infra/lambdas

for file in *.js; do
	# Create zip files
	zip ${file%%.*} ${file} -qq
done

# Change back to infra
cd ../

