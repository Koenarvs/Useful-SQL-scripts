ALTER PROCEDURE [ETL].[ValidateTableExists] (@ServerName VARCHAR(MAX), @DBName VARCHAR(MAX), @SchemaName VARCHAR(MAX), @TableName VARCHAR(MAX)) 

AS

	DECLARE	@LogNotes			NVARCHAR(MAX)
		,	@ValidationPassed	INT = 0
		,	@SQLString			NVARCHAR(MAX)
		,	@ParamDefinition	NVARCHAR(MAX)

/*	Testing
		,	@ServerName			VARCHAR(MAX)
		,	@DBName				VARCHAR(MAX)
		,	@SchemaName			VARCHAR(MAX)
		,	@TableName			VARCHAR(MAX)
	
	SET		@ServerName	= 'CMDB'
	SET		@DBName		= 'CareManagement'
	SET		@SchemaName	= 'dbo'
	SET		@TableName	= 'Episodes'
--*/
	IF @ServerName IS NOT NULL 
		BEGIN 
			IF @ServerName NOT IN (SELECT [name] FROM sys.servers WHERE is_linked = 1 UNION SELECT @@SERVERNAME)
				BEGIN
					SET @LogNotes = CONCAT('The Server ',@ServerName,' is not listed as an available server in this instance.')
				END
		END

	IF @DBName IS NOT NULL AND @LogNotes IS NULL
		BEGIN	
				SET @ParamDefinition	=	N'	@LogNotesOUT VARCHAR(MAX) OUTPUT'
				SET @SQLString			=	N'IF (SELECT CASE WHEN '''+@DBName+''' IN ( SELECT [name] FROM ['+CASE WHEN @ServerName IS NULL THEN @@SERVERNAME ELSE @ServerName END+'].Master.sys.databases )THEN 1 ELSE 0 END) = 0
												BEGIN
													SET @LogNotesOUT = CONCAT(''The Database '','''+@DBName+''','' is not listed as available on the server '','''+CASE WHEN @ServerName IS NULL THEN @@SERVERNAME ELSE @ServerName END+''',''.'')
												END'
				EXECUTE sp_executesql 
					@SQLString, 
					@ParamDefinition, 
					@LogNotesOUT=@LogNotes OUTPUT
		END

	IF @SchemaName IS NOT NULL AND @LogNotes IS NULL
		BEGIN 
				SET @ParamDefinition	=	N'	@LogNotesOUT VARCHAR(MAX) OUTPUT'
				SET @SQLString			=	N'IF (SELECT CASE WHEN '''+@SchemaName+''' IN ( SELECT [name] FROM ['+CASE WHEN @ServerName IS NULL THEN @@SERVERNAME ELSE @ServerName END+'].['+@DBName+'].sys.schemas )THEN 1 ELSE 0 END) = 0
												BEGIN
													 SET @LogNotesOUT = CONCAT(''The Schema '','''+@SchemaName+''','' is not listed as available for '','''+CASE WHEN @ServerName IS NULL THEN @@SERVERNAME ELSE @ServerName END+''',''.'','''+@DBName+''',''.'')
												END' 
				EXECUTE sp_executesql 
					@SQLString, 
					@ParamDefinition, 
					@LogNotesOUT=@LogNotes OUTPUT
		END

	IF @TableName IS NOT NULL AND @LogNotes IS NULL
		BEGIN 
				SET @ParamDefinition	=	N'	@LogNotesOUT VARCHAR(MAX) OUTPUT'
				SET @SQLString			=	N'IF (SELECT CASE WHEN '''+@TableName+''' IN ( SELECT [name] FROM ['+CASE WHEN @ServerName IS NULL THEN @@SERVERNAME ELSE @ServerName END+'].['+@DBName+'].sys.tables )THEN 1 ELSE 0 END) = 0
												BEGIN
													 SET @LogNotesOUT = CONCAT(''The Table '','''+@TableName+''','' is not listed as available for '','''+CASE WHEN @ServerName IS NULL THEN @@SERVERNAME ELSE @ServerName END+''',''.'','''+@DBName+''',''.'','''+@SchemaName+''')
												END' 
				EXECUTE sp_executesql 
					@SQLString, 
					@ParamDefinition, 
					@LogNotesOUT=@LogNotes OUTPUT
		END

	IF @LogNotes IS NULL 
		BEGIN
				SET @LogNotes = CONCAT('The Source\Destination ',@ServerName,'.',@DBName,'.',@SchemaName,'.',@TableName,' has passed pretrasfer validation')	
				SET @ValidationPassed = 1
		END;

	

	INSERT INTO DWUser.ETL.TestLog (ETLMessage,ExecutionTime)
	SELECT @LogNotes AS ETLMessage, GETDATE() AS ExecutionTime;

	

	SELECT CAST(@LogNotes AS CHAR) AS LogNotes, @ValidationPassed AS ValidationPassed;

/*	Testing

	SELECT * FROM DWUser.ETL.TestLog ORDER BY ExecutionTime DESC

--*/