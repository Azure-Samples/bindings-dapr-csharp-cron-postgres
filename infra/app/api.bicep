param location string = resourceGroup().location
param tags object = {}

param containerAppsEnvironmentName string
param containerRegistryName string
param imageName string = ''
param name string = ''
param keyVaultName string
param serviceName string = 'batch'
param managedIdentityName string = ''

module app '../core/host/container-app.bicep' = {
  name: 'api'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': 'api' })
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    containerCpuCoreCount: '1.0'
    containerMemory: '2.0Gi'
    imageName: !empty(imageName) ? imageName : 'nginx:latest'
    daprEnabled: true
    containerName: serviceName
    targetPort: 7002
    identityType: 'SystemAssigned'
    identityName: managedIdentityName
  }
}


// resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
//   name: keyVaultName
// }

output SERVICE_API_IDENTITY_PRINCIPAL_ID string = app.outputs.identityPrincipalId
output SERVICE_API_NAME string = app.outputs.name
output SERVICE_API_URI string = app.outputs.uri
output SERVICE_API_IMAGE_NAME string = app.outputs.imageName
