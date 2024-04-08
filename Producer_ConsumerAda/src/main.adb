with Ada.Text_IO, GNAT.Semaphores;
use Ada.Text_IO, GNAT.Semaphores;
with Ada.Containers.Indefinite_Doubly_Linked_Lists; use Ada.Containers;
with Ada.Numerics.Discrete_Random;
with Ada.Characters.Latin_1;
with Ada.Characters.Wide_Latin_1;
with Ada.Text_IO; use Ada.Text_IO;

pragma Wide_Character_Encoding (Utf8);

procedure Main is
   package String_Lists is new Indefinite_Doubly_Linked_Lists (String);
   use String_Lists;

   type RandRange is range 1 .. 100;

   protected ItemsHandler is
      procedure SetProduction (Total : in Integer);
      procedure DecrementProduced;
      procedure DecrementConsumed;
      function IsProductionDone return Boolean;
      function IsConsumptionDone return Boolean;
   private
      Left_Produced : Integer := 0;
      Left_Consumed : Integer := 0;
   end ItemsHandler;

   protected body ItemsHandler is
      procedure SetProduction (Total : in Integer) is
      begin
         Left_Produced := Total;
         Left_Consumed := Total;
      end SetProduction;

      procedure DecrementProduced is
      begin
         if Left_Produced > 0 then
            Left_Produced := Left_Produced - 1;
         end if;
      end DecrementProduced;

      procedure DecrementConsumed is
      begin
         if Left_Consumed > 0 then
            Left_Consumed := Left_Consumed - 1;
         end if;
      end DecrementConsumed;

      function IsProductionDone return Boolean is
      begin
         return Left_Produced = 0;
      end IsProductionDone;

      function IsConsumptionDone return Boolean is
      begin
         return Left_Consumed = 0;
      end IsConsumptionDone;

   end ItemsHandler;

   Storage_Size  : Integer := 3;
   Num_Suppliers : Integer := 1;
   Num_Receivers : Integer := 4;
   Total_Items   : Integer := 10;

   Storage        : List;
   Access_Storage : Counting_Semaphore (1, Default_Ceiling);
   Full_Storage   : Counting_Semaphore (Storage_Size, Default_Ceiling);
   Empty_Storage  : Counting_Semaphore (0, Default_Ceiling);

  task type SupplierTask is
      entry Start (Num : Integer);
   end SupplierTask;

   task body SupplierTask is
      package Rand_Int is new Ada.Numerics.Discrete_Random (RandRange);
      use Rand_Int;
      Supplier_Id   : Integer;
      Rand_Generator : Generator;
      Item_Value    : Integer;
   begin
      accept Start (Num : Integer) do
         Supplier_Id := Num;
      end Start;
      Reset (Rand_Generator);
      while not ItemsHandler.IsProductionDone loop
         ItemsHandler.DecrementProduced;
         Full_Storage.Seize;
         Access_Storage.Seize;

         Item_Value := Integer (Random (Rand_Generator));
         Storage.Append ("item" & Item_Value'Img);
         Put_Line
           (Ada.Characters.Latin_1.ESC & "[33m" & "Supplier #" & Supplier_Id'Img &
            " adds item" & Item_Value'Img & Ada.Characters.Latin_1.ESC & "[0m");

         Access_Storage.Release;
         Empty_Storage.Release;
      end loop;
      Put_Line
        (Ada.Characters.Latin_1.ESC & "[31m" & "Supplier #" & Supplier_Id'Img &
         " finished working" & Ada.Characters.Latin_1.ESC & "[0m");
   end SupplierTask;

   task type ReceiverTask is
      entry Start (Num : Integer);
   end ReceiverTask;

   task body ReceiverTask is
      Receiver_Id : Integer;
   begin
      accept Start (Num : Integer) do
         Receiver_Id := Num;
      end Start;
      while not ItemsHandler.IsConsumptionDone loop
         ItemsHandler.DecrementConsumed;
         Empty_Storage.Seize;
         Access_Storage.Seize;

         declare
            Item : String := First_Element (Storage);
         begin
            Put_Line
              (Ada.Characters.Latin_1.ESC & "[36m" & "Receiver #" & Receiver_Id'Img &
               " took " & Item & Ada.Characters.Latin_1.ESC & "[0m");
            Storage.Delete_First;

            Access_Storage.Release;
            Full_Storage.Release;
         end;
      end loop;
      Put_Line
        (Ada.Characters.Latin_1.ESC & "[35m" & "Receiver #" & Receiver_Id'Img &
         " finished working" & Ada.Characters.Latin_1.ESC & "[0m");
   end ReceiverTask;

   type SupplierArray is array (Integer range <>) of SupplierTask;
   type ReceiverArray is array (Integer range <>) of ReceiverTask;

begin
   declare
      Suppliers : SupplierArray (1 .. Num_Suppliers);
      Receivers : ReceiverArray (1 .. Num_Receivers);
   begin
      ItemsHandler.SetProduction (Total => Total_Items);
      for I in 1 .. Num_Receivers loop
         Receivers (I).Start (I);
      end loop;

      for I in 1 .. Num_Suppliers loop
         Suppliers (I).Start (I);
      end loop;
   end;
end Main;
