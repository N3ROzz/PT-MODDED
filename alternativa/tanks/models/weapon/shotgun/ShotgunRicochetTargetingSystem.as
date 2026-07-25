package alternativa.tanks.models.weapon.shotgun
{
   import alternativa.math.Matrix3;
   import alternativa.math.Vector3;
   import alternativa.physics.Body;
   import alternativa.physics.collision.types.RayHit;
   import alternativa.tanks.battle.BattleService;
   import alternativa.tanks.battle.BattleUtils;
   import alternativa.tanks.battle.objects.tank.Tank;
   import alternativa.tanks.models.weapon.AllGlobalGunParams;
   import alternativa.tanks.models.weapon.RayCollisionFilter;
   import alternativa.tanks.models.weapon.WeaponObject;
   import alternativa.tanks.models.weapon.angles.verticals.autoaiming.VerticalAutoAiming;
   import alternativa.tanks.models.weapon.shared.CommonTargetEvaluator;
   import alternativa.tanks.physics.CollisionGroup;
   import alternativa.tanks.physics.TanksCollisionDetector;
   import projects.tanks.client.battlefield.models.tankparts.weapons.common.TargetPosition;
   import projects.tanks.client.battlefield.models.tankparts.weapons.shotgun.aiming.ShotGunAimingCC;
   
   public class ShotgunRicochetTargetingSystem
   {
      
      [Inject]
      public static var battleService:BattleService;
      
      private static const TARGET_DIAMETER:Number = 90;
      
      private static const CENTER_DIRECTION_PENALTY:Number = 0.001;
      
      private static const rayHit:RayHit = new RayHit();
      
      private static const direction:Vector3 = new Vector3();
      
      private static const rotationMatrix:Matrix3 = new Matrix3();
      
      private static const stepMatrix:Matrix3 = new Matrix3();
      
      private var candidateTargets:Vector.<TargetPosition>;
      
      private var bestTargets:Vector.<TargetPosition>;
      
      private var pelletDirectionGenerator:PelletDirectionCalculator;
      
      private var directionCount:int;
      
      private var collisionDetector:TanksCollisionDetector;
      
      private var targetEvaluator:CommonTargetEvaluator;
      
      private var collisionFilter:RayCollisionFilter;
      
      private var weaponObject:WeaponObject;
      
      public function ShotgunRicochetTargetingSystem(param1:WeaponObject, param2:PelletDirectionCalculator, param3:ShotGunAimingCC)
      {
         super();
         this.candidateTargets = new Vector.<TargetPosition>();
         this.bestTargets = new Vector.<TargetPosition>();
         this.collisionFilter = new RayCollisionFilter();
         this.pelletDirectionGenerator = param2;
         this.weaponObject = param1;
         this.directionCount = this.calculateDirectionCount(param1);
         this.collisionDetector = battleService.getBattleRunner().getCollisionDetector();
         this.targetEvaluator = battleService.getCommonTargetEvaluator();
      }
      
      public function getShotDirection(param1:AllGlobalGunParams, param2:Body, param3:Vector3) : Vector.<TargetPosition>
      {
         var _loc14_:Number = NaN;
         var _loc15_:Vector3 = null;
         var _loc16_:Body = null;
         var _loc17_:Tank = null;
         var _loc18_:TargetPosition = null;
         var _loc19_:Vector.<TargetPosition> = null;
         this.pelletDirectionGenerator.next();
         this.collisionFilter.exclusion = param2;
         var _loc4_:VerticalAutoAiming = this.weaponObject.verticalAutoAiming();
         var _loc5_:Number = _loc4_.getElevationAngleDown();
         var _loc6_:Number = _loc4_.getElevationAngleUp();
         var _loc7_:Number = this.weaponObject.distanceWeakening().getDistance();
         var _loc8_:Number = this.weaponObject.distanceWeakening().getFullDamageDistance();
         var _loc9_:Number = -_loc5_;
         var _loc10_:Number = (_loc5_ + _loc6_) / (this.directionCount - 1);
         var _loc11_:Number = Math.max(_loc5_,_loc6_);
         direction.copy(param1.direction);
         rotationMatrix.fromAxisAngle(param1.elevationAxis,-_loc5_);
         direction.transform3(rotationMatrix);
         stepMatrix.fromAxisAngle(param1.elevationAxis,_loc10_);
         var _loc12_:Number = -1;
         var _loc13_:int = 0;
         while(_loc13_ < this.directionCount)
         {
            this.candidateTargets.length = 0;
            _loc14_ = _loc11_ == 0 ? 0 : -Math.abs(_loc9_) / _loc11_ * CENTER_DIRECTION_PENALTY;
            for each(_loc15_ in this.pelletDirectionGenerator.getDirectionsFor(param1.elevationAxis,direction))
            {
               if(this.collisionDetector.raycast(param1.barrelOrigin,_loc15_,CollisionGroup.WEAPON,_loc7_,this.collisionFilter,rayHit))
               {
                  _loc16_ = rayHit.shape.body;
                  _loc17_ = _loc16_.tank;
                  if(_loc17_ != null)
                  {
                     _loc18_ = BattleUtils.getTargetPosition(_loc17_);
                     _loc18_.localHitPoint = BattleUtils.getVector3d(rayHit.position.clone());
                     this.candidateTargets.push(_loc18_);
                     _loc14_ += this.targetEvaluator.getTargetPriority(_loc16_,rayHit.t,_loc9_,_loc8_,_loc11_);
                  }
               }
            }
            if(_loc12_ < _loc14_)
            {
               _loc12_ = _loc14_;
               param3.copy(direction);
               _loc19_ = this.candidateTargets;
               this.candidateTargets = this.bestTargets;
               this.bestTargets = _loc19_;
            }
            if(_loc13_ + 1 < this.directionCount)
            {
               direction.transform3(stepMatrix);
               _loc9_ += _loc10_;
            }
            _loc13_++;
         }
         this.candidateTargets.length = 0;
         for each(_loc18_ in this.bestTargets)
         {
            this.candidateTargets.push(_loc18_);
         }
         this.bestTargets.length = 0;
         return this.candidateTargets;
      }
      
      private function calculateDirectionCount(param1:WeaponObject) : int
      {
         var _loc2_:VerticalAutoAiming = param1.verticalAutoAiming();
         var _loc3_:Number = param1.distanceWeakening().getFullDamageDistance();
         var _loc4_:Number = _loc2_.getElevationAngleDown() + _loc2_.getElevationAngleUp();
         return Math.ceil(_loc4_ / (2 * Math.atan(TARGET_DIAMETER / (2 * _loc3_)))) + 1;
      }
   }
}
