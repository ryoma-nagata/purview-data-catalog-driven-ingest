// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Data Factory.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param datafactoryName string


param purviewId string = ''

param storageId string

param sqlServer001Id string
param sqlDatabase001Name string
param sqlServer002Id string
param sqlDatabase002Name string

// Variables
var storageName = length(split(storageId, '/')) >= 9 ? last(split(storageId, '/')) : 'incorrectSegmentLength'
var sqlServer001Name = length(split(sqlServer001Id, '/')) >= 9 ? last(split(sqlServer001Id, '/')) : 'incorrectSegmentLength'
var sqlServer002Name = length(split(sqlServer002Id, '/')) >= 9 ? last(split(sqlServer002Id, '/')) : 'incorrectSegmentLength'
var purviewAccountName =  length(split(purviewId, '/')) >= 9 ? last(split(purviewId, '/')) : 'incorrectSegmentLength'
var datafactoryDefaultIntegrationRuntimeName = 'AutoResolveIntegrationRuntime'

// Resources
resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: datafactoryName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    globalParameters: {}
    #disable-next-line BCP037
    purviewConfiguration: {
      purviewResourceId: purviewId
    }
  }
}


resource datafactoryManagedIntegrationRuntime001 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  parent: datafactory
  name: datafactoryDefaultIntegrationRuntimeName
  properties: {
    type: 'Managed'
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
      }
    }
  }
}



resource datafactorySqlserver001LinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: '${replace(sqlDatabase001Name, '-', '')}'
  properties: {
    type: 'AzureSqlDatabase'
    annotations: []
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: datafactoryManagedIntegrationRuntime001.name
      parameters: {}
    }
    description: 'Sql Database for storing metadata'
    parameters: {}
    typeProperties: {
      connectionString: 'Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=${sqlServer001Name}${environment().suffixes.sqlServerHostname};Initial Catalog=${sqlDatabase001Name}'
    }
  }
}


resource datafactorySqlserver002LinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: '${replace(sqlDatabase002Name, '-', '')}'
  properties: {
    type: 'AzureSqlDatabase'
    annotations: []
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: datafactoryManagedIntegrationRuntime001.name
      parameters: {}
    }
    description: 'Sql Database for storing metadata'
    parameters: {}
    typeProperties: {
      connectionString: 'Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=${sqlServer002Name}${environment().suffixes.sqlServerHostname};Initial Catalog=${sqlDatabase002Name}'
    }
  }
}

resource datafactoryStorageRawLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: 'ingestStorage'

  properties: {
    type: 'AzureBlobFS'
    annotations: []
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: datafactoryManagedIntegrationRuntime001.name
      parameters: {}
    }
    description: 'Storage Account for raw data'
    parameters: {}
    typeProperties: {
      url: 'https://${storageName}.dfs.${environment().suffixes.storage}'
    }
  }
}

resource datafactorPurviewRestLinkService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: 'purvuewRest'

  properties: {
    type: 'HttpServer'
    annotations: []
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: datafactoryManagedIntegrationRuntime001.name
      parameters: {}
    }
    description: 'Purview Basic REST Endpoint'
    parameters: {}
    typeProperties: {
      url: 'https://${purviewAccountName}.purview.azure.com/'
    }
  }
}

resource datafactoryControlDS 'Microsoft.DataFactory/factories/datasets@2018-06-01'= {
  parent:datafactory
  name: 'MetadataDrivenCopyTask_0mc_ControlDS'
  properties: {
    type: 'AzureSqlTable'
    linkedServiceName: {
      referenceName: datafactorySqlserver001LinkedService.name
      type: 'LinkedServiceReference'
    }
    folder:{
      name:'MetadataDrivenCopyTask_0mc'
    }
    typeProperties:{
      schema: 'dbo'
      table: 'MainControlTable'
    }
  }
}


resource datafactoryDestinationDS 'Microsoft.DataFactory/factories/datasets@2018-06-01'= {
  parent:datafactory
  name: 'MetadataDrivenCopyTask_0mc_DestinationDS'
  properties: {
    type: 'DelimitedText'
    linkedServiceName: {
      referenceName: datafactoryStorageRawLinkedService.name
      type: 'LinkedServiceReference'
    }
    folder:{
      name:'MetadataDrivenCopyTask_0mc'
    }
    parameters:{
      cw_fileName :{
        type:'String'
      } 
      cw_folderPath: {
        type: 'String'
      }
      cw_fileSystem: {
          type: 'String'
      }
    }
    typeProperties:{
      columnDelimiter:','
      firstRowAsHeader:true
      location:{
        type: 'AzureBlobFSLocation'
        fileName: {
          value: '@dataset().cw_fileName'
          type: 'Expression'
        }
        folderPath: {
            value: '@dataset().cw_folderPath'
            type: 'Expression'
        }
        fileSystem: {
            value: '@dataset().cw_fileSystem'
            type: 'Expression'
        }
      }
    }
  }
}

