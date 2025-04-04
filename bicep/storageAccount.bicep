@description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(24)
@description('The name of the storage account to use.')
param name string = 'storage${uniqueString(resourceGroup().id)}'

@description('The tags to add to the storage account.')
param tags object = {}

@description('The name of the file share in the storage account.')
param mlflowShareName string = 'mlflowshare'

@description('The name of the blob container in the storage account.')
param mlflowBlobName string = 'mlflowblob'

@description('The kind of the storage needed.')
param kind string = 'StorageV2'

@description('The sku of the storage needed.')
param sku string = 'Standard_LRS'

@description('The virtual network rules.')
param virtualNetworkRules array = []

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  tags: tags
  location: location
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: virtualNetworkRules
    }
  }
}

resource mlflowFileService 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  name: 'default'
  parent: storage
}

resource mlflowShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: '${mlflowShareName}_${uniqueString(deployment.name(), location)}'
  parent: mlflowFileService
}

resource traefikShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: 'traefik'
  parent: mlflowFileService
}

resource mlflowBlobservice 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storage
}

resource mlflowBlob 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${mlflowBlobName}_${uniqueString(deployment.name(), location)}'
  parent: mlflowBlobservice
}

output storageAccountId string = storage.id
