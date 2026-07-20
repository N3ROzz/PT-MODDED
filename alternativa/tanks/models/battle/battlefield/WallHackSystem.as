
package alternativa.tanks.models.battle.battlefield
{
   import alternativa.tanks.battle.BattleService;
   import alternativa.tanks.battle.events.BattleEventDispatcher;
   import alternativa.tanks.battle.events.BattleEventSupport;
   import alternativa.tanks.battle.events.TankAddedToBattleEvent;
   import alternativa.tanks.battle.events.TankRemovedFromBattleEvent;
   import alternativa.tanks.battle.objects.tank.Tank;
   import alternativa.tanks.display.usertitle.TitleConfigFlags;
   import alternativa.tanks.models.tank.LocalTankInfoService;
   import alternativa.tanks.models.tank.bosstate.IBossState;
   import alternativa.types.Long;
   import flash.utils.Dictionary;
   import platform.client.fp10.core.model.ObjectLoadPostListener;
   import platform.client.fp10.core.model.ObjectUnloadListener;
   import platform.client.fp10.core.type.IGameObject;
   import projects.tanks.client.battlefield.models.ultimate.effects.hornet.radar.BattleUltimateRadarCC;
   import projects.tanks.client.battlefield.models.user.bossstate.BossRelationRole;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.battle.IBattleInfoService;
   import alternativa.tanks.models.tank.ultimate.hornet.radar.BattleRadarHudIndicators;
   import flash.utils.getTimer;
   import utils.TankTraceUtil;
   
   [ModelInfo]
   public class WallHackSystem
   {
      [Inject]
      public static var battleService:BattleService;
      
      [Inject]
      public static var battleEventDispatcher:BattleEventDispatcher;
      
      [Inject]
      public static var battleInfoService:IBattleInfoService;
      
      [Inject]
      public static var localTankInfoService:LocalTankInfoService;
      
      private var battleRadarHudIndicators:BattleRadarHudIndicators;
      private var battleEventSupport:BattleEventSupport;
      private var tanksInBattle:Dictionary = new Dictionary();
      private var isLoaded:Boolean = false;
      public static var isEnabled:Boolean = false;
      public static var showNickname:Boolean = true;
      public static var visualMode:String = "MARKERS";
      public static const MODE_MARKERS:String = "MARKERS";
      
      public function WallHackSystem()
      {
         super();
      }

      private function initEventSupport() : void
      {
         if(this.battleEventSupport != null || battleEventDispatcher == null)
         {
            return;
         }
         this.battleEventSupport = new BattleEventSupport(battleEventDispatcher);
         this.battleEventSupport.addEventHandler(TankAddedToBattleEvent,this.onTankAddedToBattle);
         this.battleEventSupport.addEventHandler(TankRemovedFromBattleEvent,this.onTankRemovedFromBattle);
      }

      public static function shouldRevealTank(param1:Tank, param2:Tank) : Boolean
      {
         if(param1 == null)
         {
            return true;
         }
         if(param2 == param1)
         {
            return false;
         }
         if(param2.teamType == null || param1.teamType == null)
         {
            return true;
         }
         if(param2.teamType.name == "NONE" || param1.teamType.name == "NONE")
         {
            return true;
         }
         return !param1.isSameTeam(param2.teamType);
      }
      
      private function onTankAddedToBattle(param1:TankAddedToBattleEvent) : void
      {
         var _loc2_:Tank = param1.tank;
         var _loc3_:Long = _loc2_.getUser().id;
         this.tanksInBattle[_loc3_] = _loc2_;
         TankTraceUtil.log("[WallHackSystem:onAdded] key=" + _loc3_ + " " + TankTraceUtil.tankInfo(_loc2_));
         if(this.isDiscovered(_loc3_))
         {
            this.revealTank(_loc2_);
         }
      }
      
      private function isDiscovered(param1:Long) : Boolean
      {
         return true;
      }
      
      private function onTankRemovedFromBattle(param1:TankRemovedFromBattleEvent) : void
      {
         var _loc2_:Tank = param1.tank;
         var _loc3_:Long = _loc2_.getUser().id;
         delete this.tanksInBattle[_loc3_];
         TankTraceUtil.log("[WallHackSystem:onRemoved] key=" + _loc3_ + " " + TankTraceUtil.tankInfo(_loc2_));
         if(this.isDiscovered(_loc3_))
         {
            this.concealTank(_loc2_);
         }
      }
      
      public function load() : void
      {
         var _loc1_:BattleUltimateRadarCC = null;
         if(this.isLoaded)
         {
            return;
         }
         this.initEventSupport();
         _loc1_ = new BattleUltimateRadarCC(null, 1000000, 500);
         this.battleRadarHudIndicators = new BattleRadarHudIndicators(_loc1_);
         battleService.getBattleScene3D().addRenderer(this.battleRadarHudIndicators);
         if(this.battleEventSupport != null)
         {
            this.battleEventSupport.activateHandlers();
         }
         this.isLoaded = true;
         TankTraceUtil.log("[WallHackSystem:load] enabled=" + isEnabled + " nick=" + showNickname + " mode=" + visualMode);
      }

      public function unload() : void
      {
         if(this.battleEventSupport != null)
         {
            this.battleEventSupport.deactivateHandlers();
         }
         if(this.battleRadarHudIndicators != null && battleService != null && battleService.getBattleScene3D() != null)
         {
            battleService.getBattleScene3D().removeRenderer(this.battleRadarHudIndicators);
         }
         this.battleRadarHudIndicators = null;
         this.tanksInBattle = new Dictionary();
         this.isLoaded = false;
         TankTraceUtil.log("[WallHackSystem:unload]");
      }
      
      public function concealTanks() : void
      {
         if(!this.isLoaded)
            return;

         for each(var tank:Tank in tanksInBattle)
         {
            if(tank != null)
            {
               this.concealTank(tank);
            }
         }
      }
      
      public function revealTanks() : void
      {
         if(!this.isLoaded)
            return;

         TankTraceUtil.log("[WallHackSystem] revealTanks enabled=" + isEnabled + " nick=" + showNickname + " mode=" + visualMode);
         for each(var tank:Tank in tanksInBattle)
         {
            if(tank != null)
            {
               this.revealTank(tank);
            }
         }
      }
      
      private function revealTank(param1:Tank) : void
      {
         var _loc2_:Tank = null;
         if(isLoaded && isEnabled)
         {
            if(visualMode != MODE_MARKERS)
            {
               this.battleRadarHudIndicators.removeTankMarker(param1);
               return;
            }
            if(localTankInfoService != null && localTankInfoService.isLocalTankLoaded())
            {
               _loc2_ = localTankInfoService.getLocalTank();
               if(!shouldRevealTank(_loc2_,param1))
               {
                  this.battleRadarHudIndicators.removeTankMarker(param1);
                  return;
               }
            }
            this.battleRadarHudIndicators.addTankMarker(param1);
         }
      }
      
      private function concealTank(param1:Tank) : void
      {
         if(isLoaded)
         {
            this.battleRadarHudIndicators.removeTankMarker(param1);
         }
      }
   }
}
