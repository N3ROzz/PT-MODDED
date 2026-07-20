package alternativa.tanks.models.weapon.railgun
{
   import alternativa.engine3d.materials.TextureMaterial;
   import alternativa.tanks.battle.BattleService;
   import alternativa.tanks.engine3d.EffectsMaterialRegistry;
   import alternativa.tanks.engine3d.TextureAnimation;
   import alternativa.tanks.models.sfx.bcsh.IBcsh;
   import alternativa.tanks.models.sfx.lighting.LightingSfx;
   import alternativa.tanks.utils.GraphicsUtils;
   import flash.display.BitmapData;
   import flash.filters.BitmapFilter;
   import platform.client.fp10.core.model.ObjectLoadPostListener;
   import platform.client.fp10.core.model.ObjectUnloadListener;
   import platform.client.fp10.core.resource.types.MultiframeImageResource;
   import platform.client.fp10.core.resource.types.ImageResource;
   import projects.tanks.client.battlefield.models.tankparts.sfx.shoot.railgun.IRailgunShootSFXModelBase;
   import projects.tanks.client.battlefield.models.tankparts.sfx.shoot.railgun.RailgunShootSFXCC;
   import projects.tanks.client.battlefield.models.tankparts.sfx.shoot.railgun.RailgunShootSFXModelBase;
   
   [ModelInfo]
   public class RailgunSFXModel extends RailgunShootSFXModelBase implements IRailgunShootSFXModelBase, IRailgunSFXModel, ObjectLoadPostListener, ObjectUnloadListener
   {
      
      [Inject] // added
      public static var materialRegistry:EffectsMaterialRegistry;
      
      [Inject] // added
      public static var battleService:BattleService;
      
      private const chargingTextureRegistry:ChargingTextureRegistry = new ChargingTextureRegistry();
      
      public function RailgunSFXModel()
      {
         super();
      }
      
      private static function getTextureAnimation(param1:MultiframeImageResource, param2:Number) : TextureAnimation
      {
         return getTextureAnimationFromBitmap(param1.data,param1.frameWidth,param1.frameHeight,param1.numFrames,param1.fps,param2);
      }
      
      private static function getTextureAnimationFromBitmap(param1:BitmapData, param2:int, param3:int, param4:int, param5:Number, param6:Number) : TextureAnimation
      {
         var _loc7_:TextureAnimation = GraphicsUtils.getTextureAnimation(materialRegistry,param1,param2,param3,param4);
         _loc7_.fps = param5;
         _loc7_.material.resolution = param6 / param2;
         return _loc7_;
      }
      
      private static function getFilteredTextureAnimation(param1:MultiframeImageResource, param2:Number, param3:Array) : TextureAnimation
      {
         return getTextureAnimationFromBitmap(getFilteredBitmap(param1.data,param3),param1.frameWidth,param1.frameHeight,param1.numFrames,param1.fps,param2);
      }
      
      private static function getFilteredBitmap(param1:BitmapData, param2:Array) : BitmapData
      {
         var _loc3_:BitmapFilter = getBcshFilter(param2);
         if(_loc3_ == null)
         {
            return param1;
         }
         return GraphicsUtils.createFilteredImage(param1,_loc3_);
      }
      
      private static function getBcshFilter(param1:Array) : BitmapFilter
      {
         var _loc2_:IBcsh = null;
         try
         {
            _loc2_ = IBcsh(object.adapt(IBcsh));
         }
         catch(e:Error)
         {
            return null;
         }
         if(_loc2_ == null)
         {
            return null;
         }
         return _loc2_.createFilterForKeys(param1);
      }
      
      private static function getTrailMaterial(param1:BitmapData, param2:Array = null) : TextureMaterial
      {
         var _loc3_:TextureMaterial = materialRegistry.getMaterial(param2 == null ? param1 : getFilteredBitmap(param1,param2));
         _loc3_.repeat = true;
         _loc3_.mipMapping = 0;
         return _loc3_;
      }
      
      [Obfuscation(rename="false")]
      public function objectLoadedPost() : void
      {
         var _loc1_:RailgunShootSFXCC = getInitParam();
         var _loc2_:RailgunSFXData = new RailgunSFXData();
         _loc2_.trailMaterial = getTrailMaterial(_loc1_.trailImage.data,["trail","trailImage","rail","railgun","shot","default"]);
         _loc2_.smokeMaterial = getTrailMaterial(_loc1_.smokeImage.data,["smoke","smokeImage","rail","railgun","shot","default"]);
         _loc2_.hitMarkMaterial = materialRegistry.getMaterial(getFilteredBitmap(_loc1_.hitMarkTexture.data,["hitMark","hitMarkTexture","hit","railgun","shot","default"]));
         _loc2_.chargingAnimation = this.getChargingAnimation(_loc1_.chargingPart1,_loc1_.chargingPart2,_loc1_.chargingPart3);
         _loc2_.ringsAnimation = getFilteredTextureAnimation(_loc1_.ringsTexture,RailgunEffects.RINGS_SIZE,["rings","ringsTexture","hit","railgun","shot","default"]);
         _loc2_.sphereAnimation = getFilteredTextureAnimation(_loc1_.sphereTexture,RailgunEffects.SPHERE_SIZE,["sphere","sphereTexture","hit","railgun","shot","default"]);
         _loc2_.powAnimation = getFilteredTextureAnimation(_loc1_.powTexture,RailgunEffects.POW_WIDTH,["pow","powTexture","railgun","shot","default"]);
         _loc2_.sound = _loc1_.shotSound.sound;
         var _loc3_:LightingSfx = new LightingSfx(getInitParam().lightingSFXEntity);
         _loc2_.chargeLightAnimation = _loc3_.createAnimation("charge");
         _loc2_.shotLightAnimation = _loc3_.createAnimation("shot");
         _loc2_.hitLightAnimation = _loc3_.createAnimation("hit");
         _loc2_.railLightAnimation = _loc3_.createAnimation("rail");
         putData(RailgunSFXData,_loc2_);
      }
      
      private function getChargingAnimation(param1:ImageResource, param2:ImageResource, param3:ImageResource) : TextureAnimation
      {
         var _loc4_:BitmapData = this.chargingTextureRegistry.getTexture(param1,param2,param3);
         _loc4_ = getFilteredBitmap(_loc4_,["charge","charging","chargingPart1","chargingPart2","chargingPart3","railgun","shot","default"]);
         var _loc5_:int = _loc4_.height;
         var _loc6_:TextureAnimation = GraphicsUtils.getTextureAnimation(materialRegistry,_loc4_,_loc5_,_loc5_);
         _loc6_.material.resolution = RailgunEffects.CHARGE_EFFECT_SIZE / _loc5_;
         return _loc6_;
      }
      
      [Obfuscation(rename="false")]
      public function objectUnloaded() : void
      {
         var _loc1_:RailgunSFXData = RailgunSFXData(getData(RailgunSFXData));
         materialRegistry.releaseMaterial(_loc1_.trailMaterial);
         materialRegistry.releaseMaterial(_loc1_.smokeMaterial);
         materialRegistry.releaseMaterial(_loc1_.chargingAnimation.material);
         materialRegistry.releaseMaterial(_loc1_.hitMarkMaterial);
         materialRegistry.releaseMaterial(_loc1_.ringsAnimation.material);
         materialRegistry.releaseMaterial(_loc1_.sphereAnimation.material);
         materialRegistry.releaseMaterial(_loc1_.powAnimation.material);
      }
      
      public function getEffects() : IRailgunEffects
      {
         return new RailgunEffects(RailgunSFXData(getData(RailgunSFXData)),battleService);
      }
   }
}
