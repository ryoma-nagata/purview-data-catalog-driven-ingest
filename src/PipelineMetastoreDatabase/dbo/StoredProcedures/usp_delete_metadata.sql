CREATE PROCEDURE [dbo].[usp_delete_metadata](
    @metadataControleTable nvarchar(100)
    ,@MetadataDrivenCopyTaskTopName nvarchar(100))

AS


BEGIN  
    -- DECLARE @metadataControleTable nvarchar(100) = 'testTable',@MetadataDrivenCopyTaskTopName nvarchar(100) = 'TestPName'
   


    DECLARE @sql nvarchar(max) =N'DELETE FROM ' + @metadataControleTable + ' WHERE [TopLevelPipelineName]='''   +@MetadataDrivenCopyTaskTopName + ''''
    exec(@sql)

	RETURN 0


END;

GO

