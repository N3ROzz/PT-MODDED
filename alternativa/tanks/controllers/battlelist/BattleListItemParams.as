package alternativa.tanks.controllers.battlelist
{
   import alternativa.tanks.view.battleinfo.BattleInfoBaseParams;
   import alternativa.tanks.view.battleinfo.dm.BattleInfoDmParams;
   import alternativa.tanks.view.battleinfo.team.BattleInfoTeamParams;
   import alternativa.types.Long;
   import projects.tanks.client.battleservice.BattleCreateParameters;
   import projects.tanks.client.battleservice.Range;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.battle.IBattleInfoService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.userproperties.IUserPropertiesService;
   import projects.tanks.clients.fp10.libraries.tanksservices.utils.BattleFormatUtil;
   import projects.tanks.client.battleservice.EquipmentConstraintsMode;
   import utils.TankTraceUtil;
   
   public class BattleListItemParams
   {
      
      [Inject] // added
      public static var userPropertiesService:IUserPropertiesService;
      
      [Inject] // added
      public static var battleInfoService:IBattleInfoService;
      
      [Inject] // added
      public static var battleFormatUtil:BattleFormatUtil;
      
      public var isDM:Boolean;
      
      public var params:BattleInfoBaseParams;
      
      public var dmParams:BattleInfoDmParams;
      
      public var teamParams:BattleInfoTeamParams;
      
      public var accessible:Boolean;
      
      public var currentBattle:Boolean;
      
      public var formatBattle:Boolean;
      
      public var formatName:String;
      
      public function BattleListItemParams(param1:BattleInfoBaseParams)
      {
         super();
         TankTraceUtil.logBattleList("BattleListItemParams.start paramsNull=" + (param1 == null));
         this.params = param1;
         this.dmParams = param1 as BattleInfoDmParams;
         this.teamParams = param1 as BattleInfoTeamParams;
         this.isDM = this.dmParams != null;
         TankTraceUtil.logBattleList("BattleListItemParams.afterType id=" + (param1.battle == null ? "battleNull" : param1.battle.name) + " isDM=" + this.isDM + " createNull=" + (param1.createParams == null));
         var _loc2_:Range = param1.createParams.rankRange;
         TankTraceUtil.logBattleList("BattleListItemParams.rankRange id=" + (param1.battle == null ? "battleNull" : param1.battle.name) + " rangeNull=" + (_loc2_ == null) + " userRank=" + userPropertiesService.rank);
         this.accessible = _loc2_.min <= userPropertiesService.rank && userPropertiesService.rank <= _loc2_.max;
         TankTraceUtil.logBattleList("BattleListItemParams.accessible id=" + param1.battle.name + " accessible=" + this.accessible + " battleInfoServiceNull=" + (battleInfoService == null));
         this.currentBattle = param1.battle.name == battleInfoService.currentBattleId;
         TankTraceUtil.logBattleList("BattleListItemParams.current id=" + param1.battle.name + " current=" + this.currentBattle + " formatUtilNull=" + (battleFormatUtil == null) + " modeNull=" + (this.createParams.equipmentConstraintsMode == null));
         var _loc3_:String = this.getEquipmentConstraintsModeName();
         TankTraceUtil.logBattleList("BattleListItemParams.formatMode id=" + param1.battle.name + " formatMode=" + _loc3_ + " parkour=" + this.createParams.parkourMode);
         this.formatBattle = battleFormatUtil.isFormatBattle(_loc3_,this.createParams.parkourMode);
         this.formatName = battleFormatUtil.getShortFormatName(_loc3_,this.createParams.parkourMode);
         TankTraceUtil.logBattleList("BattleListItemParams.end id=" + param1.battle.name + " formatBattle=" + this.formatBattle + " formatName=" + this.formatName);
      }

      private function getEquipmentConstraintsModeName() : String
      {
         if(this.createParams.equipmentConstraintsMode == null || this.createParams.equipmentConstraintsMode == EquipmentConstraintsMode.NONE)
         {
            return null;
         }
         return this.createParams.equipmentConstraintsMode.name;
      }
      
      public function get createParams() : BattleCreateParameters
      {
         return this.params.createParams;
      }
      
      public function get id() : String
      {
         return this.params.battle.name;
      }
      
      public function get suspicionLevel() : int
      {
         return this.params.suspicionLevel.value;
      }
      
      public function get friends() : int
      {
         return this.params.friends;
      }
   }
}
