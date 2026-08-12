package projects.tanks.client.battleselect.model.battle
{
   import platform.client.fp10.core.model.IModel;
   import alternativa.osgi.OSGi;
   import scpacker.networking.Network;
   import scpacker.networking.protocol.packets.battleInfo.SpectateBattleOutPacket;

   public class BattleInfoModelServer
   {

      private var model:IModel;
      private var network:Network = Network(OSGi.getInstance().getService(Network));

      public function BattleInfoModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }

      public function joinAsSpectator() : void
      {
         this.network.send(new SpectateBattleOutPacket());
      }
   }
}
