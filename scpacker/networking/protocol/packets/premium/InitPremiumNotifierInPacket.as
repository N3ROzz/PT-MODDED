package scpacker.networking.protocol.packets.premium
{
   import projects.tanks.client.panel.model.premiumaccount.alert.PremiumAccountAlertCC;
   import projects.tanks.client.tanksservices.model.notifier.premium.PremiumNotifierCC;
   import scpacker.networking.protocol.AbstractPacket;
   
   public class InitPremiumNotifierInPacket extends AbstractPacket
   {
      public static const id:int = 1405859779;
      
      public var premiumAccountAlert:PremiumAccountAlertCC;
      
      public var premiumNotifier:PremiumNotifierCC;
      
      public function InitPremiumNotifierInPacket(param1:PremiumAccountAlertCC = null, param2:PremiumNotifierCC = null)
      {
         super();
         this.premiumAccountAlert = param1;
         this.premiumNotifier = param2;
         registerProperty(param1);
         registerPropertyCodec("scpacker.networking.protocol.codec.custom.CodecPremiumAccountAlertCC");
         registerProperty(param2);
         registerPropertyCodec("scpacker.networking.protocol.codec.custom.CodecPremiumNotifierCC");
      }
      
      override public function writeToPropertyByIndex(param1:Object, param2:int) : void
      {
         switch(param2)
         {
            case 0:
               this.premiumAccountAlert = param1 as PremiumAccountAlertCC;
               break;
            case 1:
               this.premiumNotifier = param1 as PremiumNotifierCC;
         }
      }
      
      override public function initializeSelf() : AbstractPacket
      {
         return new InitPremiumNotifierInPacket();
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
