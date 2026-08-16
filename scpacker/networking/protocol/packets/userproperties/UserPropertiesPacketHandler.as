package scpacker.networking.protocol.packets.userproperties
{
   import alternativa.tanks.model.userproperties.UserPropertiesModel;
   import projects.tanks.client.panel.model.profile.userproperties.UserPropertiesModelBase;
   import projects.tanks.client.users.model.userbattlestatistics.rank.RankBounds;
   import scpacker.networking.protocol.AbstractPacket;
   import scpacker.networking.protocol.AbstractPacketHandler;
   
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
            this.userPropertiesModel.changeCrystal(param1.crystals);
         }
      }
      
      private function updateRank(param1:UpdateRankInPacket) : void
      {
         if(param1 != null)
         {
            this.userPropertiesModel.updateRank(param1.rank,param1.score,new RankBounds(param1.rankBoundMin,param1.rankBoundMax),param1.rankReward,false,false,true);
         }
      }
      
      private function updateUserRating(param1:UpdateUserRatingInPacket) : void
      {
         if(param1 != null)
         {
            this.userPropertiesModel.updateUserRating(param1.userRating,param1.place + 1);
         }
      }
      
      private function updateScore(param1:UpdateScoreInPacket) : void
      {
         if(param1 != null)
         {
            this.userPropertiesModel.updateScore(param1.score,true);
         }
      }
   }
}
