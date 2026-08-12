package projects.tanks.client.battleselect.model.battle.team
{
   import platform.client.fp10.core.model.IModel;
   import alternativa.osgi.OSGi;
   import scpacker.networking.Network;
   import scpacker.networking.protocol.packets.battleInfo.JoinBattleOutPacket;
   import projects.tanks.client.battleservice.model.battle.team.BattleTeam;
   import platform.client.fp10.core.model.impl.Model;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.layout.ILobbyLayoutService;
   import utils.BattleSelectionTrace;
   import utils.RuntimeLifecycleDiagnostics;

   public class TeamBattleInfoModelServer
   {

      private var model:IModel;
      private var network:Network = Network(OSGi.getInstance().getService(Network));
      private var lobbyLayoutService:ILobbyLayoutService = ILobbyLayoutService(OSGi.getInstance().getService(ILobbyLayoutService));

      public function TeamBattleInfoModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }

      public function fight(param1:BattleTeam) : void
      {
         var _loc1_:String = Model.object == null ? "" : Model.object.name;
         if(RuntimeLifecycleDiagnostics.enabled)
         {
            RuntimeLifecycleDiagnostics.beginPreInit(_loc1_,_loc1_,param1 == null ? "null" : param1.name,this.network != null && this.network.diagnosticSocketConnected,this.network != null && this.network.diagnosticTransportFailed,this.lobbyLayoutService != null && this.lobbyLayoutService.isSwitchInProgress(),this.lobbyLayoutService != null && this.lobbyLayoutService.inBattle());
         }
         BattleSelectionTrace.recordJoinRequest(_loc1_,Model.object,param1 == null ? "null" : param1.name);
         this.network.send(new JoinBattleOutPacket(param1));
      }
   }
}
