param name string
param location string

param postgresUser string = 'testdeveloper'

@secure()
param postgresPassword string

var resourceToken = toLower(uniqueString(subscription().id, name, location))
param tags object = {
  'azd-env-name': name
}

module daprBindingPGResources '../core/postgres.bicep' = {
  name: 'dapr-binding-pg-${resourceToken}'
  params:{
    name: name
    location: location
    tags: tags
    postgresUser: postgresUser
    postgresPassword: postgresPassword
  }
}

output POSTGRES_USER string = daprBindingPGResources.outputs.POSTGRES_USER
