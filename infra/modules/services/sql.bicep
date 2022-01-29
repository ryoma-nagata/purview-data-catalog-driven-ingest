param sqlserverName string 
param sqldbName string = 'AdventureWorksLT'

param sqlLogin string
@secure()
param sqlPassword string
param tags object
param sqlserverAdminUserObjectID string =''
param sqlserverAdminUser string = ''

var location  =resourceGroup().location

resource sqlserver 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: sqlserverName
  location: location
  properties: {
    administratorLogin: sqlLogin
    administratorLoginPassword: sqlPassword
    publicNetworkAccess: 'Enabled'
  }
  tags:tags
}
resource sqlserverAdministrators 'Microsoft.Sql/servers/administrators@2020-11-01-preview' = if (!empty(sqlserverAdminUser) && !empty(sqlserverAdminUserObjectID)) {
  parent: sqlserver
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: sqlserverAdminUser
    sid: sqlserverAdminUserObjectID
    tenantId: subscription().tenantId
  }
}


resource network 'Microsoft.Sql/servers/firewallRules@2021-05-01-preview' = {
  name:'AllowAllWindowsAzureIps'
  parent:sqlserver
  properties:{
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}
resource ALLnetwork 'Microsoft.Sql/servers/firewallRules@2021-05-01-preview' = {
  name:'AllowAll'
  parent:sqlserver
  properties:{
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource sqldatabase 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  name: sqldbName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  parent: sqlserver
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    sampleName: 'AdventureWorksLT'   
  }
}


resource metasqldatabase 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  name: 'pipeline_meta'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  parent: sqlserver
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

output sqlserverName string = sqlserverName
output sqlId string = sqlserver.id
output metaSqlDatabaseName string = metasqldatabase.name
output targetSqlDatabaseName string = sqldatabase.name
output sqlserverHostName string = '${sqlserverName}${environment().suffixes.sqlServerHostname}'
