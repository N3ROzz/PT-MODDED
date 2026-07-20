package projects.tanks.client.battleselect.model.battleselect.create
{
   import platform.client.fp10.core.model.IModel;
   import projects.tanks.client.battleservice.BattleCreateParameters;
   import scpacker.networking.Network;
   import alternativa.osgi.OSGi;
   import scpacker.networking.protocol.packets.battlecreate.CheckBattleNameOutPacket;
   import scpacker.networking.protocol.packets.battlecreate.CreateBattleOutPacket;
   import utils.TankTraceUtil;

   public class BattleCreateModelServer
   {

      private var model:IModel;
      private var network:Network = OSGi.getInstance().getService(Network) as Network;

      public function BattleCreateModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }

      public function checkBattleNameForForbiddenWords(param1:String) : void
      {
         TankTraceUtil.logRatings("CheckBattleName name=" + param1);
         this.network.send(new CheckBattleNameOutPacket(param1));
      }

      public function createBattle(param1:BattleCreateParameters) : void
      {
         TankTraceUtil.logRatings("SendCreateBattle name=" + param1.name + " mode=" + (param1.battleMode == null ? "null" : param1.battleMode.name) + " mapId=" + param1.mapId + " proBattle=" + param1.proBattle + " private=" + param1.privateBattle + " noSupplies=" + param1.withoutSupplies + " noBonuses=" + param1.withoutBonuses + " noCrystals=" + param1.withoutCrystals + " noGold=" + param1.withoutGoldBoxes + " noMines=" + param1.withoutMines + " noMedkit=" + param1.withoutMedkit + " equipment=" + param1.equipmentConstraintsMode + " parkour=" + param1.parkourMode + " maxPeople=" + param1.maxPeopleCount + " limits=" + (param1.limits == null ? "null" : param1.limits.scoreLimit + "/" + param1.limits.timeLimitInSec));
         this.network.send(new CreateBattleOutPacket(param1));
      }
   }
}
