package projects.tanks.client.battlefield.models.bonus.battle.battlefield
{
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.type.IGameObject;
   import alternativa.types.Long;
   import scpacker.networking.Network;
   import alternativa.osgi.OSGi;
   import scpacker.networking.protocol.packets.battle.CollectBonusBoxOutPacket;
   import scpacker.utils.LongUtils;
   import utils.goldbox.GoldBoxDiagnostics;

   public class BattlefieldBonusesModelServer
   {

      private var model:IModel;
      private var network:Network = OSGi.getInstance().getService(Network) as Network;

      public function BattlefieldBonusesModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }

      public function attemptToTakeBonus(param1:Long) : void
      {
         GoldBoxDiagnostics.collectPacketSendBegin(GoldBoxDiagnostics.canonicalFromLong(param1));
         this.network.send(new CollectBonusBoxOutPacket(LongUtils.idToStr(param1)));
         GoldBoxDiagnostics.collectPacketSendCallReturned(GoldBoxDiagnostics.canonicalFromLong(param1));
      }
   }
}
