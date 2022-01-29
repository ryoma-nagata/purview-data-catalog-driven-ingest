targetScope = 'resourceGroup'

@allowed([
  'true'
  'false'
])
param AllowAll string = 'true'
param tags object 
param synapseName string
param synapseDefaultStorageAccountFileSystemId string 
param administratorUsername string = 'sqladmin'
@secure()
param administratorPassword string = ''
param purviewId string =''

var location = resourceGroup().location
var synapseDefaultStorageAccountFileSystemName = length(split(synapseDefaultStorageAccountFileSystemId, '/')) >= 13 ? last(split(synapseDefaultStorageAccountFileSystemId, '/')) : 'incorrectSegmentLength'
var synapseDefaultStorageAccountName = length(split(synapseDefaultStorageAccountFileSystemId, '/')) >= 13 ? split(synapseDefaultStorageAccountFileSystemId, '/')[8] : 'incorrectSegmentLength'


resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name:synapseName
  location:location
  identity:{
    type:'SystemAssigned'
  }
  tags:tags
  properties:{
    defaultDataLakeStorage:{
      filesystem:synapseDefaultStorageAccountFileSystemName
      accountUrl: 'https://${synapseDefaultStorageAccountName}.dfs.${environment().suffixes.storage}'
    }
    sqlAdministratorLogin: administratorUsername
    sqlAdministratorLoginPassword: administratorPassword
    publicNetworkAccess: 'Enabled'
    purviewConfiguration:{
      purviewResourceId:purviewId
    }
  }
}
resource synapseWorkspace_allowAll 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = if (AllowAll == 'true') {
  parent: synapseWorkspace
  name: 'allowAll'

  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

output synapseId string = synapseWorkspace.id
