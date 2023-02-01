param location string
param resourceToken string
param tags object

@secure()
param postgresUser string
@secure()
param postgresPassword string

resource pg 'Microsoft.DBforPostgreSQL/servers@2017-12-01' existing = {
  name: 'pg${resourceToken}'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: 'log${resourceToken}'
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: 'cae${resourceToken}'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
  dependsOn: [
    pg
  ]

  resource daprSQLDBComponent 'daprComponents' = {
    name: 'sqldb'
    properties: {
      componentType: 'bindings.postgres'
      version: 'v1'
      ignoreErrors: false
      secrets:[
          {
            name: 'pg-connectionstring'
            value: 'postgres://${postgresUser}@${pg.name}:${postgresPassword}@${pg.name}.postgres.database.azure.com:5432/postgres?sslmode=verify-ca'
          }
          
      ]
      metadata: [
       {
          name: 'url'
          secretRef: 'pg-connectionstring'
        }
      ]
      scopes: [
        'batch'
      ]
    }
  }

  resource daprCronComponent 'daprComponents' = {
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
      scopes: [
        'batch'
      ]
    }
  }
}

module containerRegistry './containerregistry.bicep' = {
  name: 'contreg${resourceToken}'
  params:{
    location: location
    resourceToken: resourceToken
    tags: tags
  }
}

output CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.CONTAINER_REGISTRY_ENDPOINT
output CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.CONTAINER_REGISTRY_NAME
output PG_STRING string = pg.name
