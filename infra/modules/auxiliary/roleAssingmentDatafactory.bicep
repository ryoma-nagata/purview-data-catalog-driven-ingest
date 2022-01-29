// The module contains a template to create a role assignment of the Synase MSI to a file system.
targetScope = 'resourceGroup'

// Parameters
param storageAccountFileSystemId string
param adfId string

// Variables
var storageAccountName = length(split(storageAccountFileSystemId, '/')) >= 13 ? split(storageAccountFileSystemId, '/')[8] : 'incorrectSegmentLength'
var adfSubscriptionId = length(split(adfId, '/')) >= 9 ? split(adfId, '/')[2] : subscription().subscriptionId
var adfResourceGroupName = length(split(adfId, '/')) >= 9 ? split(adfId, '/')[4] : resourceGroup().name
var adfName = length(split(adfId, '/')) >= 9 ? last(split(adfId, '/')) : 'incorrectSegmentLength'

// Resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: '${storageAccountName}'
}

resource adf 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: adfName
  scope: resourceGroup(adfSubscriptionId, adfResourceGroupName)
}

resource adfRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storageAccount.id, adf.id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: adf.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
