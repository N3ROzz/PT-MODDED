package alternativa.tanks.services.bonusregion
{
   import alternativa.engine3d.core.Vertex;
   import alternativa.engine3d.materials.TextureMaterial;
   import alternativa.engine3d.objects.Decal;
   import alternativa.engine3d.objects.Mesh;
   import alternativa.math.Matrix3;
   import alternativa.math.Vector3;
   import alternativa.physics.collision.types.RayHit;
   import alternativa.tanks.battle.BattleRunner;
   import alternativa.tanks.battle.BattleService;
   import alternativa.tanks.battle.BattleUtils;
   import alternativa.tanks.battle.events.BattleEventDispatcher;
   import alternativa.tanks.battle.events.BattleEventListener;
   import alternativa.tanks.battle.events.BattleEventSupport;
   import alternativa.tanks.battle.events.BattleFinishEvent;
   import alternativa.tanks.battle.objects.tank.Tank;
   import alternativa.tanks.models.bonus.region.BonusRegion;
   import alternativa.tanks.models.bonus.region.GoldBonusRegion;
   import alternativa.tanks.physics.CollisionGroup;
   import alternativa.tanks.physics.TanksCollisionDetector;
   import alternativa.tanks.service.settings.ISettingsService;
   import alternativa.tanks.service.settings.SettingsServiceEvent;
   import alternativa.utils.TextureMaterialRegistry;
   import alternativa.utils.clearDictionary;
   import flash.display.BitmapData;
   import flash.utils.Dictionary;
   import platform.client.fp10.core.resource.types.StubBitmapData;
   import projects.tanks.client.battlefield.models.bonus.battle.bonusregions.BonusRegionData;
   import projects.tanks.client.battlefield.models.bonus.battle.bonusregions.BonusRegionResource;
   import projects.tanks.client.battlefield.models.bonus.bonus.BonusesType;
   import utils.goldbox.GoldBoxDiagnostics;
   
   public class BonusRegionService implements IBonusRegionService, BattleEventListener
   {
      
      [Inject] // added
      public static var battleService:BattleService;
      
      [Inject] // added
      public static var materialRegistry:TextureMaterialRegistry;
      
      [Inject] // added
      public static var settings:ISettingsService;
      
      private static var stubBitmapData:BitmapData;
      
      private static const REGION_SIZE:int = 478;
       
      private static const REGION_DECAL_ASCENSION:Number = 0.1;

      private static const MAX_GROUND_RAY_DISTANCE:Number = 10000000000;

      private static const FLAT_SURFACE_NORMAL_Z:Number = 0.9998476951563913;

      private static const MIN_AXIS_LENGTH_SQUARED:Number = 1e-10;

      private static const rayHit:RayHit = new RayHit();

      private static const rotationAxis:Vector3 = new Vector3();

      private static const rotationAngles:Vector3 = new Vector3();

      private static const surfaceRotation:Matrix3 = new Matrix3();

      private static const yawRotation:Matrix3 = new Matrix3();
      
      private var _battleEventSupport:BattleEventSupport;
      
      private var _textures:Dictionary;
      
      private var _bonusRegions:Dictionary;
      
      private var _forceShow:Boolean;
      
      private var _forceHide:Boolean;
      
      private var _tank:Tank;
      
      public function BonusRegionService(param1:BattleEventDispatcher)
      {
         super();
         this._battleEventSupport = new BattleEventSupport(param1,this);
         this._battleEventSupport.addEventHandler(BattleFinishEvent,this.onBattleFinished);
      }
      
      private static function createRegion(param1:Vector3, param2:Vector3, param3:TextureMaterial, param4:Number) : Mesh
      {
         var _loc11_:Number = NaN;
         var _loc4_:Decal = new Decal();
         var _loc5_:Number = REGION_SIZE / 2;
         var _loc6_:Number = 0.5;
         var _loc7_:Vertex = _loc4_.addVertex(-_loc5_,_loc5_,_loc6_,0,0);
         var _loc8_:Vertex = _loc4_.addVertex(-_loc5_,-_loc5_,_loc6_,0,1);
         var _loc9_:Vertex = _loc4_.addVertex(_loc5_,-_loc5_,_loc6_,1,1);
         var _loc10_:Vertex = _loc4_.addVertex(_loc5_,_loc5_,_loc6_,1,0);
         _loc4_.addQuadFace(_loc7_,_loc8_,_loc9_,_loc10_,param3);
         _loc4_.calculateFacesNormals();
         _loc4_.calculateVerticesNormals();
         _loc4_.x = param1.x;
         _loc4_.y = param1.y;
         _loc4_.z = param1.z + REGION_DECAL_ASCENSION;
         if(param2.z > FLAT_SURFACE_NORMAL_Z)
         {
            rotationAngles.reset(0,0,param4);
         }
         else
         {
            rotationAxis.cross2(Vector3.Z_AXIS,param2);
            if(rotationAxis.lengthSqr() <= MIN_AXIS_LENGTH_SQUARED)
            {
               rotationAngles.reset(0,0,param4);
            }
            else
            {
               rotationAxis.normalize();
               _loc11_ = Math.acos(Math.max(-1,Math.min(1,param2.z)));
               surfaceRotation.fromAxisAngle(rotationAxis,_loc11_);
               yawRotation.setRotationMatrix(0,0,param4);
               yawRotation.append(surfaceRotation);
               yawRotation.getEulerAngles(rotationAngles);
            }
         }
         _loc4_.rotationX = rotationAngles.x;
         _loc4_.rotationY = rotationAngles.y;
         _loc4_.rotationZ = rotationAngles.z;
         return _loc4_;
      }
      
      private static function getStubBitmapData() : BitmapData
      {
         if(stubBitmapData == null)
         {
            stubBitmapData = new StubBitmapData(65280);
         }
         return stubBitmapData;
      }
      
      private function onBattleFinished(param1:BattleFinishEvent) : void
      {
         this.hideAndRemoveGoldRegions();
      }
      
      private function hideAndRemoveGoldRegions() : void
      {
         var _loc1_:BonusRegion = null;
         for each(_loc1_ in this._bonusRegions)
         {
            if(_loc1_ is GoldBonusRegion)
            {
               _loc1_.hideAndRemoveFromGame();
               delete this._bonusRegions[_loc1_.getPosition().toString()];
            }
         }
      }
      
      public function showAll() : void
      {
         var _loc1_:BonusRegion = null;
         if(this._forceShow)
         {
            for each(_loc1_ in this._bonusRegions)
            {
               _loc1_.showForce();
            }
         }
      }
      
      private function hasTank() : Boolean
      {
         return this._tank != null;
      }
      
      public function handleBattleEvent(param1:Object) : void
      {
         this._battleEventSupport.handleBattleEvent(param1);
      }
      
      public function prepare(param1:Vector.<BonusRegionResource>) : void
      {
         this._forceShow = settings.showDropZones;
         this._forceHide = !this._forceShow;
         settings.addEventListener(SettingsServiceEvent.SETTINGS_CHANGED,this.onSettingsAccept);
         this._battleEventSupport.activateHandlers();
         this._bonusRegions = new Dictionary();
         this.initMaterials(param1);
      }
      
      private function onSettingsAccept(param1:SettingsServiceEvent) : void
      {
         if(this._forceShow != settings.showDropZones)
         {
            this.toggleRegionsVisible();
         }
      }
      
      private function initMaterials(param1:Vector.<BonusRegionResource>) : void
      {
         var _loc4_:BonusRegionResource = null;
         this._textures = new Dictionary();
         var _loc2_:int = int(param1.length);
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_)
         {
            _loc4_ = param1[_loc3_];
            this._textures[_loc4_.regionType] = _loc4_.dropZoneResource.data;
            _loc3_++;
         }
      }
      
      public function destroy() : void
      {
         settings.removeEventListener(SettingsServiceEvent.SETTINGS_CHANGED,this.onSettingsAccept);
         this._battleEventSupport.deactivateHandlers();
         this.destroyBonusRegions();
         this.destroyTextures();
         this._tank = null;
      }
      
      private function destroyBonusRegions() : void
      {
         var _loc1_:BonusRegion = null;
         for each(_loc1_ in this._bonusRegions)
         {
            _loc1_.removeFromGame();
         }
         clearDictionary(this._bonusRegions);
         this._bonusRegions = null;
      }
      
      private function destroyTextures() : void
      {
         clearDictionary(this._textures);
         this._textures = null;
      }
      
      public function addOneRegion(param1:BonusRegionData) : void
      {
         this.tryAddRegion(param1,"preloaded_region");
      }

      private function tryAddRegion(param1:BonusRegionData, param2:String = "unknown") : Boolean
      {
         var _loc2_:Vector3 = null;
         var _loc3_:Vector3 = null;
         var _loc4_:Mesh = null;
         var _loc5_:BonusRegion = null;
         var _loc6_:BattleRunner = null;
         var _loc7_:TanksCollisionDetector = null;
         var _loc8_:TextureMaterial = null;
         if(param1 == null || param1.position == null || param1.rotation == null || this._bonusRegions == null || this._textures == null || this.hasRegion(param1) || battleService == null || materialRegistry == null)
         {
            return false;
         }
         _loc6_ = battleService.getBattleRunner();
         if(_loc6_ == null)
         {
            return false;
         }
         _loc7_ = _loc6_.getCollisionDetector();
         if(_loc7_ == null)
         {
            return false;
         }
         if(battleService.getBattleScene3D() == null)
         {
            return false;
         }
         _loc2_ = BattleUtils.getVector3(param1.position);
         rayHit.clear();
         if(!_loc7_.raycastStatic(_loc2_,Vector3.DOWN,CollisionGroup.STATIC,MAX_GROUND_RAY_DISTANCE,null,rayHit))
         {
            return false;
         }
         _loc3_ = rayHit.position.clone();
         if(param1.regionType == BonusesType.GOLD)
         {
            GoldBoxDiagnostics.onDropZoneGrounded(_loc2_.toString(),_loc2_.x,_loc2_.y,_loc2_.z,_loc3_.x,_loc3_.y,_loc3_.z,param2);
         }
         _loc8_ = this.getMaterial(param1.regionType);
         if(_loc8_ == null)
         {
            return false;
         }
         _loc4_ = createRegion(_loc3_,rayHit.normal,_loc8_,param1.rotation.z);
         if(param1.regionType == BonusesType.GOLD)
         {
            _loc5_ = new GoldBonusRegion(_loc4_,_loc2_);
         }
         else
         {
            _loc5_ = new BonusRegion(_loc4_,_loc2_,this._forceShow);
         }
         _loc5_.addToGame();
         this._bonusRegions[_loc2_.toString()] = _loc5_;
         return true;
      }
      
      public function addFewRegions(param1:Vector.<BonusRegionData>) : void
      {
         var _loc2_:int = int(param1.length);
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_)
         {
            this.addOneRegion(param1[_loc3_]);
            _loc3_++;
         }
      }
      
      private function getMaterial(param1:BonusesType) : TextureMaterial
      {
         var _loc2_:BitmapData = this._textures[param1];
         if(_loc2_ == null)
         {
            _loc2_ = getStubBitmapData();
         }
         var _loc3_:TextureMaterial = materialRegistry.getMaterial(_loc2_);
         if(_loc3_ != null && _loc3_.texture != null && _loc3_.texture.width > 0)
         {
            _loc3_.resolution = REGION_SIZE / _loc3_.texture.width;
         }
         return _loc3_;
      }
      
      public function setTank(param1:Tank) : void
      {
         this._tank = param1;
      }
      
      public function changeTank(param1:Tank) : void
      {
         if(!this.hasTank() || this.hasTank() && this._tank.getUser() != param1.getUser())
         {
            this._tank = param1;
         }
      }
      
      public function resetTank() : void
      {
         this._tank = null;
         if(this._forceShow)
         {
            this.showAll();
         }
      }
      
      public function enableForceShow() : void
      {
         var _loc1_:BonusRegion = null;
         this._forceShow = true;
         this._forceHide = false;
         settings.showDropZones = true;
         for each(_loc1_ in this._bonusRegions)
         {
            if(!(_loc1_ is GoldBonusRegion))
            {
               _loc1_.showForce();
            }
         }
      }
      
      public function enableForceHide() : void
      {
         var _loc1_:BonusRegion = null;
         this._forceHide = true;
         this._forceShow = false;
         settings.showDropZones = false;
         for each(_loc1_ in this._bonusRegions)
         {
            if(!(_loc1_ is GoldBonusRegion))
            {
               _loc1_.hideForce();
            }
         }
      }
      
      public function addAndShowRegion(param1:BonusRegionData) : void
      {
         var _loc2_:Vector3 = null;
         var _loc3_:BonusRegion = null;
         var _loc4_:String = "unknown";
         if(param1 != null && param1.position != null && param1.regionType == BonusesType.GOLD)
         {
            _loc2_ = BattleUtils.getVector3(param1.position);
            _loc4_ = GoldBoxDiagnostics.consumeDropZoneSource(_loc2_.toString(),"unknown");
            GoldBoxDiagnostics.onDropZoneShow(_loc2_.toString(),param1.regionType.name,_loc2_.x,_loc2_.y,_loc2_.z,_loc4_);
         }
         if(!this.hasRegion(param1))
         {
            if(!this.tryAddRegion(param1,_loc4_))
            {
               return;
            }
            _loc2_ = BattleUtils.getVector3(param1.position);
            _loc3_ = this._bonusRegions[_loc2_.toString()];
            if(_loc3_ != null)
            {
               _loc3_.show();
            }
         }
      }
      
      public function hideAndRemoveRegion(param1:BonusRegionData) : void
      {
         var _loc2_:Vector3 = null;
         var _loc3_:BonusRegion = null;
         if(param1 != null && param1.position != null && param1.regionType == BonusesType.GOLD)
         {
            _loc2_ = BattleUtils.getVector3(param1.position);
            GoldBoxDiagnostics.onDropZoneHide(_loc2_.toString());
         }
         if(this.hasRegion(param1))
         {
            _loc2_ = BattleUtils.getVector3(param1.position);
            _loc3_ = this._bonusRegions[_loc2_.toString()];
            _loc3_.hideAndRemoveFromGame();
            delete this._bonusRegions[_loc2_.toString()];
         }
      }
      
      public function hasRegion(param1:BonusRegionData) : Boolean
      {
         if(param1 == null || param1.position == null || this._bonusRegions == null)
         {
            return false;
         }
         var _loc2_:Vector3 = BattleUtils.getVector3(param1.position);
         return this._bonusRegions[_loc2_.toString()] != undefined;
      }
      
      public function toggleRegionsVisible() : void
      {
         if(this._forceShow)
         {
            this.enableForceHide();
         }
         else if(this._forceHide)
         {
            this.enableForceShow();
         }
      }
   }
}
