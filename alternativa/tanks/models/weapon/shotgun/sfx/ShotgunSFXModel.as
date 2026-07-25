package alternativa.tanks.models.weapon.shotgun.sfx
{
   import alternativa.math.Vector3;
   import alternativa.tanks.battle.BattleService;
   import alternativa.tanks.battle.objects.tank.Tank;
   import alternativa.tanks.models.sfx.lighting.LightingSfx;
   import alternativa.tanks.models.tank.ITankModel;
   import alternativa.tanks.models.weapon.AllGlobalGunParams;
   import alternativa.tanks.models.weapon.WeaponUtils;
   import alternativa.tanks.models.weapon.shotgun.ShotgunObject;
   import alternativa.tanks.models.weapons.discrete.DiscreteWeaponListener;
   import platform.client.fp10.core.model.ObjectLoadPostListener;
   import platform.client.fp10.core.type.IGameObject;
   import projects.tanks.client.battlefield.models.tankparts.weapons.common.discrete.TargetHit;
   import projects.tanks.client.battlefield.models.tankparts.weapons.shotgun.sfx.IShotgunSFXModelBase;
   import projects.tanks.client.battlefield.models.tankparts.weapons.shotgun.sfx.ShotgunSFXModelBase;
   import utils.HammerDiagnostics;
   
   [ModelInfo]
   public class ShotgunSFXModel extends ShotgunSFXModelBase implements IShotgunSFXModelBase, ShotgunSFX, ObjectLoadPostListener, DiscreteWeaponListener
   {
      
      [Inject] // added
      public static var battleService:BattleService;
      
      private var gunParams:AllGlobalGunParams = new AllGlobalGunParams();
      
      private var _shotgunObject:ShotgunObject;
      
      public function ShotgunSFXModel()
      {
         super();
      }
      
      [Obfuscation(rename="false")]
      public function objectLoadedPost() : void
      {
         var _loc1_:LightingSfx = new LightingSfx(getInitParam().lightingSFXEntity);
         var _loc2_:ShotgunSFXData = new ShotgunSFXData(getInitParam(),_loc1_.createAnimation("shot"));
         putData(ShotgunSFXData,_loc2_);
         var _loc3_:ShotgunEffects = new ShotgunEffects(_loc2_);
         putData(ShotgunEffects,_loc3_);
      }
      
      public function onShot(param1:IGameObject, param2:Vector3, param3:Vector.<TargetHit>) : void
      {
         if(HammerDiagnostics.ENABLED)
         {
            HammerDiagnostics.log("HAMMER_SFX_MODEL_BEGIN","shooter=" + (param1 == null ? "null" : param1.name));
         }
         this.showShotEffects(param1,param2);
         if(HammerDiagnostics.ENABLED)
         {
            HammerDiagnostics.log("HAMMER_SFX_MODEL_RETURNED");
         }
      }
      
      private function showShotEffects(param1:IGameObject, param2:Vector3) : void
      {
         var _loc4_:Tank = null;
         var _loc3_:ITankModel = ITankModel(param1.adapt(ITankModel));
         if(!_loc3_.isLocal())
         {
            this.calculateGunParams(param1);
            _loc4_ = _loc3_.getTank();
            if(HammerDiagnostics.ENABLED)
            {
               HammerDiagnostics.log("HAMMER_REMOTE_SFX_BEGIN");
            }
            this.getEffects().createShotEffects(this.weaponObject(),this.gunParams,_loc4_,param2);
            if(HammerDiagnostics.ENABLED)
            {
               HammerDiagnostics.log("HAMMER_REMOTE_SFX_RETURNED");
            }
         }
      }
      
      private function calculateGunParams(param1:IGameObject) : void
      {
         var _loc2_:ITankModel = ITankModel(param1.adapt(ITankModel));
         var _loc3_:Tank = _loc2_.getTank();
         WeaponUtils.calculateMainGunParams(_loc3_.getTurret3D(),_loc3_.getLocalMuzzlePosition(),this.gunParams);
      }
      
      public function getEffects() : ShotgunEffects
      {
         return ShotgunEffects(getData(ShotgunEffects));
      }
      
      private function weaponObject() : ShotgunObject
      {
         if(this._shotgunObject == null)
         {
            this._shotgunObject = new ShotgunObject(object);
         }
         else
         {
            this._shotgunObject.setObject(object);
         }
         return this._shotgunObject;
      }
   }
}
