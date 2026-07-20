package alternativa.tanks.models.tank
{
   import alternativa.math.Vector3;
   import alternativa.physics.Body;
   import alternativa.physics.BodyState;
   import alternativa.tanks.battle.BattleService;
   import alternativa.tanks.battle.UserTitleRenderer;
   import alternativa.tanks.battle.events.BattleEventDispatcher;
   import alternativa.tanks.battle.events.BattleEventListener;
   import alternativa.tanks.battle.events.BattleEventSupport;
   import alternativa.tanks.battle.events.TankAddedToBattleEvent;
   import alternativa.tanks.battle.events.TankRemovedFromBattleEvent;
   import alternativa.tanks.battle.objects.tank.Tank;
   import alternativa.tanks.battle.scene3d.BattleScene3D;
   import alternativa.tanks.camera.GameCamera;
   import alternativa.tanks.display.usertitle.TitleConfigFlags;
   import alternativa.tanks.models.battle.battlefield.WallHackSystem;
   import alternativa.tanks.utils.EncryptedNumber;
   import alternativa.tanks.utils.EncryptedNumberImpl;
   import alternativa.utils.clearDictionary;
   import flash.utils.Dictionary;
   import flash.utils.getTimer;
   import platform.client.fp10.core.type.AutoClosable;
   import utils.TankTraceUtil;

   public class RegularUserTitleRenderer implements UserTitleRenderer, AutoClosable, BattleEventListener
   {

      [Inject] // added
      public static var battleEventDispatcher:BattleEventDispatcher;

      [Inject] // added
      public static var battleService:BattleService;

      private static const DISTANCE_TO_SHOW_TITLES:EncryptedNumber = new EncryptedNumberImpl(7000);

      private static const DISTANCE_TO_HIDE_TITLES:EncryptedNumber = new EncryptedNumberImpl(7050);

      private var localTank:Tank;

      private var battleEventSupport:BattleEventSupport;

      private const remoteTanksInBattle:Dictionary = new Dictionary();
      private const lastTraceTimeByTank:Dictionary = new Dictionary(true);
      private const lastTraceHealthByTank:Dictionary = new Dictionary(true);

      public function RegularUserTitleRenderer(param1:Tank, param2:Dictionary)
      {
         super();
         this.localTank = param1;
         TankTraceUtil.log("[RTR:ctor] local " + TankTraceUtil.tankInfo(param1));
         this.remoteTankAddToBattle(param2);
         this.battleEventSupport = new BattleEventSupport(battleEventDispatcher,this);
         this.battleEventSupport.addEventHandler(TankAddedToBattleEvent,this.onTankAddedToBattle);
         this.battleEventSupport.addEventHandler(TankRemovedFromBattleEvent,this.onTankRemovedFromBattle);
         this.battleEventSupport.activateHandlers();
      }

      private function remoteTankAddToBattle(param1:Dictionary) : void
      {
         var _loc2_:Tank = null;
         for each(_loc2_ in param1)
         {
            if(_loc2_ != this.localTank)
            {
               this.remoteTanksInBattle[_loc2_] = true;
               TankTraceUtil.log("[RTR:addInitial] " + TankTraceUtil.tankInfo(_loc2_) + " inRemote=" + (this.remoteTanksInBattle[_loc2_] == true));
            }
         }
      }

      private function onTankAddedToBattle(param1:TankAddedToBattleEvent) : void
      {
         if(param1.tank != this.localTank)
         {
            this.remoteTanksInBattle[param1.tank] = true;
            TankTraceUtil.log("[RTR:onAdded] " + TankTraceUtil.tankInfo(param1.tank) + " inRemote=" + (this.remoteTanksInBattle[param1.tank] == true));
         }
      }

      private function onTankRemovedFromBattle(param1:TankRemovedFromBattleEvent) : void
      {
         if(param1.tank != this.localTank)
         {
            TankTraceUtil.log("[RTR:onRemoved] beforeDelete " + TankTraceUtil.tankInfo(param1.tank) + " inRemote=" + (this.remoteTanksInBattle[param1.tank] == true));
            delete this.remoteTanksInBattle[param1.tank];
            TankTraceUtil.log("[RTR:onRemoved] afterDelete " + TankTraceUtil.tankId(param1.tank) + " inRemote=" + (this.remoteTanksInBattle[param1.tank] == true));
         }
      }

      public function handleBattleEvent(param1:Object) : void
      {
         this.battleEventSupport.handleBattleEvent(param1);
      }

      public function renderUserTitles() : void
      {
         var _loc4_:* = undefined;
         var _loc1_:BattleScene3D = battleService.getBattleScene3D();
         var _loc2_:GameCamera = _loc1_.getCamera();
         var _loc3_:Vector3 = _loc2_.position;
         for(_loc4_ in this.remoteTanksInBattle)
         {
            this.updateTitleVisibility(_loc4_,_loc3_);
         }
      }

      private function updateTitleVisibility(param1:Tank, param2:Vector3) : void
      {
         if(param1.health > 0)
         {
            if(this.localTank.isSameTeam(param1.teamType))
            {
               param1.showTitle();
            }
            else
            {
               this.updateTitleForEnemyTank(param1,param2);
            }
         }
         else
         {
            param1.hideTitle();
         }
      }

      private function updateTitleForEnemyTank(param1:Tank, param2:Vector3) : void
      {
         var _loc3_:Body = param1.getBody();
         var _loc4_:BodyState = _loc3_.state;
         var _loc5_:Vector3 = _loc4_.position;
         var _loc6_:Number = _loc5_.x - param2.x;
         var _loc7_:Number = _loc5_.y - param2.y;
         var _loc8_:Number = _loc5_.z - param2.z;
         var _loc9_:Number = Math.sqrt(_loc6_ * _loc6_ + _loc7_ * _loc7_ + _loc8_ * _loc8_);
         if(WallHackSystem.isEnabled && WallHackSystem.showNickname && WallHackSystem.shouldRevealTank(this.localTank,param1))
         {
            this.updateWallHackTitle(param1);
            return;
         }
         param1.setTitleDepthTest(true);
         param1.setTitleLabelText(param1.userId);
         param1.setTitleConfiguration(TitleConfigFlags.LABEL | TitleConfigFlags.EFFECTS);
         if(TankTraceUtil.ENABLED && this.shouldTraceTitle(param1))
         {
            TankTraceUtil.log("[RegularTitle] " + TankTraceUtil.tankInfo(param1) + " flags=" + (TitleConfigFlags.LABEL | TitleConfigFlags.EFFECTS) + " wallHack=" + WallHackSystem.isEnabled + " nick=" + WallHackSystem.showNickname + " mode=" + WallHackSystem.visualMode + " inRemote=" + (this.remoteTanksInBattle[param1] == true));
         }
         if(_loc9_ >= DISTANCE_TO_HIDE_TITLES.getNumber() || param1.isInvisible(param2))
         {
            param1.hideTitle();
         }
         else if(_loc9_ < DISTANCE_TO_SHOW_TITLES.getNumber())
         {
            param1.showTitle();
         }
      }
      
      private function updateWallHackTitle(param1:Tank) : void
      {
         var _loc2_:int = 0;
         if(WallHackSystem.showNickname)
         {
            _loc2_ |= TitleConfigFlags.LABEL | TitleConfigFlags.EFFECTS;
            param1.setTitleLabelText(this.getWallHackLabel(param1));
         }
         if(TankTraceUtil.ENABLED && this.shouldTraceTitle(param1))
         {
            TankTraceUtil.log("[WallHackRenderer] " + TankTraceUtil.tankInfo(param1) + " flags=" + _loc2_ + " wallHack=" + WallHackSystem.isEnabled + " nick=" + WallHackSystem.showNickname + " mode=" + WallHackSystem.visualMode + " inRemote=" + (this.remoteTanksInBattle[param1] == true));
         }
         if(_loc2_ == 0)
         {
            param1.hideTitle();
            return;
         }
         param1.setTitleConfiguration(_loc2_);
         param1.setTitleDepthTest(false);
         param1.showTitle();
      }

      private function getWallHackLabel(param1:Tank) : String
      {
         return param1.userId;
      }

      private function shouldTraceTitle(param1:Tank) : Boolean
      {
         var _loc2_:int = getTimer();
         var _loc3_:Object = this.lastTraceHealthByTank[param1];
         var _loc4_:Object = this.lastTraceTimeByTank[param1];
         if(_loc3_ == null || Number(_loc3_) != param1.health || _loc4_ == null || _loc2_ - int(_loc4_) >= 2000)
         {
            this.lastTraceHealthByTank[param1] = param1.health;
            this.lastTraceTimeByTank[param1] = _loc2_;
            return true;
         }
         return false;
      }

      [Obfuscation(rename="false")]
      public function close() : void
      {
         this.battleEventSupport.deactivateHandlers();
         this.battleEventSupport = null;
         this.localTank = null;
         clearDictionary(this.remoteTanksInBattle);
      }
   }
}
