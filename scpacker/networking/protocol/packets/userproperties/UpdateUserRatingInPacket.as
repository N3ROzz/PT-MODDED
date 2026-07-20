package scpacker.networking.protocol.packets.userproperties
{
   import scpacker.networking.protocol.AbstractPacket;
   
   public class UpdateUserRatingInPacket extends AbstractPacket
   {
      public static const id:int = -1128606444;
      
      public var userRating:Number;
      
      public var place:int;
      
      public function UpdateUserRatingInPacket(param1:Number = 0, param2:int = 0)
      {
         super();
         this.userRating = param1;
         this.place = param2;
         registerProperty(param1);
         registerPropertyCodec("scpacker.networking.protocol.codec.primitive.FloatCodec");
         registerProperty(param2);
         registerPropertyCodec("scpacker.networking.protocol.codec.primitive.IntCodec");
      }
      
      override public function writeToPropertyByIndex(param1:Object, param2:int) : void
      {
         switch(param2)
         {
            case 0:
               this.userRating = param1 as Number;
               break;
            case 1:
               this.place = param1 as int;
         }
      }
      
      override public function initializeSelf() : AbstractPacket
      {
         return new UpdateUserRatingInPacket();
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
