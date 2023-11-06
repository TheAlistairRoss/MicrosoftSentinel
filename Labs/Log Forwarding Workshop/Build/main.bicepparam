using './main.bicep'

param location = 'uksouth'
param basename = 'sent-adv-logging-workshop'
param adminUsername = 'workshopadmin'
param authenticationType = 'password'
param adminPasswordOrSSHKey = ''
param adminPassword = ''
param logForwarderAutoscaleMin = 1
param logForwarderAutoscaleMax = 2
param deployAMPLS = true
param deployDataCollectionRule = true
param configureLogSource = true
param deployLogSplittingDataCollectionRule = true

