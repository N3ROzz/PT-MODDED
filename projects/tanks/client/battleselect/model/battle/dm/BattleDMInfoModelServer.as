package projects.tanks.client.battleselect.model.battle.dm
{
   import platform.client.fp10.core.model.IModel;
   import alternativa.osgi.OSGi;
   import scpacker.networking.Network;
   import scpacker.networking.protocol.packets.battleInfo.JoinBattleOutPacket;
   import projects.tanks.client.battleservice.model.battle.team.BattleTeam;
   import platform.client.fp10.core.model.impl.Model;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.layout.ILobbyLayoutService;

   public class BattleDMInfoModelServer
   {

      private var model:IModel;
      private var network:Network = Network(OSGi.getInstance().getService(Network));
      private var lobbyLayoutService:ILobbyLayoutService = ILobbyLayoutService(OSGi.getInstance().getService(ILobbyLayoutService));

      public function BattleDMInfoModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }

      public function fight() : void
      {
         this.recordJoin(BattleTeam.NONE);
         this.network.send(new JoinBattleOutPacket(BattleTeam.NONE));
      }

      private function recordJoin(param1:BattleTeam) : void
      {
         var _loc1_:String = Model.object == null ? "" : Model.object.name;
      }
   }
}
