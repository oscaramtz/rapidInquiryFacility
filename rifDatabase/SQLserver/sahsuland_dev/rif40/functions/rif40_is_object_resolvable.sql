/*
More of a quick hack instead of a proper implementation.  Function needs proper logging and error handling
*/

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[rif40].[rif40_is_object_resolvable]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [rif40].[rif40_is_object_resolvable]
GO 

CREATE FUNCTION [rif40].[rif40_is_object_resolvable](@l_table_name VARCHAR(500))
  RETURNS INTEGER AS
BEGIN
	DECLARE @database_name VARCHAR(500) = DB_NAME(); -- current database name
	DECLARE @schema_name VARCHAR(500) = 'rif_data';
	DECLARE @table_name VARCHAR(500) = @l_table_name;
	DECLARE @server_name VARCHAR(500) = @@SERVERNAME; -- current server name
--
-- Must be rif40 or have rif_user or rif_manager role
--

	/* 
		--cannot use try/catch within function, must record error some other way
	BEGIN TRY
		IF SUSER_SNAME() <> 'rif40' AND  IS_MEMBER(N'[rif_manager]') = 0 
		BEGIN
			RAISERROR(51001, 16, 1, SUSER_SNAME()) with log; 
			ROLLBACK;			
		END;
	END TRY
	BEGIN CATCH
		EXEC [rif40].[ErrorLog_proc];
		RETURN 0;
	END CATCH 
	*/
	
	IF SUSER_SNAME() <> 'rif40' AND  IS_MEMBER(N'[rif_manager]') = 0 
		RETURN -1;
		
-- If inputs are NULL return 0
--
	IF @l_table_name IS NULL 
		RETURN -2;
	
--

	--quick and simple:
	IF OBJECT_ID(@l_table_name) IS NOT NULL 
		RETURN 1;
	

	--more detail about the missing table... (not at all confident about the rest of this)
	--can be [remote server].[database].[schema].[table]
	
	IF CHARINDEX('.',@l_table_name) > 0 
	BEGIN
		SET @table_name = RIGHT(@l_table_name,len(@l_table_name) -CHARINDEX('.',@l_table_name));
		SET @schema_name = LEFT(@l_table_name,CHARINDEX('.',@l_table_name)-1);
		IF CHARINDEX('.',@schema_name) > 0 
		BEGIN
			SET @database_name = RIGHT(@l_table_name,len(@schema_name) -CHARINDEX('.',@schema_name));
			SET @schema_name = LEFT(@schema_name,CHARINDEX('.',@schema_name)-1);
			IF  CHARINDEX('.',@database_name) > 0 
				BEGIN
					SET @server_name = RIGHT(@l_table_name,len(@database_name) -CHARINDEX('.',@database_name));
					SET @database_name = LEFT(@database_name,CHARINDEX('.',@database_name)-1);
				END
		END
	END 
	
	--remote connection (not certain if this is right):
	/*
	IF upper(@server_name) <> upper(@@SERVERNAME)
	BEGIN
		IF NOT EXISTS (select name from sys.servers where upper(name)=upper(@server_name))
		BEGIN
			--server cannot be found
			RETURN 0;
		END
	END
	
	IF upper(@database_name) <> upper(DB_NAME())
	BEGIN
		IF NOT EXISTS (select name from sys.databases where upper(name)=upper(@database_name))
		BEGIN
			--database does not exist
			RETURN 0;
		END
	END
	
	IF @schema_name IS NOT NULL AND lower(@schema_name) <> 'dbo'
	BEGIN
		IF NOT EXISTS (select [SCHEMA_NAME] from [INFORMATION_SCHEMA].[SCHEMATA] where upper([SCHEMA_NAME])=upper(@schema_name))
		BEGIN
			--schema does not exist
			RETURN 0;
		END
	END */
	
	IF @table_name IS NOT NULL AND @table_name <> ''
	BEGIN
		IF NOT EXISTS (select [TABLE_NAME] from [INFORMATION_SCHEMA].[TABLES] where upper([TABLE_NAME])=upper(@table_name))
		BEGIN
			--table/view does not exist
			RETURN -3;
		END
	END
		
	IF EXISTS (select * from sys.fn_my_permissions(@schema_name + '.' + @l_table_name, N'OBJECT') 
		WHERE subentity_name = N'' ) -- you have some sort of permissions
	
			RETURN 1;
		ELSE
			RETURN -4; -- no permission to access
			
	RETURN -5;
END;
GO

GRANT EXECUTE ON [rif40].[rif40_is_object_resolvable] TO rif_user, rif_manager;
GO

-- 
-- Eof
