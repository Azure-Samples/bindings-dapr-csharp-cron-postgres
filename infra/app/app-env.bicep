param containerAppsEnvName string
param containerRegistryName string
param secretStoreName string
param vaultName string
param location string
param logAnalyticsWorkspaceName string
param principalId string
param applicationInsightsName string
param daprEnabled bool

// Container apps host (including container registry)
module containerApps '../core/host/container-apps.bicep' = {
  name: 'container-apps'
  params: {
    name: 'app'
    containerAppsEnvironmentName: containerAppsEnvName
    containerRegistryName: containerRegistryName
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
    daprEnabled: daprEnabled
  }
}

// Get App Env resource instance to parent Dapr component config under it
resource caEnvironment  'Microsoft.App/managedEnvironments@2022-10-01' existing = {
  name: containerAppsEnvName
}

resource daprComponentSecretStore 'Microsoft.App/managedEnvironments/daprComponents@2022-10-01' = {
  parent: caEnvironment
  name: secretStoreName
  properties: {
    componentType: 'secretstores.azure.keyvault'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5s'
    metadata: [
      {
        name: 'vaultName'
        value: vaultName
      }
      {
        name: 'azureClientId'
        value: principalId
      }
    ]
    scopes: ['batch']
  }
  dependsOn: [
    containerApps
  ]
}

resource daprComponentPostgresBinding 'Microsoft.App/managedEnvironments/daprComponents@2022-10-01' = {
  parent: caEnvironment
  name: 'sqldb'
  properties: {
    componentType: 'bindings.postgres'
    version: 'v1'
    ignoreErrors: false
    metadata: [
      {
         name: 'url'
         secretRef: 'pg-connection-string'
       }
     ]
    secretStoreComponent: secretStoreName
    scopes: ['batch']
  }
  dependsOn: [
    containerApps
  ]
}

// Dapr component configuration for shared environment, scoped to appropriate APIs
resource daprComponentCronBinding 'Microsoft.App/managedEnvironments/daprComponents@2022-10-01' = {
  parent: caEnvironment
  name: 'cron'
  properties: {
    componentType: 'bindings.cron'
    version: 'v1'
    ignoreErrors: false
    metadata: [
      {
        name: 'schedule'
        value: '@every 10s'
      }
    ]
    scopes: ['batch']
  }
  dependsOn: [
    containerApps
  ]
}

output environmentName string = containerApps.outputs.environmentName
output registryLoginServer string = containerApps.outputs.registryLoginServer
output registryName string = containerApps.outputs.registryName
