param name string
param location string

param postgresUser string = 'testdeveloper'

@secure()
param postgresPassword string

param resourceToken string = toLower(uniqueString(subscription().id, name, location))
param tags object = {
  'azd-env-name': name
}

resource postgresDB 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: 'pg${resourceToken}'
  location: location
  tags: tags
  sku: {
    capacity: 2
    family: 'Gen5'
    name: 'GP_Gen5_2'
    size: '51200'
    tier: 'GeneralPurpose'
  }
  properties: {
    storageProfile: {
      backupRetentionDays: 7 
      geoRedundantBackup: 'Disabled'
      storageMB: 51200
    }
    administratorLogin: postgresUser
    administratorLoginPassword: postgresPassword
    version: '11'
    createMode: 'Default'
    publicNetworkAccess: 'Enabled'
  }
}

resource postgresFirewall 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
  name: 'pgfirewall${resourceToken}'
  parent: postgresDB
  properties: {
    endIpAddress: '255.255.255.255'
    startIpAddress: '0.0.0.0'
  }
}

output POSTGRES_USER string = postgresUser
