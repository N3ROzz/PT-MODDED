package alternativa.tanks.models.bonus.battlefield
{
   import alternativa.math.Vector3;
   import alternativa.osgi.OSGi;
   import alternativa.tanks.battle.events.BattleEventDispatcher;
   import alternativa.tanks.battle.events.BattleEventListener;
   import alternativa.tanks.battle.events.BattleFinishEvent;
   import alternativa.tanks.battle.events.BattleRestartEvent;
   import alternativa.tanks.battle.events.StateCorrectionEvent;
   import alternativa.tanks.battle.BattleService;
   import alternativa.tanks.battle.objects.tank.ClientTankState;
   import alternativa.tanks.bonuses.BattleBonus;
   import alternativa.tanks.bonuses.Bonus;
   import alternativa.tanks.models.battle.battlefield.BattleUserInfoService;
   import alternativa.tanks.models.battle.battlefield.BattlefieldEvents;
   import alternativa.tanks.models.battle.battlefield.BattleUnloadEvent;
   import alternativa.tanks.models.effects.common.IBonusCommonModel;
   import alternativa.tanks.models.tank.LocalTankInfoService;
   import alternativa.tanks.service.money.IMoneyService;
   import flash.utils.Dictionary;
   import platform.client.fp10.core.type.IGameObject;
   import projects.tanks.client.battlefield.models.bonus.battle.BonusSpawnData;
   import projects.tanks.client.battlefield.models.bonus.battle.battlefield.BattlefieldBonusesModelBase;
   import projects.tanks.client.battlefield.models.bonus.battle.battlefield.IBattlefieldBonusesModelBase;
   import projects.tanks.client.battlefield.types.Vector3d;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.userproperties.IUserPropertiesService;
   import scpacker.utils.LongUtils;
   import alternativa.types.Long;
   import utils.goldbox.GoldBoxDiagnostics;
   
   [ModelInfo]
   public class BattlefieldBonusesModel extends BattlefieldBonusesModelBase implements IBattlefieldBonusesModelBase, BattleEventListener, BattlefieldEvents
   {
      
      [Inject] // added
      public static var battleEventDispatcher:BattleEventDispatcher;
      
      [Inject] // added
      public static var userInfoService:BattleUserInfoService;
      
      [Inject] // added
      public static var userPropertiesService:IUserPropertiesService;

      private static var localAttemptBonusId:Long;

      private static var localBonusTaken:Boolean = false;
      
      private static var localAttemptBonusType:String;
      
      private var bonuses:Dictionary = new Dictionary();
      
      private var bonusTypes:Dictionary = new Dictionary();

      private var proximityBonusIdsByCanonical:Dictionary = new Dictionary();

      private var proximityAttemptedBonusIds:Dictionary = new Dictionary();

      private var battleActive:Boolean;

      private var lifecycleListenersRegistered:Boolean;
      
      public function BattlefieldBonusesModel()
      {
         super();
         this.registerLifecycleListeners();
         this.registerProximityBridge();
      }
      
      public function handleBattleEvent(param1:Object) : void
      {
         if(param1 is BattleRestartEvent)
         {
            this.battleActive = true;
            this.registerProximityBridge();
            return;
         }
         this.battleActive = false;
         this.removeAllBonuses();
         this.proximityBonusIdsByCanonical = new Dictionary();
         this.proximityAttemptedBonusIds = new Dictionary();
         localAttemptBonusId = null;
         localAttemptBonusType = null;
         if(param1 is BattleUnloadEvent)
         {
            GoldBoxDiagnostics.unregisterProximityBridge();
            this.unregisterLifecycleListeners();
         }
      }
      
      private function removeAllBonuses() : void
      {
         var _loc1_:* = undefined;
         for(_loc1_ in this.bonuses)
         {
            this.removeBonus(_loc1_);
         }
      }
      
      private function spawnBonus(param1:IGameObject, param2:Long, param3:Vector3d, param4:int, param5:Boolean) : void
      {
         var _loc6_:IBonusCommonModel = null;
         var _loc7_:Bonus = null;
         var _loc8_:String = GoldBoxDiagnostics.recordModelSpawnEntry(param2,param1 == null ? null : param1.name,param3 == null ? NaN : param3.x,param3 == null ? NaN : param3.y,param3 == null ? NaN : param3.z,param4,param5);
         if(param1 != null)
         {
            _loc6_ = IBonusCommonModel(param1.adapt(IBonusCommonModel));
            _loc7_ = _loc6_.getBonus(param2);
            GoldBoxDiagnostics.lifecycle(_loc8_,"BONUS_OBJECT_CREATED","CREATED");
            _loc7_.spawn(new Vector3(param3.x,param3.y,param3.z),param4,getInitParam().bonusFallSpeed,param5,getFunctionWrapper(this.onBonusTankCollision));
            this.bonuses[_loc7_.bonusId] = _loc7_;
            this.bonusTypes[_loc7_.bonusId] = param1.name;
            this.proximityBonusIdsByCanonical[_loc8_] = param2;
            GoldBoxDiagnostics.setModelExists(_loc8_,true,"MODEL_REGISTERED");
         }
         else
         {
            GoldBoxDiagnostics.recordGlobalEvent("MODEL_SPAWN_EXIT","bonusId=" + GoldBoxDiagnostics.sanitize(_loc8_) + " reason=bonus_object_unresolved");
         }
      }

      public function hasBonusForDiagnostics(param1:Long) : Boolean
      {
         return param1 != null && this.bonuses[param1] != null;
      }
      
      private function onBonusTankCollision(param1:Bonus) : void
      {
         var _loc2_:String = GoldBoxDiagnostics.canonicalFromLong(param1.bonusId);
         GoldBoxDiagnostics.lifecycle(_loc2_,"LOCAL_TANK_COLLISION","COLLISION");
         GoldBoxDiagnostics.setModelExists(_loc2_,this.bonuses[param1.bonusId] != null,"MODEL_EXISTENCE_AT_COLLISION");
         GoldBoxDiagnostics.lifecycle(_loc2_,"MANDATORY_UPDATE_DISPATCH_BEGIN");
         battleEventDispatcher.dispatchEvent(StateCorrectionEvent.MANDATORY_UPDATE);
         GoldBoxDiagnostics.lifecycle(_loc2_,"MANDATORY_UPDATE_DISPATCH_COMPLETE");
         if(this.proximityAttemptedBonusIds[_loc2_])
         {
            localAttemptBonusId = null;
            localAttemptBonusType = null;
         }
         else
         {
            localAttemptBonusId = param1.bonusId;
            localAttemptBonusType = this.bonusTypes[param1.bonusId];
         }
         server.attemptToTakeBonus(param1.bonusId);
      }

      public static function consumeLocalBonusTaken() : Boolean
      {
         if(localBonusTaken)
         {
            localBonusTaken = false;
            return true;
         }
         if(localAttemptBonusId != null)
         {
            localAttemptBonusId = null;
            return true;
         }
         return false;
      }
      
      [Obfuscation(rename="false")]
      public function spawnBonuses(param1:Vector.<BonusSpawnData>) : void
      {
         var _loc2_:BonusSpawnData = null;
         if(param1 != null)
         {
            for each(_loc2_ in param1)
            {
               this.spawnBonus(_loc2_.battleBonusObject,_loc2_.bonusId,_loc2_.spawnPosition,0,false);
            }
         }
      }

      public function initBonuses(param1:Vector.<BonusSpawnData>) : void
      {
         var _loc2_:BonusSpawnData = null;
         if(param1 != null)
         {
            for each(_loc2_ in param1)
            {
               this.spawnBonus(_loc2_.battleBonusObject,_loc2_.bonusId,_loc2_.spawnPosition,_loc2_.lifeTime,false);
            }
         }
      }
      
      [Obfuscation(rename="false")]
      public function removeBonuses(param1:Vector.<Long>) : void
      {
         var _loc2_:Long = null;
         if(param1 != null)
         {
            for each(_loc2_ in param1)
            {
               this.removeBonus(_loc2_);
            }
         }
      }
      
      private function removeBonus(param1:Long) : void
      {
         var _loc2_:Bonus = this.bonuses[param1];
         var _loc3_:String = GoldBoxDiagnostics.canonicalFromLong(param1);
         if(_loc2_ != null)
         {
         GoldBoxDiagnostics.setModelExists(GoldBoxDiagnostics.canonicalFromLong(param1),true,"MODEL_REMOVE_BEGIN");
            delete this.bonuses[param1];
            delete this.bonusTypes[param1];
         GoldBoxDiagnostics.setModelExists(GoldBoxDiagnostics.canonicalFromLong(param1),false,"MODEL_REMOVED");
            _loc2_.remove();
         }
         delete this.proximityBonusIdsByCanonical[_loc3_];
         delete this.proximityAttemptedBonusIds[_loc3_];
      }
      
      [Obfuscation(rename="false")]
      public function bonusTaken(param1:Long) : void
      {
         var _loc2_:Bonus = this.bonuses[param1];
         var _loc3_:String = GoldBoxDiagnostics.canonicalFromLong(param1);
         var _loc4_:Boolean = Boolean(this.proximityAttemptedBonusIds[_loc3_]);
         if(_loc2_ != null)
         {
         GoldBoxDiagnostics.setModelExists(GoldBoxDiagnostics.canonicalFromLong(param1),true,"MODEL_PICKUP_BEGIN");
            delete this.bonuses[param1];
            delete this.bonusTypes[param1];
         GoldBoxDiagnostics.setModelExists(GoldBoxDiagnostics.canonicalFromLong(param1),false,"MODEL_REMOVED_FOR_PICKUP");
            if(localAttemptBonusId == param1 && !_loc4_)
            {
               this.addLocalBonusCrystals(localAttemptBonusType);
               localAttemptBonusId = null;
               localAttemptBonusType = null;
            }
            else if(_loc4_ && localAttemptBonusId == param1)
            {
               localAttemptBonusId = null;
               localAttemptBonusType = null;
            }
            _loc2_.pickup();
         }
         delete this.proximityBonusIdsByCanonical[_loc3_];
         delete this.proximityAttemptedBonusIds[_loc3_];
      }
      
      private function addLocalBonusCrystals(param1:String) : void
      {
         var _loc3_:IMoneyService = null;
         var _loc2_:int = this.getBonusCrystalAmount(param1);
         if(_loc2_ <= 0)
         {
            localBonusTaken = true;
            return;
         }
         _loc3_ = IMoneyService(OSGi.getInstance().getService(IMoneyService));
         if(_loc3_ != null)
         {
            _loc3_.setServerCrystals(_loc3_.crystal + _loc2_);
         }
      }
      
      private function getBonusCrystalAmount(param1:String) : int
      {
         if(param1 == null)
         {
            return 0;
         }
         param1 = param1.toLowerCase();
         if(param1.indexOf("gold") >= 0)
         {
            return 1000;
         }
         if(param1.indexOf("crystal") >= 0)
         {
            return 10;
         }
         return 0;
      }
      
      [Obfuscation(rename="false")]
      public function attemptToTakeBonusFailedTankNotActive(param1:Long) : void
      {
         var _loc2_:Bonus = this.bonuses[param1];
         GoldBoxDiagnostics.collectionFailed(GoldBoxDiagnostics.canonicalFromLong(param1));
         if(localAttemptBonusId == param1)
         {
            localAttemptBonusId = null;
            localAttemptBonusType = null;
         }
         if(_loc2_ != null)
         {
         GoldBoxDiagnostics.lifecycle(GoldBoxDiagnostics.canonicalFromLong(param1),"TRIGGER_RE_ENABLE_REQUEST");
            _loc2_.enableTrigger();
         }
      }
      
      public function onBattleLoaded() : void
      {
         this.battleActive = true;
         this.registerLifecycleListeners();
         this.registerProximityBridge();
         this.createExistingBonuses();
      }

      private function registerLifecycleListeners() : void
      {
         if(this.lifecycleListenersRegistered)
         {
            return;
         }
         battleEventDispatcher.addBattleEventListener(BattleFinishEvent,this);
         battleEventDispatcher.addBattleEventListener(BattleRestartEvent,this);
         battleEventDispatcher.addBattleEventListener(BattleUnloadEvent,this);
         this.lifecycleListenersRegistered = true;
      }

      private function unregisterLifecycleListeners() : void
      {
         if(!this.lifecycleListenersRegistered)
         {
            return;
         }
         battleEventDispatcher.removeBattleEventListener(BattleFinishEvent,this);
         battleEventDispatcher.removeBattleEventListener(BattleRestartEvent,this);
         battleEventDispatcher.removeBattleEventListener(BattleUnloadEvent,this);
         this.lifecycleListenersRegistered = false;
      }

      private function registerProximityBridge() : void
      {
         GoldBoxDiagnostics.registerProximityBridge(this.readBonusPositionForProximity,this.requestProximityCollect,this.getProximityRuntimeStatus);
      }

      private function getProximityRuntimeStatus() : Object
      {
         return {modelBattleActive:this.battleActive};
      }

      private function readBonusPositionForProximity(param1:String, param2:Vector3) : Object
      {
         var _loc3_:Long = this.proximityBonusIdsByCanonical[param1];
         var _loc4_:Bonus = _loc3_ == null ? null : this.bonuses[_loc3_];
         var _loc5_:BattleBonus = _loc4_ as BattleBonus;
         if(_loc5_ == null || _loc5_.getBonusMesh() == null || param2 == null)
         {
            return {ok:false,reason:"missing_model_bonus"};
         }
         _loc5_.getBonusMesh().readPosition(param2);
         if(!this.isFinitePosition(param2))
         {
            return {ok:false,reason:"invalid_position"};
         }
         return {ok:true,source:"model_current"};
      }

      private function requestProximityCollect(param1:String, param2:int) : Object
      {
         var _loc3_:Long = this.proximityBonusIdsByCanonical[param1];
         var _loc4_:Bonus = _loc3_ == null ? null : this.bonuses[_loc3_];
         var _loc5_:Vector3 = new Vector3();
         var _loc6_:Object = null;
         var _loc7_:BattleService = OSGi.getInstance().getService(BattleService) as BattleService;
         var _loc8_:LocalTankInfoService = OSGi.getInstance().getService(LocalTankInfoService) as LocalTankInfoService;
         if(!this.battleActive || _loc7_ == null || !_loc7_.isBattleActive())
         {
            return {ok:false,reason:"battle_inactive"};
         }
         if(_loc3_ == null)
         {
            return {ok:false,reason:"missing_long_mapping"};
         }
         if(_loc4_ == null)
         {
            return {ok:false,reason:"missing_model_bonus"};
         }
         if(this.bonusTypes[_loc3_] !== "crystal")
         {
            return {ok:false,reason:"wrong_bonus_type"};
         }
         _loc6_ = this.readBonusPositionForProximity(param1,_loc5_);
         if(_loc6_ == null || !Boolean(_loc6_.ok))
         {
            return {ok:false,reason:"invalid_position"};
         }
         if(_loc8_ == null || !_loc8_.isLocalTankLoaded() || _loc8_.getLocalTank() == null || _loc8_.getLocalTank().state != ClientTankState.ACTIVE)
         {
            return {ok:false,reason:"tank_inactive"};
         }
         battleEventDispatcher.dispatchEvent(StateCorrectionEvent.MANDATORY_UPDATE);
         GoldBoxDiagnostics.beginProximitySendContext(param1,param2);
         this.proximityAttemptedBonusIds[param1] = true;
         try
         {
            server.attemptToTakeBonus(_loc3_);
         }
         finally
         {
            GoldBoxDiagnostics.endProximitySendContext(param1);
         }
         return {ok:true,packetBonusId:LongUtils.idToStr(_loc3_)};
      }

      private function isFinitePosition(param1:Vector3) : Boolean
      {
         return param1 != null && !isNaN(param1.x) && isFinite(param1.x) && !isNaN(param1.y) && isFinite(param1.y) && !isNaN(param1.z) && isFinite(param1.z);
      }
      
      private function createExistingBonuses() : void
      {
         var _loc1_:BonusSpawnData = null;
         for each(_loc1_ in getInitParam().bonuses)
         {
            this.spawnBonus(_loc1_.battleBonusObject,_loc1_.bonusId,_loc1_.spawnPosition,_loc1_.lifeTime,false);
         }
         getInitParam().bonuses = null;
      }
      
      [Obfuscation(rename="false")]
      public function spawnBonusesOnGround(param1:Vector.<BonusSpawnData>) : void
      {
         var _loc2_:BonusSpawnData = null;
         for each(_loc2_ in param1)
         {
            this.spawnBonus(_loc2_.battleBonusObject,_loc2_.bonusId,_loc2_.spawnPosition,0,true);
         }
      }
   }
}
