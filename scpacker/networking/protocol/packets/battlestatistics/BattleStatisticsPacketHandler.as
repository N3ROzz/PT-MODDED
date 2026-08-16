package scpacker.networking.protocol.packets.battlestatistics
{
   import scpacker.networking.protocol.AbstractPacketHandler;
   import alternativa.osgi.OSGi;
   import alternativa.tanks.models.bonus.battlefield.BattlefieldBonusesModel;
   import alternativa.types.Long;
   import alternativa.tanks.models.battle.battlefield.BattlefieldModel;
   import alternativa.tanks.models.statistics.StatisticsModel;
   import alternativa.tanks.service.money.IMoneyService;
   import scpacker.networking.protocol.AbstractPacket;
   import projects.tanks.client.battleservice.model.statistics.StatisticsModelBase;
   import projects.tanks.client.battlefield.models.battle.battlefield.BattlefieldModelBase;
   import scpacker.networking.protocol.packets.battle.BattlePacketHandler;
   import platform.client.fp10.core.model.impl.Model;
   import projects.tanks.client.battleservice.model.statistics.dm.StatisticsDMModelBase;
   import projects.tanks.client.battleservice.model.statistics.UserReward;
   
   public class BattleStatisticsPacketHandler extends AbstractPacketHandler
   {
      private var statisticsModel:StatisticsModel;
      private var battlefieldModel:BattlefieldModel;
      private var moneyService:IMoneyService;
      private var lastFund:int = 0;
      
      public function BattleStatisticsPacketHandler()
      {
         super();
         this.id = 37;
         this.statisticsModel = StatisticsModel(modelRegistry.getModel(StatisticsModelBase.modelId));
         this.battlefieldModel = BattlefieldModel(modelRegistry.getModel(BattlefieldModelBase.modelId));
         this.moneyService = IMoneyService(OSGi.getInstance().getService(IMoneyService));
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case BattleFundInPacket.id:
               this.fundChange(param1 as BattleFundInPacket);
               break;
            case InitStatisticsInPacket.id:
               this.initStatisticsModel(param1 as InitStatisticsInPacket);
               break;
            case StatisticsModelLoadedPostInPacket.id:
               this.statisticsModelLoadedPost();
               break;
            case ComplaintConfirmedInPacket.id:
               this.complaintConfirmed();
               break;
            case RankUpInPacket.id:
               this.rankChanged(param1 as RankUpInPacket);
               break;
            case RoundFinishInPacket.id:
               this.roundFinish(param1 as RoundFinishInPacket);
               break;
            case RoundStartInPacket.id:
               this.roundStart(param1 as RoundStartInPacket);
               break;
            case StatusProbablyCheaterChangedInPacket.id:
               this.statusProbablyCheaterChanged(param1 as StatusProbablyCheaterChangedInPacket);
         }
      }
      
      private function initStatisticsModel(param1:InitStatisticsInPacket) : void
      {
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
         param1.statisticsModelCC.valuableRound = true;
         this.lastFund = param1.statisticsModelCC.fund;
         this.statisticsModel.putInitParams(param1.statisticsModelCC);
         this.statisticsModel.objectLoaded();
         }          finally          {             Model.popObject();          }
      }
      
      private function statisticsModelLoadedPost() : void
      {
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
         this.statisticsModel.objectLoadedPost();
         }          finally          {             Model.popObject();          }
      }
      
      private function fundChange(param1:BattleFundInPacket) : void
      {
         var _loc2_:int = param1.fund - this.lastFund;
         this.lastFund = param1.fund;
         if(_loc2_ > 0 && BattlefieldBonusesModel.consumeLocalBonusTaken() && this.moneyService != null)
         {
            this.moneyService.setServerCrystals(this.moneyService.crystal + _loc2_);
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
         this.statisticsModel.fundChange(param1.fund);
         }          finally          {             Model.popObject();          }
      }
      
      private function complaintConfirmed() : void
      {
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
         this.statisticsModel.onComplaintConfirmed();
         }          finally          {             Model.popObject();          }
      }
      
      private function rankChanged(param1:RankUpInPacket) : void
      {
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
         this.statisticsModel.onRankChanged(param1.userId,param1.rank, false);
         }          finally          {             Model.popObject();          }
      }
      
      private function roundFinish(param1:RoundFinishInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            this.statisticsModel.roundFinish(true,param1.reward,param1.timeToRestart);
            this.battlefieldModel.battleFinish();
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function roundStart(param1:RoundStartInPacket) : void
      {
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
         this.statisticsModel.roundStart(param1.timeLimitInSec,true);
         this.battlefieldModel.battleRestart();
         }          finally          {             Model.popObject();          }
      }
      
      private function statusProbablyCheaterChanged(param1:StatusProbablyCheaterChangedInPacket) : void
      {
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
         this.statisticsModel.statusProbablyCheaterChanged(param1.userId,param1.suspicious);
         }          finally          {             Model.popObject();          }
      }

      private function describeRewards(param1:Vector.<UserReward>) : String
      {
         var _loc2_:Array = [];
         var _loc3_:UserReward = null;
         if(param1 == null)
         {
            return "null";
         }
         for each(_loc3_ in param1)
         {
            _loc2_.push(_loc3_.userId + ":reward=" + _loc3_.reward + ",premium=" + _loc3_.premiumBonusReward + ",newbie=" + _loc3_.newbiesAbonementBonusReward);
         }
         return _loc2_.join("|");
      }
   }
}
