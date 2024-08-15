#!/bin/bash

/bin/bash ./api.sh
terraform apply -auto-approve -no-color
/bin/bash ./web.sh