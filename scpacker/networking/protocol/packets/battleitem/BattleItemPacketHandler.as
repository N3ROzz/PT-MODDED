package scpacker.networking.protocol.packets.battleitem
{
   import alternativa.tanks.model.item.BattleItemModel;
   import alternativa.tanks.model.item.dm.BattleDMItemModel;
   import alternativa.tanks.model.item.team.BattleTeamItemModel;
   import platform.client.fp10.core.model.impl.Model;
   import platform.client.fp10.core.type.IGameObject;
   import platform.client.fp10.core.type.ISpace;
   import projects.tanks.client.battleselect.model.item.BattleItemModelBase;
   import projects.tanks.client.battleselect.model.item.dm.BattleDMItemModelBase;
   import projects.tanks.client.battleselect.model.item.team.BattleTeamItemModelBase;
   import scpacker.SpaceAndGameObjectIds;
   import scpacker.networking.protocol.AbstractPacket;
   import scpacker.networking.protocol.AbstractPacketHandler;

   public class BattleItemPacketHandler extends AbstractPacketHandler
   {
      private var battleItemModel:BattleItemModel;
      private var battleDMItemModel:BattleDMItemModel;
      private var battleTeamItemModel:BattleTeamItemModel;
      private var battleSelectSpace:ISpace;

      public function BattleItemPacketHandler()
      {
         super();
         this.id = 32;
         this.battleItemModel = BattleItemModel(modelRegistry.getModel(BattleItemModelBase.modelId));
         this.battleDMItemModel = BattleDMItemModel(modelRegistry.getModel(BattleDMItemModelBase.modelId));
         this.battleTeamItemModel = BattleTeamItemModel(modelRegistry.getModel(BattleTeamItemModelBase.modelId));
         this.battleSelectSpace = spaceRegistry.getSpace(SpaceAndGameObjectIds.BATTLE_SELECT_SPACE_ID);
      }

      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case ItemBattleMadePrivateInPacket.id:
               this.withBattle(ItemBattleMadePrivateInPacket(param1).battleId,this.battleItemModel.madePrivate);
               break;
            case ItemLeftDmBattleInPacket.id:
               var _loc1_:ItemLeftDmBattleInPacket = ItemLeftDmBattleInPacket(param1);
               this.withBattle(_loc1_.battleId,function():void { battleDMItemModel.removeUser(_loc1_.userId); });
               break;
            case ItemLeftTeamBattleInPacket.id:
               var _loc2_:ItemLeftTeamBattleInPacket = ItemLeftTeamBattleInPacket(param1);
               this.withBattle(_loc2_.battleId,function():void { battleTeamItemModel.removeUser(_loc2_.userId); });
               break;
            case ItemJoinedDmBattleInPacket.id:
               var _loc3_:ItemJoinedDmBattleInPacket = ItemJoinedDmBattleInPacket(param1);
               this.withBattle(_loc3_.battleId,function():void { battleDMItemModel.addUser(_loc3_.userId); });
               break;
            case ItemJoinedTeamBattleInPacket.id:
               var _loc4_:ItemJoinedTeamBattleInPacket = ItemJoinedTeamBattleInPacket(param1);
               this.withBattle(_loc4_.battleId,function():void { battleTeamItemModel.addUser(_loc4_.userId,_loc4_.team); });
               break;
            case ItemSwapTeamsInPacket.id:
               this.withBattle(ItemSwapTeamsInPacket(param1).battleId,this.battleTeamItemModel.swapTeams);
               break;
            case ItemUpdateBattleNameInPacket.id:
               var _loc5_:ItemUpdateBattleNameInPacket = ItemUpdateBattleNameInPacket(param1);
               this.withBattle(_loc5_.battleId,function():void { battleItemModel.setBattleName(_loc5_.battleName); });
               break;
            case ItemUpdateBattleSuspicionInPacket.id:
               var _loc6_:ItemUpdateBattleSuspicionInPacket = ItemUpdateBattleSuspicionInPacket(param1);
               this.withBattle(_loc6_.battleId,function():void { battleItemModel.updateSuspicion(_loc6_.suspicionLevel); });
         }
      }

      private function withBattle(param1:String, param2:Function) : void
      {
         var _loc1_:IGameObject = this.battleSelectSpace.getObjectByName(param1);
         Model.withObject(_loc1_,param2);
      }
   }
}
