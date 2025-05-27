# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.27.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
  }
  #backend "azurerm" {
  #resource_group_name  = "rg-charlesazure-dev"
  #storage_account_name = "stor46mn8eir" # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
  #container_name       = "tfstate"      # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
  #key                  = "devops-dev"   # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.

  #}
  #}

  # Uncomment this block to use Terraform Cloud for this tutorial
  cloud {
    organization = "charles-ajah"
    workspaces {
      name = "Learning"
    }
  }

}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  #we would rather set the subscription_id using env variables
  #this avoids hardcoding of subscription_id into our code as shown below
  #subscription_id = "2065afa6-df81-45c8-9ca0-d797a834ca85"

  /*we can set it in powershell as follows
  $env:ARM_SUBSCRIPTION_ID="2065afa6-df81-45c8-9ca0-d797a834ca85" */

}
