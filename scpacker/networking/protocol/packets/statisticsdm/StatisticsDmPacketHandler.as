package scpacker.networking.protocol.packets.statisticsdm
{
   import alternativa.types.Long;
   import scpacker.networking.protocol.AbstractPacket;
   import scpacker.networking.protocol.AbstractPacketHandler;
   import alternativa.tanks.models.statistics.dm.StatisticsDmModel;
   import projects.tanks.client.battleservice.model.statistics.dm.StatisticsDMModelBase;
   import platform.client.fp10.core.model.impl.Model;
   import scpacker.networking.protocol.packets.battle.BattlePacketHandler;
   import alternativa.tanks.model.userproperties.UserPropertiesModel;
   import projects.tanks.client.panel.model.profile.userproperties.UserPropertiesModelBase;
   import alternativa.osgi.OSGi;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.userproperties.IUserPropertiesService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.premium.PremiumService;
   import projects.tanks.client.battleservice.model.statistics.UserStat;
   import utils.TankTraceUtil;
   
   public class StatisticsDmPacketHandler extends AbstractPacketHandler
   {
      private var statisticsDMModel:StatisticsDmModel;
      private var userPropertiesModel:UserPropertiesModel;
      private var userPropertiesService:IUserPropertiesService;
      private var premiumService:PremiumService;
      private var localScore:int = 0;
      
      public function StatisticsDmPacketHandler()
      {
         super();
         this.id = 48;
         this.statisticsDMModel = StatisticsDmModel(modelRegistry.getModel(StatisticsDMModelBase.modelId));
         this.userPropertiesModel = UserPropertiesModel(modelRegistry.getModel(UserPropertiesModelBase.modelId));
         this.userPropertiesService = IUserPropertiesService(OSGi.getInstance().getService(IUserPropertiesService));
         this.premiumService = PremiumService(OSGi.getInstance().getService(PremiumService));
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case ChangeUserStatInPacket.id:
               this.changeUserStat(param1 as ChangeUserStatInPacket);
               break;
            case InitDMStatisticsInPacket.id:
               this.initDmStatistics(param1 as InitDMStatisticsInPacket);
               break;
            case RefreshUsersStatInPacket.id:
               this.refreshUsersStat(param1 as RefreshUsersStatInPacket);
               break;
            case DmStatisticsUserConnectInPacket.id:
               this.userConnect(param1 as DmStatisticsUserConnectInPacket);
               break;
            case DmStatisticsUserDisconnectInPacket.id:
               this.userDisconnect(param1 as DmStatisticsUserDisconnectInPacket);
         }
      }
      
      private function changeUserStat(param1:ChangeUserStatInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return; // Prevent null reference and disconnects
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            TankTraceUtil.logRatings("DM changeUserStat user=" + (param1.userStats == null ? "null" : param1.userStats.user) + " score=" + (param1.userStats == null ? -1 : param1.userStats.score));
            this.updateLocalScore(param1.userStats);
            this.statisticsDMModel.changeUserStat(param1.userStats);
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function initDmStatistics(param1:InitDMStatisticsInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         //OSGi.getInstance().registerService(IClientUserInfo,this.statisticsDMModel);
         BattlePacketHandler.battlefieldGameObject.gameClass.models.push(StatisticsDMModelBase.modelId);
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            this.localScore = 0;
            TankTraceUtil.logRatings("DM initStatistics localScore=0");
            this.statisticsDMModel.putInitParams(param1.statisticsDmCC);
            this.statisticsDMModel.objectLoaded();
            this.statisticsDMModel.objectLoadedPost();
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function refreshUsersStat(param1:RefreshUsersStatInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            TankTraceUtil.logRatings("DM refreshUsersStat count=" + (param1.userStats == null ? -1 : param1.userStats.length));
            this.updateLocalScoreFromVector(param1.userStats);
            this.statisticsDMModel.refreshUsersStat(param1.userStats);
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function userConnect(param1:DmStatisticsUserConnectInPacket) : void
      {
         Model.object = BattlePacketHandler.battlefieldGameObject;
         this.statisticsDMModel.userConnect(param1.userId,param1.userInfos);
         Model.popObject();
      }
      
      private function userDisconnect(param1:DmStatisticsUserDisconnectInPacket) : void
      {
         Model.object = BattlePacketHandler.battlefieldGameObject;
         this.statisticsDMModel.userDisconnect(param1.userId);
         Model.popObject();
      }

      private function updateLocalScore(param1:UserStat) : void
      {
         var _loc2_:int = 0;
         if(param1 == null || this.userPropertiesService == null || param1.user != this.userPropertiesService.userId)
         {
            return;
         }
         _loc2_ = param1.score - this.localScore;
         TankTraceUtil.logRatings("DM localScore user=" + param1.user + " oldBattleScore=" + this.localScore + " newBattleScore=" + param1.score + " delta=" + _loc2_ + " accountScore=" + this.userPropertiesService.score + " premium=" + (this.premiumService != null && this.premiumService.hasPremium()));
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

      private function updateLocalScoreFromVector(param1:Vector.<UserStat>) : void
      {
         var _loc2_:UserStat = null;
         if(param1 == null)
         {
            return;
         }
         for each(_loc2_ in param1)
         {
            this.updateLocalScore(_loc2_);
         }
      }
   }
}
