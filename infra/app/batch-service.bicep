@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unqiue hash used in all resources.')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

@minLength(1)
@description('name used to derive service, container and dapr appid')
param containerName string = 'batch'

@description('image name used to pull')
param imageName string = ''

@description('port used for ingress target port and dapr app port')
param ingressPort int = 7002

var resourceToken = toLower(uniqueString(subscription().id, name, location))

param tags object = {
  'azd-env-name': name
}

module containerAppHttp '../core/containerapp-http.bicep' = {
  name: 'ca-http-${resourceToken}'
  params:{
    name: name
    location: location
    containerName: containerName
    imageName: imageName != '' ? imageName : 'nginx:latest'
    ingressPort: ingressPort
    tags: union(tags, { 'azd-service-name': 'batch' })
  }
}

output CONTAINERAPP_URI string = containerAppHttp.outputs.CONTAINERAPP_URI
