package scpacker.networking.protocol.packets.battlechat
{
   import scpacker.networking.protocol.AbstractPacketHandler;
   import alternativa.types.Long;
   import scpacker.networking.protocol.AbstractPacket;
   import alternativa.tanks.models.battle.gui.chat.BattleChatModel;
   import projects.tanks.client.battlefield.models.battle.gui.chat.BattleChatModelBase;
   import platform.client.fp10.core.model.impl.Model;
   import scpacker.networking.protocol.packets.battle.BattlePacketHandler;
   
   public class BattleChatPacketHandler extends AbstractPacketHandler
   {
      private var battleChatModel:BattleChatModel;
      
      public function BattleChatPacketHandler()
      {
         super();
         this.id = 61;
         this.battleChatModel = BattleChatModel(modelRegistry.getModel(BattleChatModelBase.modelId));
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case ReceiveBattleChatInPacket.id:
               this.handleReceiveBattleChat(param1 as ReceiveBattleChatInPacket);
               break;
            case AddSpectatorTeamMessageInPacket.id:
               this.handleAddSpectatorTeamMessage(param1 as AddSpectatorTeamMessageInPacket);
               break;
            case ReceiveBattleSystemChatInPacket.id:
               this.handleReceiveBattleSystemChat(param1 as ReceiveBattleSystemChatInPacket);
               break;
            case AddTeamMessageInPacket.id:
               this.handleAddTeamMessage(param1 as AddTeamMessageInPacket);
               break;
            case BattleChatLoadedInPacket.id:
               this.handleBattleChatLoaded();
               break;
            case BattleChatUpdateTeamHeaderInPacket.id:
               this.handleUpdateTeamHeader(param1 as BattleChatUpdateTeamHeaderInPacket);
         }
      }
      
      private function handleReceiveBattleChat(param1:ReceiveBattleChatInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return; // Prevent disconnect if object is stale
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            this.battleChatModel.addMessage(param1.userId,param1.message,param1.team);
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function handleAddSpectatorTeamMessage(param1:AddSpectatorTeamMessageInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            this.battleChatModel.addSpectatorTeamMessage(param1.username,param1.message);
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function handleReceiveBattleSystemChat(param1:ReceiveBattleSystemChatInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            this.battleChatModel.addSystemMessage(param1.message);
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function handleAddTeamMessage(param1:AddTeamMessageInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            this.battleChatModel.addTeamMessage(param1.userId,param1.message,param1.team);
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function handleBattleChatLoaded() : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            this.battleChatModel.objectLoaded();
         }
         finally
         {
            Model.popObject();
         }
      }
      
      private function handleUpdateTeamHeader(param1:BattleChatUpdateTeamHeaderInPacket) : void
      {
         if(BattlePacketHandler.battlefieldGameObject == null)
         {
            return;
         }
         Model.object = BattlePacketHandler.battlefieldGameObject;
         try
         {
            this.battleChatModel.updateTeamHeader(param1.header);
         }
         finally
         {
            Model.popObject();
         }
      }
   }
}
