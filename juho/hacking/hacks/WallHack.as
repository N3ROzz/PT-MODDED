package juho.hacking.hacks {
   
   import juho.hacking.Hack;
   import juho.hacking.event.HackEventDispatcher;
   import juho.hacking.event.LocalTankInitedEvent;
   import alternativa.tanks.models.battle.battlefield.BattlefieldModel;
   import alternativa.tanks.models.battle.battlefield.WallHackSystem;
   
	/**
    * Wall Hack - marker overlay for revealing enemy tanks through walls
    * @author juhe
    */
   
   public class WallHack extends Hack {
      private static const NAME:String = "Wall Hack";
      
      // ID is used in saving to disk
      private static const ID:String = "WALL_HACK";
      
      // Configuration properties - static so RegularUserTitleRenderer can read them
      public static var showNickname:Boolean = true;
      public static var visualMode:String = WallHackSystem.MODE_MARKERS;
      
      public function WallHack() {
         super(NAME, ID);
         
         this.addProperty("Show Nickname", true, "Boolean", onShowNicknameChanged);
         HackEventDispatcher.singleton.addEventListener(LocalTankInitedEvent.LOCAL_TANK_INITED, this.localTankInited);
         this.applyState();
      }
      
      private function onShowNicknameChanged(value:*):void {
         showNickname = Boolean(value);
         WallHackSystem.showNickname = showNickname;
      }
      
      private function syncSettingsFromProperties():void {
         showNickname = Boolean(this.getProperty("Show Nickname").value);
         visualMode = WallHackSystem.MODE_MARKERS;
         WallHackSystem.showNickname = showNickname;
         WallHackSystem.visualMode = visualMode;
      }
      
      override public function enable():void {
         super.enable();
         this.applyState();
      }
      
      override public function disable():void {
         super.disable();
         this.applyState();
      }
      
      private function localTankInited(e:LocalTankInitedEvent):void {
         this.applyState();
      }

      private function applyState():void {
         this.syncSettingsFromProperties();
         WallHackSystem.isEnabled = this.isEnabled;
         if(this.isEnabled) {
            this.reveal();
         } else {
            this.conceal();
         }
      }
      
      private function reveal():void {
         if(BattlefieldModel.wallHack != null) {
            BattlefieldModel.wallHack.revealTanks();
         }
      }

      private function conceal():void {
         if(BattlefieldModel.wallHack != null) {
            BattlefieldModel.wallHack.concealTanks();
         }
      }
   }
}
