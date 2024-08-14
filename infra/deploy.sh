#!/bin/bash

/bin/bash ./build.sh
terraform apply -auto-approve -no-color

/bin/bash ./web.sh