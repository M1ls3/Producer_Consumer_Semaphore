with Ada.Text_IO, GNAT.Semaphores;  -- Import Ada.Text_IO and GNAT.Semaphores packages.
use Ada.Text_IO, GNAT.Semaphores;  -- Make the contents of Ada.Text_IO and GNAT.Semaphores directly visible.
with Ada.Containers.Indefinite_Doubly_Linked_Lists; use Ada.Containers;  -- Import and make the contents of Ada.Containers.Indefinite_Doubly_Linked_Lists visible.
with Ada.Numerics.Discrete_Random;  -- Import Ada.Numerics.Discrete_Random package for generating random numbers.

pragma Wide_Character_Encoding (Utf8);  -- Set wide character encoding to UTF-8.

procedure Main is  -- Start of the main procedure.
   package String_Lists is new Indefinite_Doubly_Linked_Lists (String);  -- Define a new package String_Lists based on Indefinite_Doubly_Linked_Lists for strings.
   use String_Lists;  -- Make the contents of String_Lists directly visible.

   type RandRange is range 1 .. 100;  -- Define a range type for random numbers.

   protected ItemsHandler is  -- Define a protected type ItemsHandler to handle items.
      procedure SetProduction (Total : in Integer);  -- Procedure to set the total production.
      procedure ProduceCount;  -- Procedure to decrement the produced items.
      procedure ConsumeCount;  -- Procedure to decrement the consumed items.
      function IsProductionDone return Boolean;  -- Function to check if production is done.
      function IsConsumptionDone return Boolean;  -- Function to check if consumption is done.
   private
      Left_Produced : Integer := 0;  -- Counter for remaining produced items.
      Left_Consumed : Integer := 0;  -- Counter for remaining consumed items.
   end ItemsHandler;

   protected body ItemsHandler is  -- Body of the protected type ItemsHandler.
      procedure SetProduction (Total : in Integer) is  -- Implementation of SetProduction procedure.
      begin
         Left_Produced := Total;  -- Set the remaining produced items to the total.
         Left_Consumed := Total;  -- Set the remaining consumed items to the total.
      end SetProduction;

      procedure ProduceCount is  -- Implementation of DecrementProduced procedure.
      begin
         if Left_Produced > 0 then  -- Check if there are remaining produced items.
            Left_Produced := Left_Produced - 1;  -- Decrement the counter for produced items.
         end if;
      end ProduceCount;

      procedure ConsumeCount is  -- Implementation of DecrementConsumed procedure.
      begin
         if Left_Consumed > 0 then  -- Check if there are remaining consumed items.
            Left_Consumed := Left_Consumed - 1;  -- Decrement the counter for consumed items.
         end if;
      end ConsumeCount;

      function IsProductionDone return Boolean is  -- Implementation of IsProductionDone function.
      begin
         return Left_Produced = 0;  -- Return True if all items are produced.
      end IsProductionDone;

      function IsConsumptionDone return Boolean is  -- Implementation of IsConsumptionDone function.
      begin
         return Left_Consumed = 0;  -- Return True if all items are consumed.
      end IsConsumptionDone;

   end ItemsHandler;

   Storage_Size  : Integer := 3;  -- Define the size of the storage.
   Num_Producers : Integer := 1;  -- Define the number of producers.
   Num_Consumers : Integer := 4;  -- Define the number of consumers.
   Total_Items   : Integer := 10;  -- Define the total number of items.

   Storage        : List;  -- Define a list to store items.
   Access_Storage : Counting_Semaphore (1, Default_Ceiling);  -- Define a semaphore for accessing the storage.
   Full_Storage   : Counting_Semaphore (Storage_Size, Default_Ceiling);  -- Define a semaphore for indicating full storage.
   Empty_Storage  : Counting_Semaphore (0, Default_Ceiling);  -- Define a semaphore for indicating empty storage.

  task type ProducerTask is  -- Define a task type for producers.
      entry Start (Num : Integer);  -- Entry to start a producer task.
   end ProducerTask;

   task body ProducerTask is  -- Body of the producer task.
      package Rand_Int is new Ada.Numerics.Discrete_Random (RandRange);  -- Define a random number generator package.
      use Rand_Int;  -- Make the contents of the random number generator package directly visible.
      Producer_Id   : Integer;  -- ID of the producer.
      Rand_Generator : Generator;  -- Random number generator.
      Item_Value    : Integer;  -- Value of the produced item.
   begin
      accept Start (Num : Integer) do  -- Accept the start entry with a producer ID.
         ProducerTask.Producer_Id := Num;  -- Set the producer ID.
      end Start;
      Reset (Rand_Generator);  -- Reset the random number generator.
      while not ItemsHandler.IsProductionDone loop  -- Continue producing until all items are produced.
         ItemsHandler.ProduceCount;  -- Decrement the counter for produced items.
         Full_Storage.Seize;  -- Acquire a full storage semaphore.
         Access_Storage.Seize;  -- Acquire an access semaphore for storage.

         Item_Value := Integer (Random (Rand_Generator));  -- Generate a random item value.
         Storage.Append ("item" & Item_Value'Img);  -- Append the item to the storage.
         Put_Line
           ("Consumer [" & ProducerTask.Producer_Id'Img & "] adds item");  -- Print a message indicating item addition.

         Access_Storage.Release;  -- Release the access semaphore.
         Empty_Storage.Release;  -- Release the empty storage semaphore.
      end loop;
      Put_Line
        ("Consumer [" & ProducerTask.Producer_Id'Img & "] stopped");  -- Print a message indicating producer stop.
   end ProducerTask;

   task type ConsumerTask is  -- Define a task type for consumers.
      entry Start (Num : Integer);  -- Entry to start a consumer task.
   end ConsumerTask;

   task body ConsumerTask is  -- Body of the consumer task.
      Consumer_Id : Integer;  -- ID of the consumer.
   begin
      accept Start (Num : Integer) do  -- Accept the start entry with a consumer ID.
         ConsumerTask.Consumer_Id := Num;  -- Set the consumer ID.
      end Start;
      while not ItemsHandler.IsConsumptionDone loop  -- Continue consuming until all items are consumed.
         ItemsHandler.ConsumeCount;  -- Decrement the counter for consumed items.
         Empty_Storage.Seize;  -- Acquire an empty storage semaphore.
         Access_Storage.Seize;  -- Acquire an access semaphore for storage.

         declare
            Item : String := First_Element (Storage);  -- Get the first item from the storage.
         begin
            Put_Line
              ("Receiver [" & ConsumerTask.Consumer_Id'Img & "] get ");  -- Print a message indicating item consumption.
            Storage.Delete_First;  -- Delete the first item from the storage.

            Access_Storage.Release;  -- Release the access semaphore.
            Full_Storage.Release;  -- Release the full storage semaphore.
         end;
      end loop;
      Put_Line
        ("Receiver [" & ConsumerTask.Consumer_Id'Img & "] stopped");  -- Print a message indicating consumer stop.
   end ConsumerTask;

   type ProducerArray is array (Integer range <>) of ProducerTask;  -- Define an array type for producer tasks.
   type ConsumerArray is array (Integer range <>) of ConsumerTask;  -- Define an array type for consumer tasks.

begin
   declare
      Producers : ProducerArray (1 .. Num_Producers);  -- Declare an array of producer tasks.
      Consumers : ConsumerArray (1 .. Num_Consumers);  -- Declare an array of consumer tasks.
   begin
      ItemsHandler.SetProduction (Total => Total_Items);  -- Set the total production count.
      for I in 1 .. Num_Consumers loop  -- Loop through each consumer.
         Consumers (I).Start (I);  -- Start the consumer task.
      end loop;

      for I in 1 .. Num_Producers loop  -- Loop through each producer.
         Producers (I).Start (I);  -- Start the producer task.
      end loop;
   end;
end Main;  -- End of the main procedure.
