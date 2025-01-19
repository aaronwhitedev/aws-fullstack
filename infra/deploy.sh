#!/bin/bash

# Lambdas need built befre creating cloud infrastructure
/bin/bash ../api/api.sh

terraform apply -auto-approve -no-color

/bin/bash ../web/web.sh