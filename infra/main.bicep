targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unqiue hash used in all resources.')
param name string

param postgresLogin string = 'testdeveloper'

@secure()
param postgresPassword string

@minLength(1)
@description('Primary location for all resources')
param location string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
}

var resourceToken = toLower(uniqueString(subscription().id, name, location))

module application 'app/paas-application.bicep' = {
  name: 'bindings-dapr-aca-paas-${resourceToken}'
  params: {
    name: name
    location: location
    postgresUser: postgresLogin
    postgresPassword: postgresPassword
  }
  scope: resourceGroup
  dependsOn:[
    binding
  ]
}

module batchContainerApp 'app/batch-service.bicep' = {
  name: 'ca-batch-${resourceToken}'
  params:{
    name: name
    location: location
  }
  scope: resourceGroup
  dependsOn:[
    application
  ]
}

module binding 'app/dapr-state-postgres.bicep' = {
  name: 'bindings-pg-orders-${resourceToken}'
  params: {
    name: name
    location: location
    postgresUser: postgresLogin
    postgresPassword: postgresPassword
  }
  scope: resourceGroup
}

output APPINSIGHTS_INSTRUMENTATIONKEY string = application.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = application.outputs.CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_NAME string = application.outputs.CONTAINER_REGISTRY_NAME
output APP_CHECKOUT_BASE_URL string = batchContainerApp.outputs.CONTAINERAPP_URI
output APP_APPINSIGHTS_INSTRUMENTATIONKEY string = application.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output POSTGRES_USER string = binding.outputs.POSTGRES_USER
