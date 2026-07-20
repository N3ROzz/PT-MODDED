package scpacker.networking.protocol.packets.userproperties
{
   import scpacker.networking.protocol.AbstractPacket;
   
   public class UpdateCrystalsInPacket extends AbstractPacket
   {
      public static const id:int = -593513288;
      
      public var crystals:int;
      
      public function UpdateCrystalsInPacket(param1:int = 0)
      {
         super();
         this.crystals = param1;
         registerProperty(param1);
         registerPropertyCodec("scpacker.networking.protocol.codec.primitive.IntCodec");
      }
      
      override public function writeToPropertyByIndex(param1:Object, param2:int) : void
      {
         switch(param2)
         {
            case 0:
               this.crystals = param1 as int;
         }
      }
      
      override public function initializeSelf() : AbstractPacket
      {
         return new UpdateCrystalsInPacket();
      }
      
      override public function getPacketHandlerId() : int
      {
         return 29;
      }
      
      override public function getId() : int
      {
         return id;
      }
   }
}
