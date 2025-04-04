targetScope = 'subscription'

@description('The location into which the resources should be deployed.')
param location string

@description('The team abbreviation that is used to prefix resource names.')
param team string = 'mlflow'

@description('The name of the resource group to use.')
param project string = 'infrastructure'

@allowed([
  'ota'
  'prd'
])
@description('The environment to use.')
param environment string = 'ota'

@description('The name of the file share in the storage account.')
param mlflowShareName string = 'mlflowshare'

@description('The name of the blob container in the storage account.')
param mlflowBlobName string = 'mlflowblob'

@description('The sku of the storage needed.')
param skuStorage string = 'Standard_LRS'

var tags = union(loadJsonContent('./tags.json'), { Environment: toUpper(environment) })

var resourceGroupName = '${toUpper(team)}_${toUpper(environment)}_${toUpper(project)}'

module infraResourceGroup 'resourceGroup.bicep' = {
  name: 'infraResourceGroup${environment}_${uniqueString(deployment.name(), location)}'
  scope: subscription()
  params: {
    name: resourceGroupName
    location: location
    tags: tags
  }
}

module mlflowContainerRegistry 'containerRegistry.bicep' = {
  name: 'mlflowContainerRegistry${environment}_${uniqueString(deployment.name(), location)}'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    name: '${team}${environment}${project}'
    tags: tags
  }
  dependsOn: [
    infraResourceGroup
  ]
}

module mlflowStorageAccount 'storageAccount.bicep' = {
  name: 'mlflowStorageAccount${environment}_${uniqueString(deployment.name(), location)}'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    name: '${team}${environment}${project}'
    tags: tags
    sku: skuStorage
    mlflowShareName: mlflowShareName
    mlflowBlobName: mlflowBlobName
    virtualNetworkRules: [
      // in case of a VNET add this here to allow traffic
    ]
    mlflowBool: true
  }
  dependsOn: [
    infraResourceGroup
  ]
}
