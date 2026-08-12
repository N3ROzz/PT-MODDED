
package projects.tanks.client.battleselect.model.battle.entrance
{
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.model.impl.Model;
   import projects.tanks.client.battleservice.model.battle.team.BattleTeam;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.layout.ILobbyLayoutService;
   import scpacker.networking.Network;
   import alternativa.osgi.OSGi;
   import scpacker.networking.protocol.packets.battleInfo.JoinBattleOutPacket;
   import scpacker.networking.protocol.packets.battleInfo.SpectateBattleOutPacket;
   import utils.BattleSelectionTrace;
   import utils.RuntimeLifecycleDiagnostics;
   
   public class BattleEntranceModelServer
   {
      private var model:IModel;
      private var network:Network = OSGi.getInstance().getService(Network) as Network;
      private var lobbyLayoutService:ILobbyLayoutService = OSGi.getInstance().getService(ILobbyLayoutService) as ILobbyLayoutService;
      
      public function BattleEntranceModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }
      
      public function fight(param1:BattleTeam) : void
      {
         if(RuntimeLifecycleDiagnostics.enabled)
         {
            try
            {
               var _loc2_:String = Model.object == null ? "" : Model.object.name;
               var _loc3_:String = param1 == null ? "null" : param1.name;
               var _loc4_:Boolean = this.lobbyLayoutService != null && this.lobbyLayoutService.isSwitchInProgress();
               var _loc5_:Boolean = this.lobbyLayoutService != null && this.lobbyLayoutService.inBattle();
               var _loc6_:String = this.lobbyLayoutService == null ? "unavailable" : String(this.lobbyLayoutService.getCurrentState());
               RuntimeLifecycleDiagnostics.updateLayoutState(_loc4_,_loc5_,_loc6_);
               RuntimeLifecycleDiagnostics.beginPreInit(_loc2_,_loc2_,_loc3_,this.network != null && this.network.diagnosticSocketConnected,this.network != null && this.network.diagnosticTransportFailed,_loc4_,_loc5_);
            }
            catch(diagnosticError:Error)
            {
            }
         }
         BattleSelectionTrace.recordJoinRequest(Model.object == null ? "" : Model.object.name,Model.object,param1 == null ? "null" : param1.name);
         network.send(new JoinBattleOutPacket(param1));
      }
      
      public function joinAsSpectator() : void
      {
         network.send(new SpectateBattleOutPacket());
      }
   }
}
