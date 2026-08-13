package projects.tanks.client.battleselect.model.battleselect
{
   
   import platform.client.fp10.core.model.IModel;
   import alternativa.types.Long;
   import scpacker.networking.Network;
   import alternativa.osgi.OSGi;
   import scpacker.networking.protocol.packets.battlelist.SelectBattleInOutPacket;
   import utils.RuntimeLifecycleDiagnostics;

   public class BattleSelectModelServer
   {
      private var model:IModel;
      private var network:Network = Network(OSGi.getInstance().getService(Network));
      
      public function BattleSelectModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }
      
      public function onSelect(param1:String) : void
      {
         RuntimeLifecycleDiagnostics.recordSelectRequest(param1,this.network != null && this.network.diagnosticSocketConnected,this.network != null && this.network.diagnosticTransportFailed);
         network.send(new SelectBattleInOutPacket(param1));
      }
      
      public function search(param1:String) : void
      {
      }
   }
}
