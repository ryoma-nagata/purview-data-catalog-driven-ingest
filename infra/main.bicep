targetScope = 'subscription'

@description('自分のリソースを識別するためにリソース名の先頭に付与する文字を入力してください。（最大4文字）例：永田→ngt')
@maxLength(4)
param prefix string 

// @description('デプロイ先のリージョン。変更不要')
// param location string ='japaneast'

@description('Azure Sql管理者名')
param sqlLogin string = 'sqladmin' 
@secure()
@description('Azure Sql管理者パスワード')
param sqlPassword string

@description('Azure SqlAD管理者オブジェクトID 空欄可')
param sqlserverAdminUserObjectID string =''
@description('Azure SqlAD管理者プリンシパル名 欄可')
param sqlserverAdminUser string = ''

@description('作成日')
param createDate string =  utcNow('u')
param uniqueId string = '001'
param location string = 'japaneast'

var synapseName = '${prefix}-syn-${uniqueId}'
var sqlserverName = '${prefix}-sql-${uniqueId}'
var purviewName = '${prefix}-apv-${uniqueId}'
var storageName = replace(replace(toLower('${prefix}-dls-${uniqueId}'), '-', ''), '_', '')
var FileSytemNames = [
  'data'
]
var datafactoryName = '${prefix}-adf-${uniqueId}'

var tags ={
  Environment:'demo'
  CreateDate: dateTimeAdd(createDate, 'PT9H','yyyy/MM/dd')
  Prefix : prefix
}
resource purviewAutoIngestGroup 'Microsoft.Resources/resourceGroups@2021-04-01'={
  name: '${prefix}-autoingest-rg-${uniqueId}'
  location: location
}


// module synapse 'modules/services/synapse.bicep' = {
//   name:'synapseDeploy'
//   scope: purviewAutoIngestGroup
//   params:{
//     tags: tags
//     synapseDefaultStorageAccountFileSystemId: storage.outputs.storageFileSystemIds[0].storageFileSystemId
//     synapseName: synapseName
//     administratorUsername:sqlLogin
//     administratorPassword:sqlPassword
//     purviewId:purview.outputs.purviewId
//   }
// }

module storage 'modules/services/storage.bicep' = {
  name:'storageDeploy'
  scope: purviewAutoIngestGroup
  params:{
    tags:tags
    fileSystemNames:FileSytemNames
    storageName:storageName
  }
}

module sql 'modules/services/sql.bicep' = {
  name:'sqlDeploy'
  scope: purviewAutoIngestGroup
  params:{
    sqlLogin: sqlLogin
    sqlserverName:sqlserverName 
    sqlPassword: sqlPassword
    sqlserverAdminUser:sqlserverAdminUser
    sqlserverAdminUserObjectID:sqlserverAdminUserObjectID
    tags:tags
  }
}

module StorageRBAC 'modules/auxiliary/roleAssingmentDatafactory.bicep' ={
  name:'synapseToStorageRBAC'
  scope: purviewAutoIngestGroup
  params:{
    storageAccountFileSystemId: storage.outputs.storageFileSystemIds[0].storageFileSystemId
    adfId: datafactory.outputs.datafactoryId
  }
}

module purview 'modules/services/purview.bicep' ={
  name:'purviewDeployment'
  scope:purviewAutoIngestGroup
  params:{
    location: location
    tags: tags
    purviewName: purviewName
  }
}

module datafactory 'modules/services/datafactory.bicep' ={
  scope: purviewAutoIngestGroup
  name: 'datafactoryDeployment'
  params: {
    datafactoryName: datafactoryName
    location: location
    sqlDatabase001Name: sql.outputs.metaSqlDatabaseName
    sqlServer001Id:sql.outputs.sqlId
    sqlDatabase002Name: sql.outputs.targetSqlDatabaseName
    sqlServer002Id:sql.outputs.sqlId
    storageId:storage.outputs.storageId
    purviewId:purview.outputs.purviewId
    tags: tags  
  }
}

module purivewToStorageRBAC 'modules/auxiliary/PurviewroleAssingment.bicep'={
  scope: purviewAutoIngestGroup
  name: 'purivewToStorageRBAC'
  params: {
    purviewId: purview.outputs.purviewId
    storageAccountFileSystemId: storage.outputs.storageFileSystemIds[0].storageFileSystemId
  }
}

output sqlAdminUser string = sqlLogin
output sqlserverName string = sqlserverName
output resourceGroupName string = purviewAutoIngestGroup.name
output purviewAccountName string = purviewName
output purviewRootAdminPostUrl string = '${environment().resourceManager}${purview.outputs.purviewId}/addRootCollectionAdmin?api-version=2021-07-01'
output sqlserverHostName string = sql.outputs.sqlserverHostName
output metaStoreDatabaseName string = sql.outputs.metaSqlDatabaseName
