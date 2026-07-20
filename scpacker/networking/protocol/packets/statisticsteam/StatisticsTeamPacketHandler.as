package scpacker.networking.protocol.packets.statisticsteam
{
   import scpacker.networking.protocol.AbstractPacketHandler;
   import alternativa.tanks.models.statistics.team.StatisticsTeamModel;
   import alternativa.osgi.OSGi;
   import alternativa.tanks.models.statistics.IClientUserInfo;
   import scpacker.networking.protocol.AbstractPacket;
   import projects.tanks.client.battleservice.model.statistics.team.StatisticsTeamModelBase;
   import platform.client.fp10.core.model.impl.Model;
   import scpacker.networking.protocol.packets.battle.BattlePacketHandler;
   import alternativa.tanks.model.userproperties.UserPropertiesModel;
   import projects.tanks.client.panel.model.profile.userproperties.UserPropertiesModelBase;
   import projects.tanks.client.battleservice.model.statistics.UserStat;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.userproperties.IUserPropertiesService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.premium.PremiumService;
   import utils.TankTraceUtil;
   
   public class StatisticsTeamPacketHandler extends AbstractPacketHandler
   {
      private var statisticsTeamModel:StatisticsTeamModel;
      private var userPropertiesModel:UserPropertiesModel;
      private var userPropertiesService:IUserPropertiesService;
      private var premiumService:PremiumService;
      private var localScore:int = 0;
      
      public function StatisticsTeamPacketHandler()
      {
         super();
         this.id = 44;
         this.statisticsTeamModel = StatisticsTeamModel(modelRegistry.getModel(StatisticsTeamModelBase.modelId));
         this.userPropertiesModel = UserPropertiesModel(modelRegistry.getModel(UserPropertiesModelBase.modelId));
         this.userPropertiesService = IUserPropertiesService(OSGi.getInstance().getService(IUserPropertiesService));
         this.premiumService = PremiumService(OSGi.getInstance().getService(PremiumService));
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case StatisticsTeamChangeTeamScoreInPacket.id:
               this.changeTeamScore(param1 as StatisticsTeamChangeTeamScoreInPacket);
               break;
            case StatisticsTeamChangeUserStatInPacket.id:
               this.changeUserStat(param1 as StatisticsTeamChangeUserStatInPacket);
               break;
            case InitStatisticsTeamModelInPacket.id:
               this.loadStatisticsTeamModel(param1 as InitStatisticsTeamModelInPacket);
               break;
            case StatisticsTeamSwapTeamInPacket.id:
               this.swapTeam(param1 as StatisticsTeamSwapTeamInPacket);
               break;
            case StatisticsTeamUserConnectInPacket.id:
               this.userConnect(param1 as StatisticsTeamUserConnectInPacket);
               break;
            case StatisticsTeamUserLeftInPacket.id:
               this.userDisconnect(param1 as StatisticsTeamUserLeftInPacket);
         }
      }
      
      private function loadStatisticsTeamModel(param1:InitStatisticsTeamModelInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         //OSGi.getInstance().registerService(IClientUserInfo,this.statisticsTeamModel);
         BattlePacketHandler.battlefieldGameObject.gameClass.models.push(StatisticsTeamModelBase.modelId);
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            this.localScore = 0;
            TankTraceUtil.logRatings("Team initStatistics localScore=0 red=" + param1.statisticsTeamCC.redScore + " blue=" + param1.statisticsTeamCC.blueScore);
            this.statisticsTeamModel.putInitParams(param1.statisticsTeamCC);
            this.statisticsTeamModel.objectLoaded();
            this.statisticsTeamModel.objectLoadedPost();
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function changeUserStat(param1:StatisticsTeamChangeUserStatInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            TankTraceUtil.logRatings("Team changeUserStat user=" + (param1.userStats == null ? "null" : param1.userStats.user) + " score=" + (param1.userStats == null ? -1 : param1.userStats.score) + " team=" + param1.team);
            this.updateLocalScore(param1.userStats);
            this.statisticsTeamModel.changeUserStat(param1.userStats,param1.team);
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function changeTeamScore(param1:StatisticsTeamChangeTeamScoreInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            TankTraceUtil.logRatings("Team changeTeamScore team=" + param1.team + " score=" + param1.score);
            this.statisticsTeamModel.changeTeamScore(param1.team,param1.score);
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function swapTeam(param1:StatisticsTeamSwapTeamInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            TankTraceUtil.logRatings("Team swapTeam aCount=" + (param1.teamAUserStats == null ? -1 : param1.teamAUserStats.length) + " bCount=" + (param1.teamBUserStats == null ? -1 : param1.teamBUserStats.length));
            this.statisticsTeamModel.swapTeam(param1.teamAUserStats,param1.teamBUserStats);
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function userConnect(param1:StatisticsTeamUserConnectInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            this.statisticsTeamModel.userConnect(param1.userId,param1.userInfos,param1.team);
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function userDisconnect(param1:StatisticsTeamUserLeftInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            this.statisticsTeamModel.userDisconnect(param1.userId);
         }
         finally
         {
            Model.popObject();
         }
      }

      private function updateLocalScore(param1:UserStat) : void
      {
         var _loc2_:int = 0;
         if(param1 == null || this.userPropertiesService == null || param1.user != this.userPropertiesService.userId)
         {
            return;
         }
         _loc2_ = param1.score - this.localScore;
         TankTraceUtil.logRatings("Team localScore user=" + param1.user + " oldBattleScore=" + this.localScore + " newBattleScore=" + param1.score + " delta=" + _loc2_ + " accountScore=" + this.userPropertiesService.score + " premium=" + (this.premiumService != null && this.premiumService.hasPremium()));
         this.localScore = param1.score;
         if(_loc2_ > 0)
         {
            this.userPropertiesModel.updateScore(this.userPropertiesService.score + this.calculateAccountScoreDelta(_loc2_));
         }
      }

      private function calculateAccountScoreDelta(param1:int) : int
      {
         if(this.premiumService != null && this.premiumService.hasPremium())
         {
            return param1 + int(Math.ceil(param1 * 0.5));
         }
         return param1;
      }
   }
}
