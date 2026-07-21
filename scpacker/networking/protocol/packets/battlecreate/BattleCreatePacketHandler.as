package scpacker.networking.protocol.packets.battlecreate
{
   import scpacker.GameClassIds;
   import scpacker.networking.protocol.AbstractPacketHandler;
   import projects.tanks.client.battleselect.model.map.MapInfoCC;
   import alternativa.types.Long;
   import projects.tanks.client.battleservice.BattleMode;
   import projects.tanks.client.battleservice.Range;
   import alternativa.tanks.model.battleselect.create.BattleCreateModel;
   import alternativa.tanks.model.map.mapinfo.MapInfoModel;
   import scpacker.networking.protocol.AbstractPacket;
   import projects.tanks.client.battleservice.model.createparams.BattleLimits;
   import platform.client.fp10.core.model.impl.*;
   import platform.client.fp10.core.resource.types.ImageResource;
   import platform.client.fp10.core.type.IGameObject;
   import platform.client.fp10.core.type.IGameClass;
   import projects.tanks.client.battleselect.model.battleselect.create.BattleCreateCC;
   import scpacker.networking.protocol.packets.battlecreate.BattleCreateFailedDisabledInPacket;
   import scpacker.networking.protocol.packets.battlecreate.BattleCreateFailedServerHaltingInPacket;
   import scpacker.networking.protocol.packets.battlecreate.BattleCreateFailedTooManyBattlesInPacket;
   import scpacker.networking.protocol.packets.battlecreate.BattleCreateFailedBannedInPacket;
   import scpacker.networking.protocol.packets.battlecreate.SetFilteredBattleNameInPacket;
   import platform.client.fp10.core.type.ISpace;
   import scpacker.utils.EnumUtils;
   import projects.tanks.client.battleselect.model.battleselect.BattleSelectModelBase;
   import projects.tanks.client.battleselect.model.battleselect.create.BattleCreateModelBase;
   import projects.tanks.client.battleselect.model.map.MapInfoModelBase;
   import projects.tanks.client.battleservice.model.map.params.MapTheme;
   import scpacker.SpaceAndGameObjectIds;
   import projects.tanks.client.tanksservices.model.formatbattle.EquipmentConstraintsCC;
   import projects.tanks.client.tanksservices.model.formatbattle.EquipmentConstraintsNamingModelBase;
   import projects.tanks.client.tanksservices.model.formatbattle.EquipmentConstraintsModeInfo;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.formatbattle.EquipmentConstraintsNamingModel;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.probattle.UserProBattleService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.probattle.IUserProBattleService;
   import alternativa.osgi.OSGi;
   import utils.TankTraceUtil;
   
   public class BattleCreatePacketHandler extends AbstractPacketHandler
   {
      private static var mapNamesById:Object = {};
      private static var mapNamesByPreview:Object = {};
      private static var fallbackMapNamesById:Object = createFallbackMapNamesById();
      private static var fallbackMapNamesByPreview:Object = createFallbackMapNamesByPreview();

      private var battleCreateModel:BattleCreateModel;
      private var mapInfoModel:MapInfoModel;
      private var equipmentConstraintsNamingMode:EquipmentConstraintsNamingModel;
      
      //private var clanInfoModel:ClanInfoModel;
      
      private var battleSelectGameClass:IGameClass;
      private var battleSelectObject:IGameObject;
      private var mapGameClass:IGameClass;
      
      private var userProBattleService:IUserProBattleService;
      
      public function BattleCreatePacketHandler()
      {
         super();
         this.id = 30;
         this.battleCreateModel = BattleCreateModel(modelRegistry.getModel(BattleCreateModelBase.modelId));
         this.mapInfoModel = MapInfoModel(modelRegistry.getModel(MapInfoModelBase.modelId));
         this.equipmentConstraintsNamingMode = EquipmentConstraintsNamingModel(modelRegistry.getModel(EquipmentConstraintsNamingModelBase.modelId));
         this.userProBattleService = OSGi.getInstance().getService(IUserProBattleService) as IUserProBattleService;
         //this.clanInfoModel = ClanInfoModel(modelRegistry.getModel(Long.getLong(0,300090014)));

         var battleSelectModels:Vector.<Long> = new Vector.<Long>();
         battleSelectModels.push(BattleCreateModelBase.modelId);
         battleSelectModels.push(BattleSelectModelBase.modelId);
         battleSelectModels.push(EquipmentConstraintsNamingModelBase.modelId);

         var mapModels:Vector.<Long> = new Vector.<Long>();
         mapModels.push(MapInfoModelBase.modelId);
         //_loc2_.push(this.clanInfoModel.id);

         this.mapGameClass = gameTypeRegistry.createClass(GameClassIds.BATTLE_SELECT_MAP,mapModels);
         this.battleSelectGameClass = gameTypeRegistry.createClass(Long.getLong(591359,5235923),battleSelectModels);
      }

      public static function getKnownMapName(mapId:String, preview:String) : String
      {
         var mapName:String = null;
         if(mapId != null)
         {
            mapName = mapNamesById[mapId];
            if(mapName == null)
            {
               mapName = fallbackMapNamesById[mapId];
            }
         }
         if(mapName == null && preview != null)
         {
            mapName = mapNamesByPreview[preview];
            if(mapName == null)
            {
               mapName = fallbackMapNamesByPreview[preview];
            }
         }
         return mapName;
      }

      private static function createFallbackMapNamesById() : Object
      {
         var names:Object = {};
         names["4006"] = "Boombox";
         names["4010"] = "Bridges";
         names["4030"] = "Desert";
         names["4036"] = "Dusseldorf";
         names["4044"] = "Farm";
         names["4171"] = "Iran";
         names["4173"] = "Island";
         names["4174"] = "Island";
         names["4177"] = "Kungur";
         names["4182"] = "Madness";
         names["4192"] = "Monte Carlo";
         names["4194"] = "Noise";
         names["4195"] = "Noise";
         names["4309"] = "Ping-Pong";
         names["4312"] = "Polygon";
         names["4319"] = "Sandal";
         names["4320"] = "Sandal";
         names["4321"] = "Sandbox";
         names["4325"] = "Serpukhov";
         names["4331"] = "Silence";
         names["4332"] = "Silence";
         names["4342"] = "Station";
         names["6466"] = "Station";
         return names;
      }

      private static function createFallbackMapNamesByPreview() : Object
      {
         var names:Object = {};
         names["4493"] = "Boombox";
         names["4497"] = "Bridges";
         names["4618"] = "Desert";
         names["4625"] = "Dusseldorf";
         names["4633"] = "Farm";
         names["4756"] = "Iran";
         names["4758"] = "Island";
         names["4763"] = "Kungur";
         names["4769"] = "Madness";
         names["4779"] = "Monte Carlo";
         names["4781"] = "Noise";
         names["4782"] = "Noise";
         names["4794"] = "Ping-Pong";
         names["4798"] = "Polygon";
         names["4906"] = "Sandal";
         names["4907"] = "Sandal";
         names["4909"] = "Sandbox";
         names["4914"] = "Serpukhov";
         names["4920"] = "Silence";
         names["4922"] = "Silence";
         names["4937"] = "Station";
         names["6498"] = "Station";
         return names;
      }

      private function parseSupportedModes(param1:Object) : Vector.<BattleMode>
      {
         var _loc3_:BattleMode = null;
         var _loc2_:Vector.<BattleMode> = new Vector.<BattleMode>();
         if(param1 == null)
         {
            return _loc2_;
         }
         for each(var _loc4_ in param1)
         {
            try
            {
               _loc3_ = EnumUtils.stringToBattleMode(String(_loc4_));
               _loc2_.push(_loc3_);
            }
            catch(error:Error)
            {
               TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.skipMode mode=" + _loc4_ + " reason=" + error.message);
            }
         }
         return _loc2_;
      }

      private function parseMapTheme(param1:Object) : MapTheme
      {
         var _loc2_:MapTheme = null;
         if(param1 == null)
         {
            return null;
         }
         try
         {
            _loc2_ = EnumUtils.stringToMapTheme(String(param1));
         }
         catch(error:Error)
         {
            _loc2_ = null;
         }
         return _loc2_;
      }

      private function describeSupportedModes(param1:Object) : String
      {
         var _loc2_:Array = [];
         if(param1 == null)
         {
            return "null";
         }
         for each(var _loc3_ in param1)
         {
            _loc2_.push(String(_loc3_));
         }
         return _loc2_.join(",");
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case BattleCreateFailedDisabledInPacket.id:
               this.createFailedBattleCreateDisabled();
               break;
            case BattleCreateFailedServerHaltingInPacket.id:
               this.createFailedServerIsHalting();
               break;
            case BattleCreateFailedTooManyBattlesInPacket.id:
               this.createFailedTooManyBattlesFromYou();
               break;
            case BattleCreateFailedBannedInPacket.id:
               this.createFailedYouAreBanned();
               break;
            case InitBattleSelectInPacket.id:
               this.initBattleList(param1 as InitBattleSelectInPacket);
               break;
            case SetFilteredBattleNameInPacket.id:
               this.setFilteredBattleName(param1 as SetFilteredBattleNameInPacket);
         }
      }
      
      private function initBattleList(param1:InitBattleSelectInPacket) : void
      {
          TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.initBattleList jsonLength=" + (param1.battlesJson == null ? -1 : param1.battlesJson.length));
          var mapObjectInstance:IGameObject = null;
          var mapInfoInstance:MapInfoCC = null;
          //var clanInfoInstance:ClanInfoCC = null;
          var spaceInstance:ISpace = spaceRegistry.getSpace(SpaceAndGameObjectIds.BATTLE_SELECT_SPACE_ID);
          this.battleSelectObject = spaceInstance.createObject(SpaceAndGameObjectIds.BATTLE_SELECT_OBJECT_ID,this.battleSelectGameClass,"BattleSelectObject");
          
          var battlesData:Object = JSON.parse(param1.battlesJson);
          TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.parsed maps=" + (battlesData.maps == null ? -1 : battlesData.maps.length) + " battleCreationDisabled=" + battlesData.battleCreationDisabled);
          TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.beforeMapRegistration");
          var mapObjectId:Long = null;
          var mapRegisterIndex:int = 0;
          var validMapsRegistered:int = 0;
          var mapTheme:MapTheme = null;
          var supportedModes:Vector.<BattleMode> = null;
          for each(var mapData in battlesData.maps)
          {
            try
            {
               if(mapData == null)
               {
                  TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.skipMap index=" + mapRegisterIndex + " reason=nullMap");
                  mapRegisterIndex++;
                  continue;
               }
               supportedModes = this.parseSupportedModes(mapData.supportedModes);
               mapTheme = this.parseMapTheme(mapData.theme);
               if(mapTheme == null || supportedModes.length == 0)
               {
                  TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.skipMap index=" + mapRegisterIndex + " mapId=" + mapData.mapId + " preview=" + mapData.preview + " theme=" + mapData.theme + " modes=" + this.describeSupportedModes(mapData.supportedModes) + " reason=unsupportedMapParams");
                  mapRegisterIndex++;
                  continue;
               }
               mapObjectId = Long.getLong(int(mapData.preview) * 1000,int(mapData.preview) * 1000);
               mapObjectInstance = spaceInstance.getObject(mapObjectId);
               if(mapObjectInstance == null)
               {
                  mapObjectInstance = spaceInstance.createObject(mapObjectId,this.mapGameClass,mapData.mapId + mapData.theme);
               }
               else
               {
                  TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.reuseMapObject index=" + mapRegisterIndex + " mapId=" + mapData.mapId + " preview=" + mapData.preview + " theme=" + mapData.theme);
               }
               mapInfoInstance = new MapInfoCC();
               mapInfoInstance.additionalCrystalsPercent = mapData.additionalCrystalsPercent;
               mapInfoInstance.defaultTheme = mapTheme;
               mapInfoInstance.enabled = mapData.enabled;
               mapInfoInstance.mapId = mapData.mapId;
               mapInfoInstance.mapName = mapData.mapName;
               mapNamesById[String(mapData.mapId)] = mapData.mapName;
               mapNamesByPreview[String(mapData.preview)] = mapData.mapName;
               mapInfoInstance.maxPeople = mapData.maxPeople;
               mapInfoInstance.preview = ImageResource(resourceRegistry.getResource(Long.getLong(0,mapData.preview)));
               mapInfoInstance.rankLimit = new Range(mapData.maxRank,mapData.minRank);
               mapInfoInstance.supportedModes = supportedModes;
               mapInfoInstance.theme = mapTheme;
               //_loc2_ = new ClanInfoCC(mapData.clanLink,mapData.clanName);
               Model.object = mapObjectInstance;
               try
               {
                  this.mapInfoModel.putInitParams(mapInfoInstance);
                  this.mapInfoModel.objectLoaded();
                  validMapsRegistered++;
               }
               finally
               {
                  Model.popObject();
               }
               //this.clanInfoModel.putInitParams(clanInfoInstance);
            }
            catch(mapError:Error)
            {
               TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.skipMap index=" + mapRegisterIndex + " mapId=" + mapData.mapId + " preview=" + mapData.preview + " theme=" + mapData.theme + " modes=" + this.describeSupportedModes(mapData.supportedModes) + " reason=" + mapError.message);
            }
            mapRegisterIndex++;
          }
          TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.afterMapRegistration mapsRegistered=" + MapInfoModel.getMaps().length + " validThisPacket=" + validMapsRegistered);
          if(validMapsRegistered == 0)
          {
             TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.noValidMaps abortCreateInit");
             return;
          }

         var equipmentConstraintsCC:EquipmentConstraintsCC = new EquipmentConstraintsCC();
         equipmentConstraintsCC.equipmentConstraintsModeInfos = new Vector.<EquipmentConstraintsModeInfo>();
         //equipmentConstraintsCC.equipmentConstraintsModeInfos.push(new EquipmentConstraintsModeInfo(0,"NONE","Default"));
         equipmentConstraintsCC.equipmentConstraintsModeInfos.push(new EquipmentConstraintsModeInfo(0,"HORNET_RAILGUN","Hornet & Railgun"));
         equipmentConstraintsCC.equipmentConstraintsModeInfos.push(new EquipmentConstraintsModeInfo(1,"WASP_RAILGUN","Wasp & Railgun"));
         equipmentConstraintsCC.equipmentConstraintsModeInfos.push(new EquipmentConstraintsModeInfo(2,"HORNET_WASP_RAILGUN","Hornet, Wasp & Railgun"));

         Model.object = this.battleSelectObject;
         try
         {
         this.equipmentConstraintsNamingMode.putInitParams(equipmentConstraintsCC);
         this.equipmentConstraintsNamingMode.objectLoaded();
         }          finally          {             Model.popObject();          }

          Model.object = this.battleSelectObject;
          try
          {

          var battleCreateParams:BattleCreateCC = new BattleCreateCC();
          battleCreateParams.battleCreationDisabled = battlesData.battleCreationDisabled;
          battleCreateParams.battlesLimits = new Vector.<BattleLimits>();
   
          for each(var limit in battlesData.battleLimits)
          {
            battleCreateParams.battlesLimits.push(new BattleLimits(limit.scoreLimit,limit.timeLimitInSec));
          }
          while(battleCreateParams.battlesLimits.length < BattleMode.values.length)
          {
            battleCreateParams.battlesLimits.push(new BattleLimits(999,1800));
          }

          battleCreateParams.maxRangeLength = battlesData.maxRangeLength == null ? 31 : int(battlesData.maxRangeLength);
          battleCreateParams.maxRange = new Range(31,1);
          var defaultMaxRank:int = Math.min(Math.max(1,battleCreateParams.maxRangeLength),31);
          battleCreateParams.defaultRange = new Range(defaultMaxRank,1);
          battleCreateParams.ultimatesEnabled = true;
          //battleCreateParams.proBattleTimeLeftInSec = battlesData.proBattleTimeLeftInSec;
          this.battleCreateModel.putInitParams(battleCreateParams);
          TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.beforeBattleCreateModelLoad mapsRegistered=" + MapInfoModel.getMaps().length);
          this.battleCreateModel.objectLoaded();
          this.battleCreateModel.objectLoadedPost();
          TankTraceUtil.logCreateBattle("BattleCreatePacketHandler.afterBattleCreateModelLoad");
          }           finally           {              Model.popObject();           }
      }
      
      private function createFailedBattleCreateDisabled() : void
      {
         this.battleCreateModel.createFailedBattleCreateDisabled();
      }
      
      private function createFailedServerIsHalting() : void
      {
         this.battleCreateModel.createFailedServerIsHalting();
      }
      
      private function createFailedTooManyBattlesFromYou() : void
      {
         this.battleCreateModel.createFailedTooManyBattlesFromYou();
      }
      
      private function createFailedYouAreBanned() : void
      {
         this.battleCreateModel.createFailedYouAreBanned();
      }
      
      private function setFilteredBattleName(param1:SetFilteredBattleNameInPacket) : void
      {
         var _loc2_:IGameObject = spaceRegistry.getSpace(SpaceAndGameObjectIds.BATTLE_SELECT_SPACE_ID).getObjectByName("BattleSelectObject");
         Model.object = _loc2_;
         try
         {
         this.battleCreateModel.setFilteredBattleName(param1.battleName);
         }          finally          {             Model.popObject();          }
      }
   }
}
