targetScope = 'resourceGroup'

@description('The team abbreviation that is used to prefix resource names.')
param team string = 'mlflow'

@description('The location into which the resources should be deployed.')
param location string = resourceGroup().location

@minLength(4)
@maxLength(24)
@description('The name of the resource group to use.')
param project string = 'infrastructure'

@allowed([
  'ota'
  'prd'
])
@description('The environment to use.')
param environment string = 'ota'

@description('The name of the container instance group to use.')
param aciName string = '${team}${environment}'

@description('The name of the container registry to use.')
param acrName string = '${team}${environment}${project}'

@minLength(4)
@maxLength(24)
@description('The name of the storage account to use.')
param storageName string = '${team}${environment}${project}'

@description('The name of the file share in the storage account.')
param mlflowShareName string = 'mlflowshare'

var resourceGroupName = '${toUpper(team)}_${toUpper(environment)}_${toUpper(project)}'

var tags = union(loadJsonContent('./tags.json'), { Environment: environment })

@description('The name of the specific MLFlow container instance to use.')
var acicontainerName = 'mlflowcontainer'

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageName
  scope: resourceGroup(resourceGroupName)
}

resource registry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
  scope: resourceGroup(resourceGroupName)
}

module mlflowACI 'containerInstance.bicep' = {
  name: '${aciName}_${uniqueString(deployment.name(), location)}'
  params: {
    tags: tags
    aciName: '${aciName}_mlflow'
    containerName: acicontainerName
    acrImage: '${registry.properties.loginServer}/mlflowserver-azure:latest'
    port: 5000
    resources: {
      limits: {
        cpu: 1
        memoryInGB: json('2')
      }
      requests: {
        cpu: 1
        memoryInGB: json('2')
      }
    }
    volumeMounts: [
      {
        mountPath: '/mnt/azfiles'
        name: 'mlflowvolume'
        readOnly: false
      }
    ]
    envVariables: [
      {
        name: 'MLFLOW_SERVER_FILE_STORE'
        value: '/mnt/azfiles/mlruns'
      }
      {
        name: 'MLFLOW_SERVER_HOST'
        value: '0.0.0.0'
      }
      {
        name: 'MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT'
        secureValue: 'wasbs://mlflowblob@${storage.name}.blob.core.windows.net/mlartefacts'
      }
      {
        name: 'AZURE_STORAGE_ACCESS_KEY'
        secureValue: storage.listKeys().keys[0].value
      }
      {
        name: 'AZURE_STORAGE_CONNECTION_STRING'
        secureValue: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
      }
    ]
    subnetIDs: []
    imageCreds: [
      {
        password: registry.listCredentials().passwords[0].value
        server: registry.properties.loginServer
        username: registry.listCredentials().username
      }
    ]
    volumes: [
      {
        azureFile: {
          readOnly: false
          shareName: mlflowShareName
          storageAccountKey: storage.listKeys().keys[0].value
          storageAccountName: storage.name
        }
        name: 'mlflowvolume'
      }
    ]
  }
}
