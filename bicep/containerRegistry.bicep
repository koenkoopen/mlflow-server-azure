@description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the container registry to use.')
param name string = 'cont${uniqueString(resourceGroup().id)}'

@description('The tags to add to the container registry.')
param tags object = {}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  location: location
  name: name
  sku: {
    name: 'Premium'
  }
  tags: tags
  properties: {
    adminUserEnabled: true
    anonymousPullEnabled: false
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      softDeletePolicy: {
        retentionDays: 7
        status: 'enabled'
      }
    }
  }
}

output containerRegistryId string = containerRegistry.id
