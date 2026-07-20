package alternativa.tanks.models.bonus.goldbonus
{
   import alternativa.tanks.battle.BattleService;
   import alternativa.tanks.models.battle.ctf.MessageColor;
   import alternativa.tanks.models.battle.gui.BattlefieldGUI;
   import alternativa.tanks.models.bonus.notification.BonusNotification;
   import alternativa.tanks.services.bonusregion.IBonusRegionService;
   import platform.client.fp10.core.resource.types.SoundResource;
   import platform.client.fp10.core.type.IGameObject;
   import projects.tanks.client.battlefield.models.bonus.battle.bonusregions.BonusRegionData;
   import projects.tanks.client.battlefield.models.bonus.battle.goldbonus.GoldBonusesModelBase;
   import projects.tanks.client.battlefield.models.bonus.battle.goldbonus.IGoldBonusesModelBase;
   import projects.tanks.client.battlefield.models.bonus.battle.goldbonus.GoldBonusCC;
   import alternativa.math.Vector3;
   import alternativa.tanks.battle.BattleUtils;
   import projects.tanks.client.battlefield.models.bonus.bonus.BonusesType;
   import utils.goldbox.GoldBoxDiagnostics;
   
   [ModelInfo]
   public class GoldBonusesModel extends GoldBonusesModelBase implements IGoldBonusesModelBase, IGoldBonus
   {
      
      [Inject] // added
      public static var battleService:BattleService;
      
      [Inject] // added
      public static var bonusRegionService:IBonusRegionService;
      
      private static const UID_PATTERN:String = "%USERNAME%";
      
      public function GoldBonusesModel()
      {
         super();
      }
      
      public function getRegions() : Vector.<BonusRegionData>
      {
         return getInitParam().regionsData;
      }
      
      [Obfuscation(rename="false")]
      public function notificationBonus(param1:IGameObject, param2:BonusRegionData) : void
      {
         var _loc3_:BonusNotification = BonusNotification(param1.adapt(BonusNotification));
         this.notification(param1,param2,_loc3_.getMessage());
      }
      
      [Obfuscation(rename="false")]
      public function notificationBonusContainsUid(param1:IGameObject, param2:String, param3:BonusRegionData) : void
      {
         var _loc4_:BonusNotification = BonusNotification(param1.adapt(BonusNotification));
         var _loc5_:String = _loc4_.getMessageContainsUid().replace(UID_PATTERN,param2);
         this.notification(param1,param3,_loc5_);
      }
      
      private function notification(param1:IGameObject, param2:BonusRegionData, param3:String) : void
      {
         var _loc4_:SoundResource = BonusNotification(param1.adapt(BonusNotification)).getSoundNotification();
         if(_loc4_ != null)
         {
            GoldBoxDiagnostics.recordGlobalEvent("GOLD_SIREN_REQUESTED","source=model_notification");
            battleService.soundManager.playSound(_loc4_.sound);
            GoldBoxDiagnostics.recordGlobalEvent("GOLD_SIREN_PLAY_CALL_RETURNED","source=model_notification");
         }
         var _loc5_:BattlefieldGUI = BattlefieldGUI(object.adapt(BattlefieldGUI));
         GoldBoxDiagnostics.recordGlobalEvent("GOLD_NOTIFICATION_SHOW_REQUESTED","source=model_notification reason=" + GoldBoxDiagnostics.sanitize(param3).replace(/\s+/g,"_"));
         _loc5_.showBattleMessage(MessageColor.ORANGE,param3);
         GoldBoxDiagnostics.recordGlobalEvent("GOLD_NOTIFICATION_SHOW_CALL_RETURNED","source=model_notification");
         this.noteRegionSource(param2,"model_notification","DROP_ZONE_MODEL_NOTIFICATION");
         bonusRegionService.addAndShowRegion(param2);
      }

      public function notificationProtanki(message:String, sound:SoundResource) : void
      {
         if(sound != null)
         {
            GoldBoxDiagnostics.recordGlobalEvent("GOLD_SIREN_REQUESTED","source=notification_packet");
            battleService.soundManager.playSound(sound.sound);
            GoldBoxDiagnostics.recordGlobalEvent("GOLD_SIREN_PLAY_CALL_RETURNED","source=notification_packet");
         }
         var _loc5_:BattlefieldGUI = BattlefieldGUI(object.adapt(BattlefieldGUI));
         GoldBoxDiagnostics.recordGlobalEvent("GOLD_NOTIFICATION_SHOW_REQUESTED","source=notification_packet reason=" + GoldBoxDiagnostics.sanitize(message).replace(/\s+/g,"_"));
         _loc5_.showBattleMessage(MessageColor.ORANGE,message);
         GoldBoxDiagnostics.recordGlobalEvent("GOLD_NOTIFICATION_SHOW_CALL_RETURNED","source=notification_packet");
      }

      private function noteRegionSource(param1:BonusRegionData, param2:String, param3:String) : void
      {
         var _loc4_:Vector3 = null;
         if(param1 != null && param1.position != null && param1.regionType == BonusesType.GOLD)
         {
            _loc4_ = BattleUtils.getVector3(param1.position);
            GoldBoxDiagnostics.noteDropZoneSource(_loc4_.toString(),param2,param1.regionType.name,_loc4_.x,_loc4_.y,_loc4_.z,param3);
         }
      }
      
      [Obfuscation(rename="false")]
      public function hideDropZone(param1:BonusRegionData) : void
      {
         bonusRegionService.hideAndRemoveRegion(param1);
      }
   }
}
