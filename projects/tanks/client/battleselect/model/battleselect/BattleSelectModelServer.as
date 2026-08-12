package projects.tanks.client.battleselect.model.battleselect
{
   
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.type.IGameObject;
   import alternativa.types.Long;
   import scpacker.networking.Network;
   import alternativa.osgi.OSGi;
   import scpacker.networking.protocol.packets.battlelist.SelectBattleInOutPacket;
   import utils.BattleSelectionTrace;
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
      
      public function onSelect(param1:String, param2:IGameObject = null) : void
      {
         RuntimeLifecycleDiagnostics.recordSelectRequest(param1,this.network != null && this.network.diagnosticSocketConnected,this.network != null && this.network.diagnosticTransportFailed);
         var payload:String = BattleSelectionTrace.buildSelectPayload(param1);
         BattleSelectionTrace.beginRequest(param1,payload,param2);
         network.send(new SelectBattleInOutPacket(payload));
      }
      
      public function search(param1:String) : void
      {
      }
   }
}
