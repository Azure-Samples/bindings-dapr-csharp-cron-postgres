targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }

param apiContainerAppName string = ''
param apiServiceName string = 'batch'
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param containerAppsEnvironmentName string = ''
param containerRegistryName string = ''
param postgresUser string = 'postgres'
param keyVaultName string = ''
param secretStoreName string = 'secretstore'
param logAnalyticsName string = ''
param resourceGroupName string = ''

@secure()
param pgPassword string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('The image name for the api service')
param apiImageName string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module security 'app/security.bicep' = {
  name: 'security'
  scope: rg
  params: {
    location: location
    vaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    managedIdentityName: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
    principalId: principalId
    tags: tags
    pgConnectionString: 'postgres://${postgresUser}:${pgPassword}@${postgresServer.outputs.POSTGRES_DOMAIN_NAME}/${postgresUser}'
  }
}

// Shared App Env with Dapr configuration for db
module appEnv './app/app-env.bicep' = {
  name: 'app-env'
  scope: rg
  params: {
    containerAppsEnvName: !empty(containerAppsEnvironmentName) ? containerAppsEnvironmentName : '${abbrs.appManagedEnvironments}${resourceToken}'
    containerRegistryName: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
    secretStoreName: secretStoreName
    principalId: security.outputs.managedIdentityClientlId
    vaultName: security.outputs.keyVaultName
  }
}

// Api backend
module api './app/api.bicep' = {
  name: 'batch'
  scope: rg
  params: {
    name: !empty(apiContainerAppName) ? apiContainerAppName : '${abbrs.appContainerApps}${apiServiceName}-${resourceToken}'
    location: location
    imageName: apiImageName
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    containerAppsEnvironmentName: appEnv.outputs.environmentName
    containerRegistryName: appEnv.outputs.registryName
    serviceName: apiServiceName
    keyVaultName: security.outputs.keyVaultName
    managedIdentityName: security.outputs.managedIdentityName
  }
}

// The application database
module postgresServer './core/database/postgres/sql/postgres-sql-db.bicep' = {
  name:'pg' 
  scope: rg
  params: {
    name: '${resourceToken}-pg-server'
    location: location
    tags: tags
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storage: {
      storageSizeGB: 32
    }
    version: '13'
    allowAllIPsFirewall: true
    administratorLogin: postgresUser
    administratorLoginPassword: pgPassword
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output APPLICATIONINSIGHTS_NAME string = monitoring.outputs.applicationInsightsName
output AZURE_CONTAINER_ENVIRONMENT_NAME string = appEnv.outputs.environmentName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = appEnv.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = appEnv.outputs.registryName
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_KEY_VAULT_ENDPOINT string = security.outputs.keyVaultEndpoint
output AZURE_KEY_VAULT_NAME string = security.outputs.keyVaultName
output AZURE_MANAGED_IDENTITY_NAME string = security.outputs.managedIdentityName
output SERVICE_API_NAME string = api.outputs.SERVICE_API_NAME
