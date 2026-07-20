package scpacker.networking.protocol.packets.userproperties
{
   import scpacker.networking.protocol.AbstractPacket;
   
   public class UpdateRankInPacket extends AbstractPacket
   {
      public static const id:int = 1989173907;
      
      public var rank:int;
      
      public var score:int;
      
      public var rankBoundMin:int;
      
      public var rankBoundMax:int;
      
      public var rankReward:int;
      
      public function UpdateRankInPacket(param1:int = 0, param2:int = 0, param3:int = 0, param4:int = 0, param5:int = 0)
      {
         super();
         this.rank = param1;
         this.score = param2;
         this.rankBoundMin = param3;
         this.rankBoundMax = param4;
         this.rankReward = param5;
         registerProperty(param1);
         registerPropertyCodec("scpacker.networking.protocol.codec.primitive.IntCodec");
         registerProperty(param2);
         registerPropertyCodec("scpacker.networking.protocol.codec.primitive.IntCodec");
         registerProperty(param3);
         registerPropertyCodec("scpacker.networking.protocol.codec.primitive.IntCodec");
         registerProperty(param4);
         registerPropertyCodec("scpacker.networking.protocol.codec.primitive.IntCodec");
         registerProperty(param5);
         registerPropertyCodec("scpacker.networking.protocol.codec.primitive.IntCodec");
      }
      
      override public function writeToPropertyByIndex(param1:Object, param2:int) : void
      {
         switch(param2)
         {
            case 0:
               this.rank = param1 as int;
               break;
            case 1:
               this.score = param1 as int;
               break;
            case 2:
               this.rankBoundMin = param1 as int;
               break;
            case 3:
               this.rankBoundMax = param1 as int;
               break;
            case 4:
               this.rankReward = param1 as int;
         }
      }
      
      override public function initializeSelf() : AbstractPacket
      {
         return new UpdateRankInPacket();
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
