@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unqiue hash used in all resources.')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = {
  'azd-env-name': name
}

param postgresUser string = 'testdeveloper'

@secure()
param postgresPassword string

module containerAppsEnvResources './../core/containerappsenv.bicep' = {
  name: 'containerapps-resources'
  params: {
    location: location
    tags: tags
    postgresUser: postgresUser
    postgresPassword: postgresPassword
    resourceToken: resourceToken
  }

  dependsOn: [
    logAnalyticsResources
    appInsightsResources
  ]
}

module appInsightsResources './../core/appinsights.bicep' = {
  name: 'appinsights-resources'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
  }
}

module logAnalyticsResources './../core/loganalytics.bicep' = {
  name: 'loganalytics-resources'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
  }
}

output APPINSIGHTS_INSTRUMENTATIONKEY string = appInsightsResources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output CONTAINER_REGISTRY_ENDPOINT string = containerAppsEnvResources.outputs.CONTAINER_REGISTRY_ENDPOINT
output CONTAINER_REGISTRY_NAME string = containerAppsEnvResources.outputs.CONTAINER_REGISTRY_NAME
output RESOURCE_TOKEN string = resourceToken
