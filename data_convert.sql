CREATE PROCEDURE [dbo].########
   AS
  
   --объявляем переменные
   DECLARE @id int
   
   --объявляем курсор
   DECLARE my_cur CURSOR FOR 
     SELECT [id]
     FROM [1c__flop_62p] 
	 where [EventData_] is null
   
   --открываем курсор
   OPEN my_cur
   --считываем данные первой строки в наши переменные
   FETCH NEXT FROM my_cur INTO @id
   --если данные в курсоре есть, то заходим в цикл
   --и крутимся там до тех пор, пока не закончатся строки в курсоре
   WHILE @@FETCH_STATUS = 0
   BEGIN
        --на каждую итерацию цикла запускаем запускаем update
        update [1c__flop_62p] set  EventData_ =  (select SUBSTRING([Source],9,4)+'.'+SUBSTRING([Source],7,2)+'.'+substring([Source],5,2) from [1c__flop_62p] where id = @id) where id = @id
        --считываем следующую строку курсора
        FETCH NEXT FROM my_cur INTO @id
   END
   
   --закрываем курсор
   CLOSE my_cur
   DEALLOCATE my_cur
