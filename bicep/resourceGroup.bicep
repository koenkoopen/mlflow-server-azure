targetScope = 'subscription'

@description('The name of the resource group to use.')
param name string

@description('The location into which the resources should be deployed.')
param location string

@description('The tags to add to the resource group.')
param tags object = {}

resource newResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: name
  location: location
  tags: tags
}
