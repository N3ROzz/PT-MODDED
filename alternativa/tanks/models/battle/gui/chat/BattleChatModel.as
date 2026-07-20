package alternativa.tanks.models.battle.gui.chat
{
   import alternativa.osgi.service.display.IDisplay;
   import alternativa.tanks.model.chat.ChatSettingsTracker;
   import alternativa.tanks.services.battlegui.BattleGUIService;
   import alternativa.types.Long;
   import flash.events.KeyboardEvent;
   import flash.ui.Keyboard;
   import platform.client.fp10.core.model.ObjectLoadListener;
   import platform.client.fp10.core.model.ObjectUnloadListener;
   import projects.tanks.client.battlefield.models.battle.gui.chat.BattleChatModelBase;
   import projects.tanks.client.battlefield.models.battle.gui.chat.IBattleChatModelBase;
   import projects.tanks.client.battleservice.model.battle.team.BattleTeam;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.battle.IBattleInfoService;
   import services.contextmenu.ContextMenuServiceEvent;
   import services.contextmenu.IContextMenuService;
   
   [ModelInfo]
   public class BattleChatModel extends BattleChatModelBase implements IBattleChatModelBase, IBattleChat, ObjectLoadListener, ObjectUnloadListener
   {
      
      [Inject] // added
      public static var display:IDisplay;
      
      [Inject] // added
      public static var battleInfoService:IBattleInfoService;
      
      [Inject] // added
      public static var battleGuiService:BattleGUIService;
      
      [Inject] // added
      public static var contextMenuService:IContextMenuService;
      
      private var battleChat:BattleChat;
      
      private var teamHeaderText:String;
      private var sendMessageHandler:Function;
      private var sendCmdHandler:Function;
      private var loaded:Boolean = false;
      
      private const VOTE_CMD:* = "/vote ";
      
      public function BattleChatModel()
      {
         super();
         this.battleChat = new BattleChat();
      }
      
      [Obfuscation(rename="false")]
      public function objectLoaded() : void
      {
         if(this.loaded)
         {
            this.objectUnloaded();
         }
         this.battleChat.setBattleObject(object);
         this.battleChat.clear();
         this.battleChat.locked = false;
         this.sendMessageHandler = getFunctionWrapper(this.onSendMessage);
         this.sendCmdHandler = getFunctionWrapper(this.onSendCmd);
         this.battleChat.addEventListener(BattleChatEvent.SEND_MESSAGE,this.sendMessageHandler);
         battleGuiService.getGuiContainer().addChild(this.battleChat);
         display.stage.addEventListener(KeyboardEvent.KEY_UP,this.onKeyUp);
         this.teamHeaderText = "";
         putData(ChatLocker,new ChatLocker(this.battleChat));
         putData(ChatSettingsTracker,new ChatSettingsTracker(this.battleChat));
         contextMenuService.addEventListener(ContextMenuServiceEvent.VOTE_USER,this.sendCmdHandler);
         this.loaded = true;
      }
      
      [Obfuscation(rename="false")]
      public function objectUnloaded() : void
      {
         if(!this.loaded)
         {
            return;
         }
         this.battleChat.closeChat();
         this.battleChat.locked = true;
         if(this.sendMessageHandler != null)
         {
            this.battleChat.removeEventListener(BattleChatEvent.SEND_MESSAGE,this.sendMessageHandler);
            this.sendMessageHandler = null;
         }
         if(this.sendCmdHandler != null)
         {
            contextMenuService.removeEventListener(ContextMenuServiceEvent.VOTE_USER,this.sendCmdHandler);
            this.sendCmdHandler = null;
         }
         this.battleChat.clear();
         if(this.battleChat.parent != null)
         {
            this.battleChat.parent.removeChild(this.battleChat);
         }
         display.stage.removeEventListener(KeyboardEvent.KEY_UP,this.onKeyUp);
         this.loaded = false;
      }
      
      [Obfuscation(rename="false")]
      public function addMessage(param1:String, param2:String, param3:BattleTeam) : void
      {
         this.addUserMessageWithMessageLabel(param1,param2,param3);
      }
      
      [Obfuscation(rename="false")]
      public function addTeamMessage(param1:String, param2:String, param3:BattleTeam) : void
      {
         this.addUserMessageWithMessageLabel(param1,param2,param3,true);
      }
      
      private function addUserMessageWithMessageLabel(param1:String, param2:String, param3:BattleTeam, param4:Boolean = false) : void
      {
         var _loc5_:Boolean = param1 == "";
         this.battleChat.addUserMessage(param1,param3,param2 + "\n",param4,_loc5_);
      }
      
      [Obfuscation(rename="false")]
      public function addSpectatorTeamMessage(param1:String, param2:String) : void
      {
         this.battleChat.addUserMessage("",BattleTeam.NONE,param2 + "\n",true,true);
      }
      
      [Obfuscation(rename="false")]
      public function addSystemMessage(param1:String) : void
      {
         this.battleChat.addSystemMessage(param1);
      }
      
      private function onKeyUp(param1:KeyboardEvent) : void
      {
         if(param1.keyCode == Keyboard.ENTER)
         {
            if(battleInfoService.isSpectatorMode())
            {
               this.battleChat.setSpectatorList(this.teamHeaderText);
            }
            this.battleChat.openChat();
         }
      }
      
      private function onSendMessage(param1:BattleChatEvent) : void
      {
         if(this.loaded)
         {
            server.sendMessage(param1.message,param1.teamOnly);
         }
      }
      
      private function onSendCmd(param1:ContextMenuServiceEvent) : void
      {
         server.sendMessage(this.VOTE_CMD + param1.uid,false);
      }
      
      [Obfuscation(rename="false")]
      public function updateTeamHeader(param1:String) : void
      {
         this.teamHeaderText = param1;
      }
      
      public function getChat() : BattleChat
      {
         return this.battleChat;
      }
   }
}
