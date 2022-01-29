// The module contains a template to create a role assignment of the Synase MSI to a file system.
targetScope = 'resourceGroup'

// Parameters
param storageAccountFileSystemId string
param purviewId string
var purviewName = last(split(purviewId, '/')) 

// Variables
var storageAccountName = length(split(storageAccountFileSystemId, '/')) >= 13 ? split(storageAccountFileSystemId, '/')[8] : 'incorrectSegmentLength'

// Resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: '${storageAccountName}'
}

resource purview  'Microsoft.Purview/accounts@2021-07-01'  existing = {
  name: purviewName
}

resource RoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storageAccount.id, purview.id, '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
    principalId: purview.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
