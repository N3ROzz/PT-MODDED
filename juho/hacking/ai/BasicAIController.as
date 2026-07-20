package juho.hacking.ai
{
   import alternativa.math.Vector3;
   import alternativa.tanks.battle.events.BattleEventDispatcher;
   import alternativa.tanks.battle.events.BattleEventListener;
   import alternativa.tanks.battle.events.TankAddedToBattleEvent;
   import alternativa.tanks.battle.events.TankRemovedFromBattleEvent;
   import alternativa.tanks.battle.objects.tank.ClientTankState;
   import alternativa.tanks.battle.objects.tank.Tank;
   import alternativa.tanks.battle.objects.tank.controllers.ChassisController;
   import alternativa.tanks.battle.objects.tank.controllers.LocalChassisController;
   import alternativa.tanks.models.battle.battlefield.keyboard.AbstractKeyboardHandler;
   import alternativa.tanks.models.tank.ITankModel;
   import alternativa.tanks.models.tank.TankModel;
   import flash.events.Event;
   import flash.utils.getTimer;
   import platform.client.fp10.core.type.IGameObject;
   
   public class BasicAIController implements BattleEventListener
   {
      
      private static const MAX_TARGET_DISTANCE:Number = 6000;
      
      private static const FIRE_RANGE:Number = 1400;
      
      private static const CHASE_STOP_DISTANCE:Number = 450;
      
      private static const CLOSE_FIRE_RANGE:Number = 650;
      
      private static const BODY_TURN_DEADZONE:Number = 0.12;
      
      private static const FIRE_TURRET_ANGLE:Number = 1.05;
      
      private static const STUCK_CHECK_INTERVAL:int = 1000;
      
      private static const STUCK_MIN_MOVE:Number = 40;
      
      private static const STUCK_REVERSE_TIME:int = 900;
      
      private static const tmpEyePosition:Vector3 = new Vector3();
      
      private var enabled:Boolean;
      
      private var localTank:Tank;
      
      private var target:Tank;
      
      private var tanks:Vector.<Tank> = new Vector.<Tank>();
      
      private var triggerPressed:Boolean;
      
      private var lastControlState:int;
      
      private var listenersActive:Boolean;
      
      private var frameActive:Boolean;
      
      private var lastStuckCheckTime:int;
      
      private var lastX:Number = 0;
      
      private var lastY:Number = 0;
      
      private var reverseUntil:int;
      
      private var reverseTurnLeft:Boolean;
      
      public function BasicAIController()
      {
         super();
      }
      
      public function startTracking() : void
      {
         this.addBattleListeners();
         this.refreshTanksFromRegistry();
      }
      
      public function setEnabled(value:Boolean) : void
      {
         if(this.enabled == value)
         {
            return;
         }
         this.enabled = value;
         if(value)
         {
            this.activate();
         }
         else
         {
            this.deactivate();
         }
      }
      
      public function setLocalTank(tank:Tank) : void
      {
         this.addBattleListeners();
         this.assignLocalTank(tank);
         this.resetStuckState();
         if(this.enabled)
         {
            this.addFrameListener();
         }
      }
      
      public function clearLocalTank(tank:Tank = null) : void
      {
         if(tank == null || tank == this.localTank)
         {
            this.releaseControls();
            this.localTank = null;
            this.target = null;
         }
      }
      
      public function handleBattleEvent(event:Object) : void
      {
         if(event is TankAddedToBattleEvent)
         {
            this.onTankAdded(TankAddedToBattleEvent(event));
         }
         else if(event is TankRemovedFromBattleEvent)
         {
            this.onTankRemoved(TankRemovedFromBattleEvent(event));
         }
      }
      
      private function activate() : void
      {
         this.addBattleListeners();
         this.refreshTanksFromRegistry();
         this.addFrameListener();
      }
      
      private function deactivate() : void
      {
         this.releaseControls();
         this.removeFrameListener();
         this.target = null;
      }
      
      private function addBattleListeners() : void
      {
         var dispatcher:BattleEventDispatcher = LocalChassisController.battleEventDispatcher;
         if(this.listenersActive || dispatcher == null)
         {
            return;
         }
         dispatcher.addBattleEventListener(TankAddedToBattleEvent,this);
         dispatcher.addBattleEventListener(TankRemovedFromBattleEvent,this);
         this.listenersActive = true;
      }
      
      private function addFrameListener() : void
      {
         if(this.frameActive || LocalChassisController.display == null || LocalChassisController.display.stage == null)
         {
            return;
         }
         LocalChassisController.display.stage.addEventListener(Event.ENTER_FRAME,this.onEnterFrame);
         this.frameActive = true;
      }
      
      private function removeFrameListener() : void
      {
         if(!this.frameActive || LocalChassisController.display == null || LocalChassisController.display.stage == null)
         {
            return;
         }
         LocalChassisController.display.stage.removeEventListener(Event.ENTER_FRAME,this.onEnterFrame);
         this.frameActive = false;
      }
      
      private function onTankAdded(event:TankAddedToBattleEvent) : void
      {
         this.addTank(event.tank);
         if(event.isLocal)
         {
            this.setLocalTank(event.tank);
         }
      }
      
      private function onTankRemoved(event:TankRemovedFromBattleEvent) : void
      {
         var index:int = this.tanks.indexOf(event.tank);
         if(index >= 0)
         {
            this.tanks.splice(index,1);
         }
         if(event.tank == this.target)
         {
            this.target = null;
            this.setFire(false);
         }
         this.clearLocalTank(event.tank);
      }
      
      private function addTank(tank:Tank) : void
      {
         if(tank != null && this.tanks.indexOf(tank) < 0)
         {
            this.tanks.push(tank);
         }
      }
      
      private function refreshTanksFromRegistry() : void
      {
         var users:Vector.<IGameObject> = null;
         var user:IGameObject = null;
         var model:ITankModel = null;
         var tank:Tank = null;
         if(TankModel.tankUsersRegistry == null)
         {
            return;
         }
         users = TankModel.tankUsersRegistry.getUsers();
         for each(user in users)
         {
            model = ITankModel(user.adapt(ITankModel));
            if(model != null)
            {
               tank = model.getTank();
               this.addTank(tank);
               if(model.isLocal())
               {
                  this.assignLocalTank(tank);
               }
            }
         }
      }
      
      private function assignLocalTank(tank:Tank) : void
      {
         this.localTank = tank;
         this.addTank(tank);
      }
      
      private function onEnterFrame(event:Event) : void
      {
         this.addBattleListeners();
         this.refreshTanksFromRegistry();
         if(!this.canRun())
         {
            this.releaseControls();
            return;
         }
         this.target = this.findTarget();
         if(this.target == null)
         {
            this.releaseControls();
            return;
         }
         this.runFirebirdChase(this.target);
      }
      
      private function canRun() : Boolean
      {
         return this.enabled && this.localTank != null && this.localTank.isInBattle() && this.localTank.health > 0 && this.localTank.state == ClientTankState.ACTIVE && this.localTank.isFirebirdWeaponForBasicAI() && !this.isInputLocked();
      }
      
      private function isInputLocked() : Boolean
      {
         return AbstractKeyboardHandler.battleInputService != null && AbstractKeyboardHandler.battleInputService.isInputLocked();
      }
      
      private function findTarget() : Tank
      {
         var tank:Tank = null;
         var bestTank:Tank = null;
         var distanceSq:Number = NaN;
         var bestDistanceSq:Number = Number.MAX_VALUE;
         for each(tank in this.tanks)
         {
            if(this.isValidTarget(tank))
            {
               distanceSq = this.distanceSquared(this.localTank,tank);
               if(distanceSq < bestDistanceSq)
               {
                  bestDistanceSq = distanceSq;
                  bestTank = tank;
               }
            }
         }
         return bestTank;
      }
      
      private function isValidTarget(tank:Tank) : Boolean
      {
         if(tank == null || tank == this.localTank || !tank.isInBattle() || tank.health <= 0 || tank.state != ClientTankState.ACTIVE)
         {
            return false;
         }
         if(this.localTank.isSameTeam(tank.teamType))
         {
            return false;
         }
         if(this.distanceSquared(this.localTank,tank) > MAX_TARGET_DISTANCE * MAX_TARGET_DISTANCE)
         {
            return false;
         }
         return this.isVisible(tank);
      }
      
      private function isVisible(tank:Tank) : Boolean
      {
         tmpEyePosition.copy(this.localTank.getBody().state.position);
         tmpEyePosition.z += 80;
         return !tank.isInvisible(tmpEyePosition);
      }
      
      private function runFirebirdChase(enemy:Tank) : void
      {
         var localPosition:Vector3 = this.localTank.getBody().state.position;
         var enemyPosition:Vector3 = enemy.getBody().state.position;
         var dx:Number = enemyPosition.x - localPosition.x;
         var dy:Number = enemyPosition.y - localPosition.y;
         var distance:Number = Math.sqrt(dx * dx + dy * dy);
         var targetWorldAngle:Number = Math.atan2(-dx,dy);
         var bodyDiff:Number = this.angleDiff(targetWorldAngle,this.localTank.getTankDirection());
         var targetTurretAngle:Number = this.normalizeAngle(targetWorldAngle - this.localTank.getTankDirection());
         var turretDiff:Number = NaN;
         
         this.localTank.turretController.setTargetDirection(targetTurretAngle);
         this.applyMovement(bodyDiff,distance);
         
         turretDiff = this.angleDiff(targetTurretAngle,this.localTank.turretController.getDirection());
         this.setFire(distance <= FIRE_RANGE);
      }
      
      private function applyMovement(bodyDiff:Number, distance:Number) : void
      {
         var now:int = getTimer();
         var control:int = 0;
         if(now < this.reverseUntil)
         {
            control = this.setBit(control,ChassisController.BIT_BACK,true);
            control = this.setBit(control,this.reverseTurnLeft ? ChassisController.BIT_LEFT : ChassisController.BIT_RIGHT,true);
         }
         else
         {
            if(distance > CHASE_STOP_DISTANCE)
            {
               control = this.setBit(control,ChassisController.BIT_FORWARD,true);
            }
            if(Math.abs(bodyDiff) > BODY_TURN_DEADZONE)
            {
               control = this.setBit(control,bodyDiff > 0 ? ChassisController.BIT_LEFT : ChassisController.BIT_RIGHT,true);
            }
         }
         this.setChassisControl(control);
         this.updateStuckState(now,control,bodyDiff,distance);
      }
      
      private function updateStuckState(now:int, control:int, bodyDiff:Number, distance:Number) : void
      {
         var position:Vector3 = null;
         var moved:Number = NaN;
         if(this.lastStuckCheckTime == 0)
         {
            this.resetStuckState();
            return;
         }
         if(now - this.lastStuckCheckTime < STUCK_CHECK_INTERVAL)
         {
            return;
         }
         position = this.localTank.getBody().state.position;
         moved = Math.sqrt((position.x - this.lastX) * (position.x - this.lastX) + (position.y - this.lastY) * (position.y - this.lastY));
         if((control & (1 << ChassisController.BIT_FORWARD)) != 0 && distance > CHASE_STOP_DISTANCE && moved < STUCK_MIN_MOVE)
         {
            this.reverseUntil = now + STUCK_REVERSE_TIME;
            this.reverseTurnLeft = bodyDiff <= 0;
         }
         this.lastStuckCheckTime = now;
         this.lastX = position.x;
         this.lastY = position.y;
      }
      
      private function resetStuckState() : void
      {
         var position:Vector3 = null;
         this.lastStuckCheckTime = getTimer();
         if(this.localTank != null)
         {
            position = this.localTank.getBody().state.position;
            this.lastX = position.x;
            this.lastY = position.y;
         }
         this.reverseUntil = 0;
      }
      
      private function setChassisControl(control:int) : void
      {
         var model:ITankModel = null;
         var chassis:ChassisController = null;
         if(control == this.lastControlState || this.localTank == null)
         {
            return;
         }
         model = ITankModel(this.localTank.getUser().adapt(ITankModel));
         chassis = model.getChassisController();
         chassis.setControlState(control);
         this.lastControlState = control;
      }
      
      private function setFire(pressed:Boolean) : void
      {
         if(this.localTank == null)
         {
            return;
         }
         if(pressed)
         {
            this.localTank.pullTriggerForBasicAI();
         }
         else if(this.triggerPressed)
         {
            this.localTank.releaseTriggerForBasicAI();
         }
         this.triggerPressed = pressed;
      }
      
      private function releaseControls() : void
      {
         if(this.localTank != null)
         {
            this.setChassisControl(0);
            this.localTank.turretController.setControlState(0);
         }
         this.setFire(false);
         this.lastControlState = 0;
      }
      
      private function setBit(value:int, bit:int, enabled:Boolean) : int
      {
         if(enabled)
         {
            return value | (1 << bit);
         }
         return value & ~(1 << bit);
      }
      
      private function distanceSquared(a:Tank, b:Tank) : Number
      {
         var pa:Vector3 = a.getBody().state.position;
         var pb:Vector3 = b.getBody().state.position;
         var dx:Number = pb.x - pa.x;
         var dy:Number = pb.y - pa.y;
         return dx * dx + dy * dy;
      }
      
      private function angleDiff(a:Number, b:Number) : Number
      {
         return Math.atan2(Math.sin(a - b),Math.cos(a - b));
      }
      
      private function normalizeAngle(value:Number) : Number
      {
         return Math.atan2(Math.sin(value),Math.cos(value));
      }
   }
}
