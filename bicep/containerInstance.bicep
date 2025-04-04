targetScope = 'resourceGroup'

@description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the container instance group to use.')
param aciName string

@description('The name of the container.')
param containerName string

@description('The name of the container registry to use.')
param acrImage string

@description('The tags to add to the storage account.')
param tags object = {}

@description('The .env variables to add to the container.')
param envVariables array = []

@description('The image credentials to the container.')
param imageCreds array = []

@description('The volume mounts.')
param volumeMounts array = []

@description('The volumes.')
param volumes array = []

@description('The subnet IDs.')
param subnetIDs array = []

@description('The OS')
param OS string = 'Linux'

@description('The TCP port')
param port int

@description('The container resources')
param resources object

resource mlflowACI 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: aciName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          environmentVariables: envVariables
          image: acrImage
          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]
          volumeMounts: volumeMounts
          resources: resources
        }
      }
    ]
    imageRegistryCredentials: imageCreds
    ipAddress: {
      ports: [
        {
          port: port
          protocol: 'TCP'
        }
      ]
      type: 'Private'
    }
    osType: OS
    sku: 'Standard'
    subnetIds: subnetIDs
    volumes: volumes
  }
}

output managedIdentityServicePrincipalId string = mlflowACI.identity.principalId
