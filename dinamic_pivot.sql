   CREATE PROCEDURE [dbo].[SP_Dynamic_Pivot]
   (
        @TableSRC NVARCHAR(100),   --Таблица источник (Представление)
        @ColumnName NVARCHAR(100), --Столбец, содержащий значения, которые станут именами столбцов
        @Field NVARCHAR(100),      --Столбец, над которым проводить агрегацию
        @FieldRows NVARCHAR(MAX),  --Столбец (столбцы) для группировки по строкам (Column1, Column2)
        @FunctionType NVARCHAR(20) = 'SUM',--Агрегатная функция (SUM, COUNT, MAX, MIN, AVG), по умолчанию SUM
        @Condition NVARCHAR(200) = '' --Условие (WHERE и т.д.). По умолчанию без условия
   )
   AS 
   BEGIN
        /*
                
        */
        
        --Отключаем вывод количества строк
        SET NOCOUNT ON;
        
        --Переменная для хранения строки запроса
        DECLARE @Query NVARCHAR(MAX);                     
         --Переменная для хранения имен столбцов
        DECLARE @ColumnNames NVARCHAR(MAX);              
        --Переменная для хранения заголовков результирующего набора данных
        DECLARE @ColumnNamesHeader NVARCHAR(MAX); 

        --Обработчик ошибок
        BEGIN TRY
                --Таблица для хранения уникальных значений, 
                --которые будут использоваться в качестве столбцов      
                CREATE TABLE #ColumnNames(ColumnName NVARCHAR(100) NOT NULL PRIMARY KEY);
        
                --Формируем строку запроса для получения уникальных значений для имен столбцов
                SET @Query = N'INSERT INTO #ColumnNames (ColumnName)
                                                  SELECT DISTINCT COALESCE(' + @ColumnName + ', ''Пусто'') 
                                                  FROM ' + @TableSRC + ' ' + @Condition + ';'
                print(@Query)
                --Выполняем строку запроса
                EXEC (@Query);

                --Формируем строку с именами столбцов
                SELECT @ColumnNames = ISNULL(@ColumnNames + ', ','') + QUOTENAME(ColumnName) 
                FROM #ColumnNames;
                
                --Формируем строку для заголовка динамического перекрестного запроса (PIVOT)
                SELECT @ColumnNamesHeader = ISNULL(@ColumnNamesHeader + ', ','') 
                                                                        + 'COALESCE('
                                                                        + QUOTENAME(ColumnName) 
                                                                        + ', 0) AS '
                                                                        + QUOTENAME(ColumnName)
                FROM #ColumnNames;
        
                --Формируем строку с запросом PIVOT
                SET @Query = N'SELECT ' + @FieldRows + ' , ' + @ColumnNamesHeader + ' 
                                           FROM (SELECT ' + @FieldRows + ', ' + @ColumnName + ', ' + @Field 
                                                         + ' FROM ' + @TableSRC  + ' ' + @Condition + ') AS SRC
                                           PIVOT ( ' + @FunctionType + '(' + @Field + ')' +' FOR ' +  
                                                                   @ColumnName + ' IN (' + @ColumnNames + ')) AS PVT
                                           ORDER BY ' + @FieldRows + ';'
                
                --Удаляем временную таблицу
                DROP TABLE #ColumnNames;

                --Выполняем строку запроса с PIVOT
                EXEC (@Query);
                
                --Включаем обратно вывод количества строк
                SET NOCOUNT OFF;
                
        END TRY
        BEGIN CATCH
                --В случае ошибки, возвращаем номер и описание этой ошибки
                SELECT ERROR_NUMBER() AS [Номер ошибки], 
                           ERROR_MESSAGE() AS [Описание ошибки]
        END CATCH
   END