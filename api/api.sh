#!/bin/bash

if [ ! -d "lambdas" ]
then
	mkdir lambdas
fi

project=''
# PARSE DOMAIN from terraform.tfvars
while IFS= read -r line || [[ -n "$line" ]]; do
	if [[ $line = *'project='* ]]; then
		project=$(echo "${line//project=/}" | tr -d '"')
	fi
done < "../infra/terraform.tfvars"

# Copy prev transpiled JavaScript files for future compare
for file in ./lambdas/*.js; do
	if [ -f ${file} ]; then
		cp ${file} ${file%.*}.txt
	fi
done

npm i &> /dev/null
tsc &> /dev/null

for file in *.ts; do
	deps=""
	while IFS= read -r line; do
		if [[ $line == *import* && $line == *from*  && $line != *aws-lambda* && $line != *@types/node* ]]; then
			deps+=$(echo $line | awk -F "\"" '{print $2}')
			deps+=" "
		fi
	done < "${file}"

	if [[ ! -d ./lambdas/${file%.*} ]]; then
		mkdir "./lambdas/${file%.*}"
	fi

	# read existing dependencies
	existing=""
	if [[ -f ./lambdas/${file%.*}/deps.txt ]]; then
		existing=$(cat ./lambdas/${file%.*}/deps.txt)
	fi
	
	# detect changes in dependencies
	if [[ "$existing" != "$deps" || "$existing" == '' ]]; then
		if [[ -d lambdas/${file%.*}/node_modules ]]; then
			rm -r lambdas/${file%.*}/node_modules
		fi
		cp ./lambdas/${file%.*}.js ./lambdas/${file%.*}/index.js
		
		# Check & install NPM dependecies if they exist
		if [ -n "${deps}" ]; then
			echo $(npm i --prefix ./lambdas/${file%.*}/ ${deps})
			cd ./lambdas/${file%.*}/node_modules/
			zip ../../${file%.*}.zip -r . &> /dev/null
			cd ../
			echo ./lambdas/${file%.*}/deps.txt > "${deps[@]}"
			zip ../${file%.*}.zip ./index.js &> /dev/null
			cd ../../
		else
			cd ./lambdas/${file%.*}
			zip ../${file%.*}.zip ./index.js &> /dev/null
			touch ./deps.txt
			cd ../../
		fi
		
	else
		cd ./lambdas/
		cp ./${file%.*}.js ./${file%.*}/index.js &> /dev/null
		cd ./${file%.*}/
		zip ../${file%.*}.zip ./index.js &> /dev/null
		cd ../../
	fi
done

if [ "${1}" != "setup" ]; then
	for file in ./lambdas/*.js; do
		IFS='/' read -ra array <<< "${file%.*}"
		function_name=${array[2]}

		# compare transpiled .js file against previous file (saved as .txt)
		cmp -s ${file} "${file%.*}.txt"
		
		if [ $? -ne 0 ]; then
			echo $(aws lambda update-function-code --function-name ${project}_${function_name} --zip-file fileb://lambdas/${function_name}.zip ) # &> /dev/null)
			echo "Deploying ${function_name}"
		fi
	done
	echo "API deployed"
fi

# remove temp .txt files
for file in ./lambdas/*.txt; do
	rm ${file}
done
