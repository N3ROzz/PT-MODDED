package scpacker.networking.protocol.packets.usernotifier
{
   import projects.tanks.client.tanksservices.model.notifier.clan.UserClanInfoCC;
   import scpacker.networking.protocol.AbstractPacket;
   
   public class ClanUserInfoInPacket extends AbstractPacket
   {
      
      public static const id:int = -117055417;
      
      public var userClanInfo:UserClanInfoCC;
      
      public function ClanUserInfoInPacket(param1:UserClanInfoCC = null)
      {
         super();
         this.userClanInfo = param1;
         registerProperty(param1);
         registerPropertyCodec("scpacker.networking.protocol.codec.custom.CodecUserClanInfoCC");
      }
      
      override public function writeToPropertyByIndex(param1:Object, param2:int) : void
      {
         switch(param2)
         {
            case 0:
               this.userClanInfo = param1 as UserClanInfoCC;
         }
      }
      
      override public function initializeSelf() : AbstractPacket
      {
         return new ClanUserInfoInPacket();
      }
      
      override public function getPacketHandlerId() : int
      {
         return 18;
      }
      
      override public function getId() : int
      {
         return id;
      }
   }
}
