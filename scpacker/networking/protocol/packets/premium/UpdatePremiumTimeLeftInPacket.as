package scpacker.networking.protocol.packets.premium
{
   import scpacker.networking.protocol.AbstractPacket;
   
   public class UpdatePremiumTimeLeftInPacket extends AbstractPacket
   {
      public static const id:int = 1391146385;
      
      public var timeLeftInSeconds:int;
      
      public function UpdatePremiumTimeLeftInPacket(param1:int = 0)
      {
         super();
         this.timeLeftInSeconds = param1;
         registerProperty(param1);
         registerPropertyCodec("scpacker.networking.protocol.codec.primitive.IntCodec");
      }
      
      override public function writeToPropertyByIndex(param1:Object, param2:int) : void
      {
         switch(param2)
         {
            case 0:
               this.timeLeftInSeconds = param1 as int;
         }
      }
      
      override public function initializeSelf() : AbstractPacket
      {
         return new UpdatePremiumTimeLeftInPacket();
      }
      
      override public function getPacketHandlerId() : int
      {
         return 11;
      }
      
      override public function getId() : int
      {
         return id;
      }
   }
}
