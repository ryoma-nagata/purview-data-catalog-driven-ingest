CREATE PROCEDURE [dbo].[usp_insert_metadata](@serverName NVARCHAR(50) ,
        @databaseName NVARCHAR(50),
        @schemaName NVARCHAR(50),
        @tableName NVARCHAR(50),
        @fileSystemName NVARCHAR(50),
        @rootFolderPath NVARCHAR(50),
        @topLevelPipelineName NVARCHAR(50) ,
        @metadataControleTable nvarchar(100)
)

AS

BEGIN  

    -- DECLARE 
    --     @serverName NVARCHAR(50) = 'testServer',
    --     @databaseName NVARCHAR(50) = 'testDB',
    --     @schemaName NVARCHAR(50) = 'testShema',
    --     @tableName NVARCHAR(50) = 'testTable',
    --     @fileSystemName NVARCHAR(50) = 'testFilesystem',
    --     @topLevelPipelineName NVARCHAR(50) = 'MetadataDrivenCopyTask_TopLevel',
    --     @rootFolderPath NVARCHAR(50) = 'testRoot',
    --     @metadataControleTable nvarchar(100)= 'MainControlTable'


	SET NOCOUNT ON;
    CREATE TABLE [dbo].[#MainControlTable] (
    [SourceObjectSettings]         NVARCHAR (MAX) NULL,
    [SourceConnectionSettingsName] VARCHAR (MAX)  NULL,
    [CopySourceSettings]           NVARCHAR (MAX) NULL,
    [SinkObjectSettings]           NVARCHAR (MAX) NULL,
    [SinkConnectionSettingsName]   VARCHAR (MAX)  NULL,
    [CopySinkSettings]             NVARCHAR (MAX) NULL,
    [CopyActivitySettings]         NVARCHAR (MAX) NULL,
    [TopLevelPipelineName]         VARCHAR (MAX)  NULL,
    [TriggerName]                  NVARCHAR (MAX) NULL,
    [DataLoadingBehaviorSettings]  NVARCHAR (MAX) NULL,
    [TaskId]                       INT            NULL,
    [CopyEnabled]                  BIT            NULL
);

    DECLARE @MainControlMetadata NVARCHAR(max)  = N'{
    "SourceObjectSettings": {
        "schema": "'+ @schemaName + N'",
        "table": "'+ @tableName + N'"
    },
    "SinkObjectSettings": {
        "fileName": "'+ @schemaName + @tableName + N'.csv",
        "folderPath": "'+  @rootFolderPath + N'/'+  @serverName + N'/'+ @databaseName + N'",
        "fileSystem": "'+ @fileSystemName + N'"
    },
    "CopySourceSettings": {
        "partitionOption": "None",
        "sqlReaderQuery": null,
        "partitionLowerBound": null,
        "partitionUpperBound": null,
        "partitionColumnName": null,
        "partitionNames": null
    },
    "CopyActivitySettings": {
        "translator": null
    },
    "TopLevelPipelineName": "'+ @topLevelPipelineName + N'",
    "TriggerName": [
        "Sandbox",
        "Manual",
        "Trigger"
    ],
    "DataLoadingBehaviorSettings": {
        "dataLoadingBehavior": "FullLoad"
    },
    "TaskId": 0,
    "CopyEnabled": 1
    }'
    
    INSERT INTO [dbo].[#MainControlTable] (
    [SourceObjectSettings],
    [SourceConnectionSettingsName],
    [CopySourceSettings],
    [SinkObjectSettings],
    [SinkConnectionSettingsName],
    [CopySinkSettings],
    [CopyActivitySettings],
    [TopLevelPipelineName],
    [TriggerName],
    [DataLoadingBehaviorSettings],
    [TaskId],
    [CopyEnabled])
    SELECT * FROM OPENJSON(@MainControlMetadata)
        WITH ([SourceObjectSettings] [nvarchar](max) AS JSON,
        [SourceConnectionSettingsName] [varchar](max),
        [CopySourceSettings] [nvarchar](max) AS JSON,
        [SinkObjectSettings] [nvarchar](max) AS JSON,
        [SinkConnectionSettingsName] [varchar](max),
        [CopySinkSettings] [nvarchar](max) AS JSON,
        [CopyActivitySettings] [nvarchar](max) AS JSON,
        [TopLevelPipelineName] [varchar](max),
        [TriggerName] [nvarchar](max) AS JSON,
        [DataLoadingBehaviorSettings] [nvarchar](max) AS JSON,
        [TaskId] [int],
        [CopyEnabled] [bit]);
    
    DECLARE @sql NVARCHAR(max) = '
    INSERT INTO [dbo].['+ @metadataControleTable +'] (
    [SourceObjectSettings],
    [SourceConnectionSettingsName],
    [CopySourceSettings],
    [SinkObjectSettings],
    [SinkConnectionSettingsName],
    [CopySinkSettings],
    [CopyActivitySettings],
    [TopLevelPipelineName],
    [TriggerName],
    [DataLoadingBehaviorSettings],
    [TaskId],
    [CopyEnabled])
    SELECT * FROM #MainControlTable
    '
    exec(@sql)
	RETURN 0


END;

GO