resource datafactorySourceDS 'Microsoft.DataFactory/factories/datasets@2018-06-01'= {
  parent:datafactory
  name: 'MetadataDrivenCopyTask_0mc_SourceDS'
  properties: {
    type: 'AzureSqlTable'
    linkedServiceName: {
      referenceName: datafactorySqlserver002LinkedService.name
      type: 'LinkedServiceReference'
    }
    folder:{
      name:'MetadataDrivenCopyTask_0mc'
    }
    parameters:{
      cw_schema :{
        type:'String'
      } 
      cw_table: {
        type: 'String'
      }
    }
    typeProperties:{
      schema: {
        value: '@dataset().cw_schema'
        type: 'Expression'
      }
      table: {
        value: '@dataset().cw_table'
        type: 'Expression'
      }
    }
  }
}


resource datafactoryInsertFromPurviewMetadata 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: 'InsertFromPurviewMetadataomc2'
  parent:datafactory
  properties: {
    activities: [
      {
        name: 'Query Ingest Target'
        type: 'WebActivity'
        dependsOn: [
          {
            activity: 'Set Query_Body'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]

        userProperties: []
        typeProperties: {
          url: {
            value: '@variables(\'QueryURL\')'
            type: 'Expression'
          }
          connectVia: {
            referenceName: datafactoryManagedIntegrationRuntime001.name
            type: 'IntegrationRuntimeReference'
          }
          method: 'POST'
          headers: {}
          body: {
            value: '@variables(\'QueryBody\')'
            type: 'Expression'
          }
          authentication: {
            type: 'MSI'
            resource: 'https://purview.azure.net'
          }
        }
      }
      {
        name: 'Set Query_Body'
        type: 'SetVariable'
        dependsOn: [
          {
            activity: 'Set Get_QueryUrl'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          variableName: 'QueryBody'
          value: {
            value: '{\n    "keywords": null,\n    "limit": 10,\n    "filter": {\n        "classification": @{pipeline().parameters.MetadataDrivenCopyTaskTopName},\n        "includeSubClassifications": false\n    }\n\n}'
            type: 'Expression'
          }
        }
      }
      {
        name: 'Set Get_QueryUrl'
        type: 'SetVariable'
        dependsOn: [
          {
            activity: 'Delete Metadata'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          variableName: 'QueryURL'
          value: {
            value: '@concat(\'https://\',pipeline().parameters.purviewName,\'.purview.azure.com/catalog/api/search/query?api-version=2021-05-01-preview\')'
            type: 'Expression'
          }
        }
      }
      {
        name: 'ForEach1'
        type: 'ForEach'
        dependsOn: [
          {
            activity: 'Query Ingest Target'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          items: {
            value: '@activity(\'Query Ingest Target\').output.value'
            type: 'Expression'
          }
          activities: [
            {
              name: 'Get_Entity'
              type: 'WebActivity'
              dependsOn: []

              userProperties: []
              typeProperties: {
                url: {
                  value: '@concat(\'https://\',pipeline().parameters.purviewName,\'.purview.azure.com/catalog/api/atlas/v2/entity/guid/\',item().id,\'?api-version=2021-05-01-preview\')'
                  type: 'Expression'
                }
                connectVia: {
                  referenceName: datafactoryManagedIntegrationRuntime001.name
                  type: 'IntegrationRuntimeReference'
                }
                method: 'GET'
                headers: {}
                authentication: {
                  type: 'MSI'
                  resource: 'https://purview.azure.net'
                }
              }
            }
            {
              name: 'Get_Schema_Entity'
              type: 'WebActivity'
              dependsOn: [
                {
                  activity: 'Get_Entity'
                  dependencyConditions: [
                    'Succeeded'
                  ]
                }
              ]

              userProperties: []
              typeProperties: {
                url: {
                  value: '@concat(\'https://\',pipeline().parameters.purviewName,\'.purview.azure.com/catalog/api/atlas/v2/entity/guid/\',activity(\'Get_Entity\').output.entity.relationshipAttributes.dbSchema.guid,\'?api-version=2021-05-01-preview\')'
                  type: 'Expression'
                }
                connectVia: {
                  referenceName: datafactoryManagedIntegrationRuntime001.name
                  type: 'IntegrationRuntimeReference'
                }
                method: 'GET'
                headers: {}
                authentication: {
                  type: 'MSI'
                  resource: 'https://purview.azure.net'
                }
              }
            }
            {
              name: 'Get_db_Entity'
              type: 'WebActivity'
              dependsOn: [
                {
                  activity: 'Get_Schema_Entity'
                  dependencyConditions: [
                    'Succeeded'
                  ]
                }
              ]

              userProperties: []
              typeProperties: {
                url: {
                  value: '@concat(\'https://\',pipeline().parameters.purviewName,\'.purview.azure.com/catalog/api/atlas/v2/entity/guid/\',activity(\'Get_Schema_Entity\').output.entity.relationshipAttributes.db.guid,\'?api-version=2021-05-01-preview\')'
                  type: 'Expression'
                }
                connectVia: {
                  referenceName: datafactoryManagedIntegrationRuntime001.name
                  type: 'IntegrationRuntimeReference'
                }
                method: 'GET'
                headers: {}
                authentication: {
                  type: 'MSI'
                  resource: 'https://purview.azure.net'
                }
              }
            }
            {
              name: 'Get_Server_Entity'
              type: 'WebActivity'
              dependsOn: [
                {
                  activity: 'Get_db_Entity'
                  dependencyConditions: [
                    'Succeeded'
                  ]
                }
              ]

              userProperties: []
              typeProperties: {
                url: {
                  value: '@concat(\'https://\',pipeline().parameters.purviewName,\'.purview.azure.com/catalog/api/atlas/v2/entity/guid/\',activity(\'Get_db_Entity\').output.entity.relationshipAttributes.server.guid,\'?api-version=2021-05-01-preview\')'
                  type: 'Expression'
                }
                connectVia: {
                  referenceName: datafactoryManagedIntegrationRuntime001.name
                  type: 'IntegrationRuntimeReference'
                }
                method: 'GET'
                headers: {}
                authentication: {
                  type: 'MSI'
                  resource: 'https://purview.azure.net'
                }
              }
            }
            {
              name: 'Insert Metadata'
              type: 'SqlServerStoredProcedure'
              dependsOn: [
                {
                  activity: 'Get_Server_Entity'
                  dependencyConditions: [
                    'Succeeded'
                  ]
                }
              ]

              userProperties: []
              typeProperties: {
                storedProcedureName: '[dbo].[usp_insert_metadata]'
                storedProcedureParameters: {
                  databaseName: {
                    value: {
                      value: '@activity(\'Get_db_Entity\').output.entity.attributes.name'
                      type: 'Expression'
                    }
                    type: 'String'
                  }
                  fileSystemName: {
                    value: {
                      value: '@pipeline().parameters.fileSystemName'
                      type: 'Expression'
                    }
                    type: 'String'
                  }
                  rootFolderPath: {
                    value: {
                      value: '@pipeline().parameters.rootFolderPath'
                      type: 'Expression'
                    }
                    type: 'String'
                  }
                  schemaName: {
                    value: {
                      value: '@activity(\'Get_Schema_Entity\').output.entity.attributes.name'
                      type: 'Expression'
                    }
                    type: 'String'
                  }
                  serverName: {
                    value: {
                      value: '@activity(\'Get_Server_Entity\').output.entity.attributes.name'
                      type: 'Expression'
                    }
                    type: 'String'
                  }
                  tableName: {
                    value: {
                      value: '@activity(\'Get_Entity\').output.entity.attributes.name'
                      type: 'Expression'
                    }
                    type: 'String'
                  }
                  topLevelPipelineName: {
                    value: {
                      value: '@pipeline().parameters.MetadataDrivenCopyTaskTopName'
                      type: 'Expression'
                    }
                    type: 'String'
                  }
                  metadataControleTable: {
                    value: {
                      value: '@pipeline().parameters.MainControlTableName'
                      type: 'Expression'
                    }
                    type: 'String'
                  }
                }
              }
              linkedServiceName: {
                referenceName: datafactorySqlserver001LinkedService.name
                type: 'LinkedServiceReference'
              }
            }
          ]
        }
      }
      {
        name: 'Delete Metadata'
        type: 'SqlServerStoredProcedure'
        dependsOn: []

        userProperties: []
        typeProperties: {
          storedProcedureName: '[dbo].[usp_delete_metadata]'
          storedProcedureParameters: {
            metadataControleTable: {
              value: {
                value: '@pipeline().parameters.MainControlTableName'
                type: 'Expression'
              }
              type: 'String'
            }
            MetadataDrivenCopyTaskTopName: {
              value: {
                value: '@pipeline().parameters.MetadataDrivenCopyTaskTopName'
                type: 'Expression'
              }
              type: 'String'
            }
          }
        }
        linkedServiceName: {
          referenceName: datafactorySqlserver001LinkedService.name
          type: 'LinkedServiceReference'
        }
      }
    ]

    parameters: {
      purviewName: {
        type: 'String'
      }
      MetadataDrivenCopyTaskTopName: {
        type: 'String'
        defaultValue: 'MetadataDrivenCopyTask_0mc_TopLevel'
      }
      MainControlTableName: {
        type: 'String'
        defaultValue: 'MainControlTable'
      }
      rootFolderPath: {
        type: 'String'
        defaultValue: 'landing'
      }
      fileSystemName: {
        type: 'String'
        defaultValue: 'data'
      }
    }
    variables: {
      QueryURL: {
        type: 'String'
      }
      QueryBody: {
        type: 'String'
      }
    }
  }
}

resource factoryName_MetadataDrivenCopyTask_0mc_BottomLevel 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: 'MetadataDrivenCopyTask_0mc_BottomLevel'
  parent:datafactory
  properties: {
    description: 'This pipeline will copy objects from one group. The objects belonging to this group will be copied parallelly.'
    activities: [
      {
        name: 'ListObjectsFromOneGroup'
        description: 'List objects from one group and iterate each of them to downstream activities'
        type: 'ForEach'
        dependsOn: []
        userProperties: []
        typeProperties: {
          items: {
            value: '@pipeline().parameters.ObjectsPerGroupToCopy'
            type: 'Expression'
          }
          activities: [
            {
              name: 'RouteJobsBasedOnLoadingBehavior'
              description: 'Check the loading behavior for each object if it requires full load or incremental load. If it is Default or FullLoad case, do full load. If it is DeltaLoad case, do incremental load via watermark column to identify changes.'
              type: 'Switch'
              dependsOn: []
              userProperties: []
              typeProperties: {
                on: {
                  value: '@json(item().DataLoadingBehaviorSettings).dataLoadingBehavior'
                  type: 'Expression'
                }
                cases: [
                  {
                    value: 'FullLoad'
                    activities: [
                      {
                        name: 'FullLoadOneObject'
                        description: 'Take a full snapshot on this object and copy it to the destination'
                        type: 'Copy'
                        dependsOn: []
                        userProperties: [
                          {
                            name: 'Source'
                            value: '@{json(item().SourceObjectSettings).schema}.@{json(item().SourceObjectSettings).table}'
                          }
                          {
                            name: 'Destination'
                            value: '@{json(item().SinkObjectSettings).fileSystem}/landing/@{formatDateTime(pipeline().TriggerTime,\'yyyy\')}-@{formatDateTime(pipeline().TriggerTime,\'MM\')}-@{formatDateTime(pipeline().TriggerTime,\'dd\')}/@{json(item().SinkObjectSettings).fileName}'
                          }
                        ]
                        typeProperties: {
                          source: {
                            type: 'AzureSqlSource'
                            sqlReaderQuery: {
                              value: '@json(item().CopySourceSettings).sqlReaderQuery'
                              type: 'Expression'
                            }
                            partitionOption: {
                              value: '@json(item().CopySourceSettings).partitionOption'
                              type: 'Expression'
                            }
                            partitionSettings: {
                              partitionColumnName: {
                                value: '@json(item().CopySourceSettings).partitionColumnName'
                                type: 'Expression'
                              }
                              partitionUpperBound: {
                                value: '@json(item().CopySourceSettings).partitionUpperBound'
                                type: 'Expression'
                              }
                              partitionLowerBound: {
                                value: '@json(item().CopySourceSettings).partitionLowerBound'
                                type: 'Expression'
                              }
                              partitionNames: '@json(item().CopySourceSettings).partitionNames'
                            }
                          }
                          sink: {
                            type: 'DelimitedTextSink'
                            storeSettings: {
                              type: 'AzureBlobFSWriteSettings'
                            }
                            formatSettings: {
                              type: 'DelimitedTextWriteSettings'
                              quoteAllText: true
                              fileExtension: '.txt'
                            }
                          }
                          enableStaging: false
                          validateDataConsistency: false
                          translator: {
                            value: '@json(item().CopyActivitySettings).translator'
                            type: 'Expression'
                          }
                        }
                        inputs: [
                          {
                            referenceName: datafactorySourceDS.name
                            type: 'DatasetReference'
                            parameters: {
                              cw_schema: {
                                value: '@json(item().SourceObjectSettings).schema'
                                type: 'Expression'
                              }
                              cw_table: {
                                value: '@json(item().SourceObjectSettings).table'
                                type: 'Expression'
                              }
                            }
                          }
                        ]
                        outputs: [
                          {
                            referenceName: datafactoryDestinationDS.name
                            type: 'DatasetReference'
                            parameters: {
                              cw_fileName: {
                                value: '@json(item().SinkObjectSettings).fileName'
                                type: 'Expression'
                              }
                              cw_folderPath: {
                                value: '@{json(item().SinkObjectSettings).folderPath}/@{formatDateTime(pipeline().TriggerTime,\'yyyy\')}-@{formatDateTime(pipeline().TriggerTime,\'MM\')}-@{formatDateTime(pipeline().TriggerTime,\'dd\')}'
                                type: 'Expression'
                              }
                              cw_fileSystem: {
                                value: '@json(item().SinkObjectSettings).fileSystem'
                                type: 'Expression'
                              }
                            }
                          }
                        ]
                      }
                    ]
                  }
                  {
                    value: 'DeltaLoad'
                    activities: [
                      {
                        name: 'GetMaxWatermarkValue'
                        description: 'Query the source object to get the max value from watermark column'
                        type: 'Lookup'
                        dependsOn: []
                        userProperties: []
                        typeProperties: {
                          source: {
                            type: 'AzureSqlSource'
                            sqlReaderQuery: {
                              value: 'select max(@{json(item().DataLoadingBehaviorSettings).watermarkColumnName}) as CurrentMaxWaterMarkColumnValue from [@{json(item().SourceObjectSettings).schema}].[@{json(item().SourceObjectSettings).table}]'
                              type: 'Expression'
                            }
                            partitionOption: 'None'
                          }
                          dataset: {
                            referenceName: datafactorySourceDS.name
                            type: 'DatasetReference'
                            parameters: {
                              cw_schema: {
                                value: '@json(item().SourceObjectSettings).schema'
                                type: 'Expression'
                              }
                              cw_table: {
                                value: '@json(item().SourceObjectSettings).table'
                                type: 'Expression'
                              }
                            }
                          }
                        }
                      }
                      {
                        name: 'SetWatermarkValueQuoteChar'
                        type: 'SetVariable'
                        dependsOn: [
                          {
                            activity: 'GetMaxWatermarkValue'
                            dependencyConditions: [
                              'Succeeded'
                            ]
                          }
                        ]
                        userProperties: []
                        typeProperties: {
                          variableName: 'WatermarkValueQuoteChar'
                          value: {
                            value: '@if(contains(json(item().DataLoadingBehaviorSettings).watermarkColumnType, \'Int\'), \'\',\'\'\'\')'
                            type: 'Expression'
                          }
                        }
                      }
                      {
                        name: 'DeltaLoadOneObject'
                        description: 'Copy the changed data only from last time via comparing the value in watermark column to identify changes.'
                        type: 'Copy'
                        dependsOn: [
                          {
                            activity: 'SetWatermarkValueQuoteChar'
                            dependencyConditions: [
                              'Succeeded'
                            ]
                          }
                        ]

                        userProperties: [
                          {
                            name: 'Source'
                            value: '@{json(item().SourceObjectSettings).schema}.@{json(item().SourceObjectSettings).table}'
                          }
                          {
                            name: 'Destination'
                            value: '@{json(item().SinkObjectSettings).fileSystem}/landing/@{formatDateTime(pipeline().TriggerTime,\'yyyy\')}-@{formatDateTime(pipeline().TriggerTime,\'MM\')}-@{formatDateTime(pipeline().TriggerTime,\'dd\')}/@{json(item().SinkObjectSettings).fileName}'
                          }
                        ]
                        typeProperties: {
                          source: {
                            type: 'AzureSqlSource'
                            sqlReaderQuery: {
                              value: 'select * from [@{json(item().SourceObjectSettings).schema}].[@{json(item().SourceObjectSettings).table}]\n                    where @{json(item().DataLoadingBehaviorSettings).watermarkColumnName}\n                    > @{variables(\'WatermarkValueQuoteChar\')}@{json(item().DataLoadingBehaviorSettings).watermarkColumnStartValue}@{variables(\'WatermarkValueQuoteChar\')}\n                    and @{json(item().DataLoadingBehaviorSettings).watermarkColumnName}\n                    <= @{variables(\'WatermarkValueQuoteChar\')}@{activity(\'GetMaxWatermarkValue\').output.firstRow.CurrentMaxWaterMarkColumnValue}@{variables(\'WatermarkValueQuoteChar\')}'
                              type: 'Expression'
                            }
                            partitionOption: {
                              value: '@json(item().CopySourceSettings).partitionOption'
                              type: 'Expression'
                            }
                            partitionSettings: {
                              partitionColumnName: {
                                value: '@json(item().CopySourceSettings).partitionColumnName'
                                type: 'Expression'
                              }
                              partitionUpperBound: {
                                value: '@json(item().CopySourceSettings).partitionUpperBound'
                                type: 'Expression'
                              }
                              partitionLowerBound: {
                                value: '@json(item().CopySourceSettings).partitionLowerBound'
                                type: 'Expression'
                              }
                              partitionNames: '@json(item().CopySourceSettings).partitionNames'
                            }
                          }
                          sink: {
                            type: 'DelimitedTextSink'
                            storeSettings: {
                              type: 'AzureBlobFSWriteSettings'
                            }
                            formatSettings: {
                              type: 'DelimitedTextWriteSettings'
                              quoteAllText: true
                              fileExtension: '.txt'
                            }
                          }
                          enableStaging: false
                          validateDataConsistency: false
                          translator: {
                            value: '@json(item().CopyActivitySettings).translator'
                            type: 'Expression'
                          }
                        }
                        inputs: [
                          {
                            referenceName: datafactorySourceDS.name
                            type: 'DatasetReference'
                            parameters: {
                              cw_schema: {
                                value: '@json(item().SourceObjectSettings).schema'
                                type: 'Expression'
                              }
                              cw_table: {
                                value: '@json(item().SourceObjectSettings).table'
                                type: 'Expression'
                              }
                            }
                          }
                        ]
                        outputs: [
                          {
                            referenceName: datafactoryDestinationDS.name
                            type: 'DatasetReference'
                            parameters: {
                              cw_fileName: {
                                value: '@{json(item().SinkObjectSettings).fileName}-@{json(item().DataLoadingBehaviorSettings).watermarkColumnStartValue}-@{activity(\'GetMaxWatermarkValue\').output.firstRow.CurrentMaxWaterMarkColumnValue}'
                                type: 'Expression'
                              }
                              cw_folderPath: {
                                value: 'landing/@{formatDateTime(pipeline().TriggerTime,\'yyyy\')}-@{formatDateTime(pipeline().TriggerTime,\'MM\')}-@{formatDateTime(pipeline().TriggerTime,\'dd\')}'
                                type: 'Expression'
                              }
                              cw_fileSystem: {
                                value: '@json(item().SinkObjectSettings).fileSystem'
                                type: 'Expression'
                              }
                            }
                          }
                        ]
                      }
                      {
                        name: 'UpdateWatermarkColumnValue'
                        type: 'SqlServerStoredProcedure'
                        dependsOn: [
                          {
                            activity: 'DeltaLoadOneObject'
                            dependencyConditions: [
                              'Succeeded'
                            ]
                          }
                        ]
                        userProperties: []
                        typeProperties: {
                          storedProcedureName: '[dbo].[UpdateWatermarkColumnValue_0mc]'
                          storedProcedureParameters: {
                            Id: {
                              value: {
                                value: '@item().Id'
                                type: 'Expression'
                              }
                              type: 'Int'
                            }
                            watermarkColumnStartValue: {
                              value: {
                                value: '@activity(\'GetMaxWatermarkValue\').output.firstRow.CurrentMaxWaterMarkColumnValue'
                                type: 'Expression'
                              }
                              type: 'String'
                            }
                          }
                        }
                        linkedServiceName: {
                          referenceName: datafactorySqlserver001LinkedService.name
                          type: 'LinkedServiceReference'
                        }
                      }
                    ]
                  }
                ]
                defaultActivities: [
                  {
                    name: 'DefaultFullLoadOneObject'
                    description: 'Take a full snapshot on this object and copy it to the destination'
                    type: 'Copy'
                    dependsOn: []
                    userProperties: [
                      {
                        name: 'Source'
                        value: '@{json(item().SourceObjectSettings).schema}.@{json(item().SourceObjectSettings).table}'
                      }
                      {
                        name: 'Destination'
                        value: '@{json(item().SinkObjectSettings).fileSystem}/landing/@{formatDateTime(pipeline().TriggerTime,\'yyyy\')}-@{formatDateTime(pipeline().TriggerTime,\'MM\')}-@{formatDateTime(pipeline().TriggerTime,\'dd\')}/@{json(item().SinkObjectSettings).fileName}'
                      }
                    ]
                    typeProperties: {
                      source: {
                        type: 'AzureSqlSource'
                        sqlReaderQuery: {
                          value: '@json(item().CopySourceSettings).sqlReaderQuery'
                          type: 'Expression'
                        }
                        partitionOption: {
                          value: '@json(item().CopySourceSettings).partitionOption'
                          type: 'Expression'
                        }
                        partitionSettings: {
                          partitionColumnName: {
                            value: '@json(item().CopySourceSettings).partitionColumnName'
                            type: 'Expression'
                          }
                          partitionUpperBound: {
                            value: '@json(item().CopySourceSettings).partitionUpperBound'
                            type: 'Expression'
                          }
                          partitionLowerBound: {
                            value: '@json(item().CopySourceSettings).partitionLowerBound'
                            type: 'Expression'
                          }
                          partitionNames: '@json(item().CopySourceSettings).partitionNames'
                        }
                      }
                      sink: {
                        type: 'DelimitedTextSink'
                        storeSettings: {
                          type: 'AzureBlobFSWriteSettings'
                        }
                        formatSettings: {
                          type: 'DelimitedTextWriteSettings'
                          quoteAllText: true
                          fileExtension: '.txt'
                        }
                      }
                      enableStaging: false
                      validateDataConsistency: false
                      translator: {
                        value: '@json(item().CopyActivitySettings).translator'
                        type: 'Expression'
                      }
                    }
                    inputs: [
                      {
                        referenceName: datafactorySourceDS.name
                        type: 'DatasetReference'
                        parameters: {
                          cw_schema: {
                            value: '@json(item().SourceObjectSettings).schema'
                            type: 'Expression'
                          }
                          cw_table: {
                            value: '@json(item().SourceObjectSettings).table'
                            type: 'Expression'
                          }
                        }
                      }
                    ]
                    outputs: [
                      {
                        referenceName: datafactoryDestinationDS.name
                        type: 'DatasetReference'
                        parameters: {
                          cw_fileName: {
                            value: '@json(item().SinkObjectSettings).fileName'
                            type: 'Expression'
                          }
                          cw_folderPath: {
                            value: 'landing/@{formatDateTime(pipeline().TriggerTime,\'yyyy\')}-@{formatDateTime(pipeline().TriggerTime,\'MM\')}-@{formatDateTime(pipeline().TriggerTime,\'dd\')}'
                            type: 'Expression'
                          }
                          cw_fileSystem: {
                            value: '@json(item().SinkObjectSettings).fileSystem'
                            type: 'Expression'
                          }
                        }
                      }
                    ]
                  }
                ]
              }
            }
          ]
        }
      }
    ]
    policy: {
      elapsedTimeMetric: {}
    }
    parameters: {
      ObjectsPerGroupToCopy: {
        type: 'Array'
      }
      windowStart: {
        type: 'String'
      }
    }
    variables: {
      WatermarkValueQuoteChar: {
        type: 'String'
      }
    }
    folder: {
      name: 'MetadataDrivenCopyTask_0mc'
    }
    annotations: []
  }

}


resource factoryName_MetadataDrivenCopyTask_0mc_MiddleLevel 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: 'MetadataDrivenCopyTask_0mc_MiddleLevel'
  parent:datafactory
  properties: {
    description: 'This pipeline will copy one batch of objects. The objects belonging to this batch will be copied parallelly.'
    activities: [
      {
        name: 'DivideOneBatchIntoMultipleGroups'
        description: 'Divide objects from single batch into multiple sub parallel groups to avoid reaching the output limit of lookup activity.'
        type: 'ForEach'
        dependsOn: []
        userProperties: []
        typeProperties: {
          items: {
            value: '@range(0, add(div(pipeline().parameters.SumOfObjectsToCopyForCurrentBatch, pipeline().parameters.MaxNumberOfObjectsReturnedFromLookupActivity),\n                    if(equals(mod(pipeline().parameters.SumOfObjectsToCopyForCurrentBatch, pipeline().parameters.MaxNumberOfObjectsReturnedFromLookupActivity), 0), 0, 1)))'
            type: 'Expression'
          }
          isSequential: false
          batchCount: 50
          activities: [
            {
              name: 'GetObjectsPerGroupToCopy'
              description: 'Get objects (tables etc.) from control table required to be copied in this group. The order of objects to be copied following the TaskId in control table (ORDER BY [TaskId] DESC).'
              type: 'Lookup'
              dependsOn: []
              userProperties: []
              typeProperties: {
                source: {
                  type: 'AzureSqlSource'
                  sqlReaderQuery: {
                    value: 'WITH OrderedControlTable AS (\n                             SELECT *, ROW_NUMBER() OVER (ORDER BY [TaskId], [Id] DESC) AS RowNumber\n                             FROM @{pipeline().parameters.MainControlTableName}\n                             where TopLevelPipelineName = \'@{pipeline().parameters.TopLevelPipelineName}\'\n                             and TriggerName like \'%@{pipeline().parameters.TriggerName}%\' and CopyEnabled = 1)\n                             SELECT * FROM OrderedControlTable WHERE RowNumber BETWEEN @{add(mul(int(item()),pipeline().parameters.MaxNumberOfObjectsReturnedFromLookupActivity),\n                             add(mul(pipeline().parameters.SumOfObjectsToCopyForCurrentBatch, pipeline().parameters.CurrentSequentialNumberOfBatch), 1))}\n                             AND @{min(add(mul(int(item()), pipeline().parameters.MaxNumberOfObjectsReturnedFromLookupActivity), add(mul(pipeline().parameters.SumOfObjectsToCopyForCurrentBatch, pipeline().parameters.CurrentSequentialNumberOfBatch),\n                             pipeline().parameters.MaxNumberOfObjectsReturnedFromLookupActivity)),\n                            mul(pipeline().parameters.SumOfObjectsToCopyForCurrentBatch, add(pipeline().parameters.CurrentSequentialNumberOfBatch,1)), pipeline().parameters.SumOfObjectsToCopy)}'
                    type: 'Expression'
                  }
                  partitionOption: 'None'
                }
                dataset: {
                  referenceName: datafactoryControlDS.name
                  type: 'DatasetReference'
                  parameters: {}
                }
                firstRowOnly: false
              }
            }
            {
              name: 'CopyObjectsInOneGroup'
              description: 'Execute another pipeline to copy objects from one group. The objects belonging to this group will be copied parallelly.'
              type: 'ExecutePipeline'
              dependsOn: [
                {
                  activity: 'GetObjectsPerGroupToCopy'
                  dependencyConditions: [
                    'Succeeded'
                  ]
                }
              ]
              userProperties: []
              typeProperties: {
                pipeline: {
                  referenceName: factoryName_MetadataDrivenCopyTask_0mc_BottomLevel.name
                  type: 'PipelineReference'
                }
                waitOnCompletion: true
                parameters: {
                  ObjectsPerGroupToCopy: {
                    value: '@activity(\'GetObjectsPerGroupToCopy\').output.value'
                    type: 'Expression'
                  }
                  windowStart: {
                    value: '@pipeline().parameters.windowStart'
                    type: 'Expression'
                  }
                }
              }
            }
          ]
        }
      }
    ]
    policy: {
      elapsedTimeMetric: {}
    }
    parameters: {
      MaxNumberOfObjectsReturnedFromLookupActivity: {
        type: 'Int'
      }
      TopLevelPipelineName: {
        type: 'String'
      }
      TriggerName: {
        type: 'String'
      }
      CurrentSequentialNumberOfBatch: {
        type: 'Int'
      }
      SumOfObjectsToCopy: {
        type: 'Int'
      }
      SumOfObjectsToCopyForCurrentBatch: {
        type: 'Int'
      }
      MainControlTableName: {
        type: 'String'
      }
      windowStart: {
        type: 'String'
      }
    }
    folder: {
      name: 'MetadataDrivenCopyTask_0mc'
    }
    annotations: []
  }
}

resource factoryName_MetadataDrivenCopyTask_0mc_TopLevel 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: 'MetadataDrivenCopyTask_0mc_TopLevel'
  parent:datafactory
  properties: {
    description: 'This pipeline will count the total number of objects (tables etc.) required to be copied in this run, come up with the number of sequential batches based on the max allowed concurrent copy task, and then execute another pipeline to copy different batches sequentially.'
    activities: [
      {
        name: 'GetSumOfObjectsToCopy'
        description: 'Count the total number of objects (tables etc.) required to be copied in this run.'
        type: 'Lookup'
        dependsOn: []
        userProperties: []
        typeProperties: {
          source: {
            type: 'AzureSqlSource'
            sqlReaderQuery: {
              value: 'SELECT count(*) as count FROM @{pipeline().parameters.MainControlTableName} where TopLevelPipelineName=\'@{pipeline().Pipeline}\' and CopyEnabled = 1'
              type: 'Expression'
            }
            partitionOption: 'None'
          }
          dataset: {
            referenceName: datafactoryControlDS.name
            type: 'DatasetReference'
            parameters: {}
          }
        }
      }
      {
        name: 'CopyBatchesOfObjectsSequentially'
        description: 'Come up with the number of sequential batches based on the max allowed concurrent copy tasks, and then execute another pipeline to copy different batches sequentially.'
        type: 'ForEach'
        dependsOn: [
          {
            activity: 'GetSumOfObjectsToCopy'
            dependencyConditions: [
              'Succeeded'
            ]
          }
        ]
        userProperties: []
        typeProperties: {
          items: {
            value: '@range(0, add(div(activity(\'GetSumOfObjectsToCopy\').output.firstRow.count,\n                    pipeline().parameters.MaxNumberOfConcurrentTasks),\n                    if(equals(mod(activity(\'GetSumOfObjectsToCopy\').output.firstRow.count,\n                    pipeline().parameters.MaxNumberOfConcurrentTasks), 0), 0, 1)))'
            type: 'Expression'
          }
          isSequential: true
          activities: [
            {
              name: 'CopyObjectsInOneBtach'
              description: 'Execute another pipeline to copy one batch of objects. The objects belonging to this batch will be copied parallelly.'
              type: 'ExecutePipeline'
              dependsOn: []
              userProperties: []
              typeProperties: {
                pipeline: {
                  referenceName: factoryName_MetadataDrivenCopyTask_0mc_MiddleLevel.name
                  type: 'PipelineReference'
                }
                waitOnCompletion: true
                parameters: {
                  MaxNumberOfObjectsReturnedFromLookupActivity: {
                    value: '@pipeline().parameters.MaxNumberOfObjectsReturnedFromLookupActivity'
                    type: 'Expression'
                  }
                  TopLevelPipelineName: {
                    value: '@{pipeline().Pipeline}'
                    type: 'Expression'
                  }
                  TriggerName: {
                    value: '@{pipeline().TriggerName}'
                    type: 'Expression'
                  }
                  CurrentSequentialNumberOfBatch: {
                    value: '@item()'
                    type: 'Expression'
                  }
                  SumOfObjectsToCopy: {
                    value: '@activity(\'GetSumOfObjectsToCopy\').output.firstRow.count'
                    type: 'Expression'
                  }
                  SumOfObjectsToCopyForCurrentBatch: {
                    value: '@min(pipeline().parameters.MaxNumberOfConcurrentTasks, activity(\'GetSumOfObjectsToCopy\').output.firstRow.count)'
                    type: 'Expression'
                  }
                  MainControlTableName: {
                    value: '@pipeline().parameters.MainControlTableName'
                    type: 'Expression'
                  }
                  windowStart: {
                    value: '@pipeline().parameters.windowStart'
                    type: 'Expression'
                  }
                }
              }
            }
          ]
        }
      }
    ]
    policy: {
      elapsedTimeMetric: {}
    }
    parameters: {
      MaxNumberOfObjectsReturnedFromLookupActivity: {
        type: 'Int'
        defaultValue: 5000
      }
      MaxNumberOfConcurrentTasks: {
        type: 'Int'
        defaultValue: 20
      }
      MainControlTableName: {
        type: 'String'
        defaultValue: 'dbo.MainControlTable'
      }
      windowStart: {
        type: 'String'
      }
    }
    folder: {
      name: 'MetadataDrivenCopyTask_0mc'
    }
    annotations: [
      'MetadataDrivenSolution'
    ]
  }

}


// Outputs
output datafactoryId string = datafactory.id
