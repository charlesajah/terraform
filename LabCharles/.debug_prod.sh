#!/bin/bash
#set the subscription
export ARM_SUBSCRIPTION_ID="2065afa6-df81-45c8-9ca0-d797a834ca85"

#set the application/environment
export TF_VAR_application_name="network"
export TF_VAR_environment_name="prod"

#set the backend
export BACKEND_RESOURCE_GROUP="rg-charlesazure-prod"
export BACKEND_STORAGE_ACCOUNT="storm2f761qc"
export BACKEND_STORAGE_CONTAINER="tfstate"
export BACKEND_KEY=$TF_VAR_application_name-$TF_VAR_environment_name

echo $BACKEND_KEY

#run terraform
terraform init 

##this command below with dollar and asteriks symbols is a trick that allows you to pass in any terraforms command when it is executed for e.g. APPLY, DESTROY, PLAN
terraform $*

#remove all local copies of the remote state
rm -rf .terraform