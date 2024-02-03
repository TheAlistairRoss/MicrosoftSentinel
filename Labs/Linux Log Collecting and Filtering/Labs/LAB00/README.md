# Lab Setup

## Overview
### Objectives

After completing this lab, you should:

- Have all intial resources deployed for this workshop
- Have simulated logs ingested from the Linux server into the Syslog table

## Prerequisite

Double check you have the following
- An Azure subscription
- Owner permissions on a resource group
- Access via the Azure portal
- Able to deploy:
    - Azure Virtual Networks
    - Azure Public IP (for Azure Bastion)
    - Azure Bastion
    - Linux Virtual Machine
    - Log Analytics Workspace 
    - Microsoft Sentinel
    - Data Collection Rules

## **Phase 1 Deploy ARM Templates**

1. Deploy the ARM template:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FTheAlistairRoss%2FMicrosoftSentinel%2Fmain%2FLabs%2FLinux%2520Log%2520Collecting%2520and%2520Filtering%2FBuild%2Fmain.json)

2. Branch Deploy 
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FTheAlistairRoss%2FMicrosoftSentinel%2FWorkshopUpdating%2FLabs%2FLinux%2520Log%2520Collecting%2520and%2520Filtering%2FBuild%2Fmain.json)

1. Set the Parameters
   1. **Subscription** - Select the subscription where the resoruces will be deployed
   1. **Resource Group** - Select an existing or create a new resource group (recommended) for the workshop resources.    
   1. **Region** - This is automatically set based on your Resource Group location
   1. **Admin Password or SSH Key** - Either leave this as the default ```WorkshopPassword1234``` , or change to a new password.
   1. **Admin Username** - Either leave as the default ```workshopadmin```, or change to a new name.
   1. **Authentication Type** - Leave as ```Password```. The instructions have not been writted for SSH! (Unless you already know what you are doing).
   1. **Basename** - Most resources will incorporate this into their naming convention. Leave as is.
   1. **datetime** - Leave as ```utcnow()``` as it is used for unique deployment names.
   1. **Deploy Bastion** -Leave as ```true```. Used for testing scenarios.
   1. **Deploy Data Collection Rule** - Leave as ```true```. Used for testing scenarios.
   1. **Deploy Linux Log Source** - Leave as ```true```. Used for testing scenarios.
   1. **Deploy Networking** - Leave as ```true```. Used for testing scenarios.
   1. **Deploy Sentinel** - Leave as ```true```. Used for testing scenarios.
   1. **Location** - Leave as ```resourceGroup().location```
   1. **vNet Address IPv4 Id** - Leave as default ```10.0.0.0``` unless you intend to peer with another network outside of this workshop.
   1. **_artifactsLocation** - Leave as default  ```deployment().properties.templateLink.uri``` unless you need to specify another url to deploy this template from.
   1. **_artifactsLocationSasToken** - Leave as default (Blank) unless you are deploying from a location that requires Sas token for authentication.

Deployment will take up to about 15 minutes for this due to Azure Bastion. Once it has completed, navigate to the next lab

## Continue with the next lab

[Lab01 - ](./Labs/LAB01/README.md)
