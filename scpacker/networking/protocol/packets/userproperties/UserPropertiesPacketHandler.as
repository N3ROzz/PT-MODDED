package scpacker.networking.protocol.packets.userproperties
{
   import alternativa.tanks.model.userproperties.UserPropertiesModel;
   import projects.tanks.client.panel.model.profile.userproperties.UserPropertiesModelBase;
   import projects.tanks.client.users.model.userbattlestatistics.rank.RankBounds;
   import scpacker.networking.protocol.AbstractPacket;
   import scpacker.networking.protocol.AbstractPacketHandler;
   import utils.TankTraceUtil;
   
   public class UserPropertiesPacketHandler extends AbstractPacketHandler
   {
      private var userPropertiesModel:UserPropertiesModel;
      
      public function UserPropertiesPacketHandler()
      {
         super();
         this.id = 29;
         this.userPropertiesModel = UserPropertiesModel(modelRegistry.getModel(UserPropertiesModelBase.modelId));
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         TankTraceUtil.logRatings("UserProperties packet id=" + param1.getId());
         switch(param1.getId())
         {
            case UpdateCrystalsInPacket.id:
               this.updateCrystals(param1 as UpdateCrystalsInPacket);
               break;
            case UpdateRankInPacket.id:
               this.updateRank(param1 as UpdateRankInPacket);
               break;
            case UpdateUserRatingInPacket.id:
               this.updateUserRating(param1 as UpdateUserRatingInPacket);
               break;
            case UpdateScoreInPacket.id:
               this.updateScore(param1 as UpdateScoreInPacket);
         }
      }
      
      private function updateCrystals(param1:UpdateCrystalsInPacket) : void
      {
         if(param1 != null)
         {
            TankTraceUtil.logRatings("UpdateCrystals crystals=" + param1.crystals);
            this.userPropertiesModel.changeCrystal(param1.crystals);
         }
      }
      
      private function updateRank(param1:UpdateRankInPacket) : void
      {
         if(param1 != null)
         {
            TankTraceUtil.logRatings("UpdateRank rank=" + param1.rank + " score=" + param1.score + " min=" + param1.rankBoundMin + " max=" + param1.rankBoundMax + " reward=" + param1.rankReward);
            this.userPropertiesModel.updateRank(param1.rank,param1.score,new RankBounds(param1.rankBoundMin,param1.rankBoundMax),param1.rankReward,false,false,true);
         }
      }
      
      private function updateUserRating(param1:UpdateUserRatingInPacket) : void
      {
         if(param1 != null)
         {
            TankTraceUtil.logRatings("UpdateUserRating rawRating=" + param1.userRating + " rawPlace=" + param1.place + " displayPlace=" + (param1.place + 1));
            this.userPropertiesModel.updateUserRating(param1.userRating,param1.place + 1);
         }
      }
      
      private function updateScore(param1:UpdateScoreInPacket) : void
      {
         if(param1 != null)
         {
            TankTraceUtil.logRatings("UpdateScore score=" + param1.score);
            this.userPropertiesModel.updateScore(param1.score,true);
         }
      }
   }
}
