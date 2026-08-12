package projects.tanks.client.battlefield.models.user.suicide
{
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.type.IGameObject;
   import scpacker.networking.Network;
   import alternativa.osgi.OSGi;
   import scpacker.networking.protocol.packets.selfdestruct.SuicideOutPacket;
   import utils.RuntimeLifecycleDiagnostics;

   public class SuicideModelServer
   {

      private var model:IModel;
      private var network:Network = OSGi.getInstance().getService(Network) as Network;

      public function SuicideModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }

      public function suicideCommand() : void
      {
         RuntimeLifecycleDiagnostics.recordSuicide("SUICIDE_OUT_SEND_REQUEST","packetId=" + SuicideOutPacket.id,true);
         this.network.send(new SuicideOutPacket());
         RuntimeLifecycleDiagnostics.recordSuicide("SUICIDE_OUT_SEND_RETURNED","packetId=" + SuicideOutPacket.id,true);
      }
   }
}
