package scpacker.networking.protocol.packets.premium
{
   import alternativa.osgi.OSGi;
   import projects.tanks.client.tanksservices.model.notifier.premium.PremiumNotifierCC;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.premium.PremiumService;
   import scpacker.networking.protocol.AbstractPacket;
   import scpacker.networking.protocol.AbstractPacketHandler;
   
   public class PremiumPacketHandler extends AbstractPacketHandler
   {
      private var premiumService:PremiumService;
      
      public function PremiumPacketHandler()
      {
         super();
         this.id = 11;
         this.premiumService = OSGi.getInstance().getService(PremiumService) as PremiumService;
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case InitPremiumNotifierInPacket.id:
               this.initPremiumNotifier(param1 as InitPremiumNotifierInPacket);
               break;
            case UpdatePremiumTimeLeftInPacket.id:
               this.updatePremiumTimeLeft(param1 as UpdatePremiumTimeLeftInPacket);
         }
      }

      private function initPremiumNotifier(param1:InitPremiumNotifierInPacket) : void
      {
         if(param1 == null)
         {
            return;
         }
         this.updatePremiumNotifier(param1.premiumNotifier);
      }
      
      private function updatePremiumTimeLeft(param1:UpdatePremiumTimeLeftInPacket) : void
      {
         if(this.premiumService != null && param1 != null)
         {
            this.premiumService.updateTimeLeft(param1.timeLeftInSeconds);
         }
      }

      private function updatePremiumNotifier(param1:PremiumNotifierCC) : void
      {
         if(this.premiumService != null && param1 != null)
         {
            this.premiumService.updateTimeLeft(param1.lifeTimeInSeconds);
         }
      }
   }
}
