package scpacker.networking.protocol.packets.battlelist
{
   import scpacker.GameClassIds;
   import scpacker.networking.protocol.AbstractPacketHandler;
   import alternativa.types.Long;
   import projects.tanks.client.battleservice.Range;
   import alternativa.osgi.OSGi;
   import alternativa.tanks.model.battleselect.BattleSelectModel;
   import alternativa.tanks.service.achievement.IAchievementService;
   import scpacker.networking.protocol.AbstractPacket;
   import platform.client.fp10.core.model.impl.*;
   import platform.client.fp10.core.type.IGameObject;
   import platform.client.fp10.core.type.IGameClass;
   import projects.tanks.client.battleselect.model.item.BattleSuspicionLevel;
   import projects.tanks.client.battleselect.model.battle.dm.BattleDMInfoCC;
   import projects.tanks.client.battleselect.model.battle.dm.BattleDMInfoModelBase;
   import alternativa.tanks.model.info.dm.BattleDmInfoModel;
   import alternativa.tanks.model.info.BattleInfoModel;
   import alternativa.tanks.model.info.team.BattleTeamInfoModel;
   import alternativa.tanks.model.info.param.BattleParamInfoModel;
   import alternativa.tanks.model.map.mapinfo.MapInfoModel;
   import projects.tanks.client.battleselect.model.battle.BattleInfoModelBase;
   import projects.tanks.client.battleselect.model.battle.team.TeamBattleInfoModelBase;
   import projects.tanks.client.battleselect.model.battle.param.BattleParamInfoModelBase;
   import projects.tanks.client.battleselect.model.map.MapInfoCC;
   import projects.tanks.client.battleselect.model.map.MapInfoModelBase;
   import platform.client.fp10.core.type.ISpace;
   import platform.client.fp10.core.resource.types.ImageResource;
   import scpacker.utils.IdTool;
   import projects.tanks.client.battleselect.model.battle.BattleInfoCC;
   import projects.tanks.client.battleselect.model.battle.team.TeamBattleInfoCC;
   import projects.tanks.client.battleselect.model.battle.entrance.user.BattleInfoUser;
   import projects.tanks.client.battleselect.model.battle.param.BattleParamInfoCC;
   import projects.tanks.client.battleservice.BattleCreateParameters;
   import projects.tanks.client.battleservice.BattleMode;
   import scpacker.utils.EnumUtils;
   import projects.tanks.client.battleselect.model.battleselect.BattleSelectModelBase;
   import scpacker.SpaceAndGameObjectIds;
   import projects.tanks.client.battleservice.model.createparams.BattleLimits;
   import projects.tanks.client.battleselect.model.battle.entrance.BattleEntranceModelBase;
   import alternativa.tanks.model.battleselect.create.BattleCreateModel;
   import projects.tanks.client.battleselect.model.battleselect.create.BattleCreateCC;
   import projects.tanks.client.battleselect.model.battleselect.create.BattleCreateModelBase;
   import scpacker.networking.protocol.packets.battlecreate.BattleCreatePacketHandler;
   import utils.TankTraceUtil;
   import utils.BattleSelectionTrace;
   
   public class BattleListPacketHandler extends AbstractPacketHandler
   {
      private var battleSelectModel:BattleSelectModel;
      private var achievementService:IAchievementService;
      private var battleSelectSpace:ISpace;

      private var battleInfoModel:BattleInfoModel;
      private var battleInfoDmModel:BattleDmInfoModel;
      private var battleTeamInfoModel:BattleTeamInfoModel;
      private var battleParamsInfoModel:BattleParamInfoModel;
      private var mapInfoModel:MapInfoModel;
      private var battleCreateModel:BattleCreateModel;
      private var mapGameClass:IGameClass;

      public static var dmBattleInfoGameClass:IGameClass;
      public static var teamBattleInfoGameClass:IGameClass;
      
      private var battleSelectObject:IGameObject;
      
      public function BattleListPacketHandler()
      {
         super();
         this.id = 31;

         this.battleSelectModel = BattleSelectModel(modelRegistry.getModel(BattleSelectModelBase.modelId));
         this.battleInfoModel = BattleInfoModel(modelRegistry.getModel(BattleInfoModelBase.modelId));
         this.battleInfoDmModel = BattleDmInfoModel(modelRegistry.getModel(BattleDMInfoModelBase.modelId));
         this.battleTeamInfoModel = BattleTeamInfoModel(modelRegistry.getModel(TeamBattleInfoModelBase.modelId));
         this.battleParamsInfoModel = BattleParamInfoModel(modelRegistry.getModel(BattleParamInfoModelBase.modelId));
         this.mapInfoModel = MapInfoModel(modelRegistry.getModel(MapInfoModelBase.modelId));
         this.battleCreateModel = BattleCreateModel(modelRegistry.getModel(BattleCreateModelBase.modelId));
         
         var modelVector:Vector.<Long> = new Vector.<Long>();
         modelVector.push(BattleInfoModelBase.modelId);
         modelVector.push(BattleDMInfoModelBase.modelId);
         modelVector.push(BattleParamInfoModelBase.modelId);
         modelVector.push(BattleEntranceModelBase.modelId);
         dmBattleInfoGameClass = gameTypeRegistry.createClass(Long.getLong(5823623,5812059),modelVector);

         modelVector = new Vector.<Long>();
         modelVector.push(BattleInfoModelBase.modelId);
         modelVector.push(TeamBattleInfoModelBase.modelId);
         modelVector.push(BattleParamInfoModelBase.modelId);
         modelVector.push(BattleEntranceModelBase.modelId);
         teamBattleInfoGameClass = gameTypeRegistry.createClass(Long.getLong(5823622,5812058),modelVector);

         modelVector = new Vector.<Long>();
         modelVector.push(MapInfoModelBase.modelId);
         this.mapGameClass = gameTypeRegistry.createClass(GameClassIds.BATTLE_SELECT_MAP,modelVector);

         this.battleSelectSpace = spaceRegistry.getSpace(SpaceAndGameObjectIds.BATTLE_SELECT_SPACE_ID);
         this.achievementService = IAchievementService(OSGi.getInstance().getService(IAchievementService));
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         TankTraceUtil.logBattleList("BattleListPacketHandler.invoke packetId=" + param1.getId());
         switch(param1.getId())
         {
            case BattleCreatedInPacket.id:
               this.createBattle(param1 as BattleCreatedInPacket);
               break;
            case LoadAllBattlesInPacket.id:
               this.loadAllBattles(param1 as LoadAllBattlesInPacket);
               break;
            case RemoveBattleInPacket.id:
               this.removeBattle(param1 as RemoveBattleInPacket);
               break;
            case SelectBattleInOutPacket.id:
               this.selectBattle(param1 as SelectBattleInOutPacket);
               break;
            case UnloadBattleSelectSpaceInPacket.id:
               this.unloadAllBattles();
         }
      }
      
      private function loadAllBattles(param1:LoadAllBattlesInPacket) : void
      {
         var _loc4_:int = 0;
         var _loc5_:Object = null;
         TankTraceUtil.logBattleList("loadAllBattles packet jsonLength=" + (param1.battlesJson == null ? -1 : param1.battlesJson.length));
         // Creating object for BattleSelectModel so that getFunctionWrapper works correctly
         var spaceInstance:ISpace = spaceRegistry.getSpace(SpaceAndGameObjectIds.BATTLE_SELECT_SPACE_ID);
         this.battleSelectObject = spaceInstance.getObject(SpaceAndGameObjectIds.BATTLE_SELECT_OBJECT_ID);

         if (this.battleSelectObject == null)
         {
            TankTraceUtil.logBattleList("loadAllBattles ERROR BattleSelectObject is null");
            throw new Error("BattleSelectObject is null in BattleListPacketHandler.loadAllBattles");
         }

         Model.object = this.battleSelectObject;
         
         var _loc3_:Object = JSON.parse(param1.battlesJson);
         BattleSelectionTrace.recordFullSnapshot(this.extractBattleIds(_loc3_));
         _loc5_ = this.collectLiveBattleIds(_loc3_);
         TankTraceUtil.logBattleList("parsed battles=" + (_loc3_.battles == null ? -1 : _loc3_.battles.length));
         TankTraceUtil.logBattleListStale("loadAllBattles snapshot count=" + (_loc3_.battles == null ? -1 : _loc3_.battles.length) + " ids=" + this.getObjectKeys(_loc5_));
         this.ensureCreateDataFromBattleList(_loc3_);
         this.battleSelectModel.objectLoadedPost();
         TankTraceUtil.logBattleList("loadAllBattles after objectLoadedPost");
         this.removeStaleBattles(_loc5_);
         for each(var _loc2_ in _loc3_.battles)
         {
            try
            {
               TankTraceUtil.logBattleList("loadAllBattles add index=" + _loc4_);
               this.addBattle(_loc2_);
            }
            catch(e:Error)
            {
               TankTraceUtil.logBattleList("loadAllBattles ERROR add index=" + _loc4_ + " " + e.name + " " + e.message + " stack=" + e.getStackTrace());
            }
            _loc4_++;
         }
         TankTraceUtil.logBattleList("loadAllBattles before battleItemsPacketJoinSuccess count=" + _loc4_);
         this.battleSelectModel.battleItemsPacketJoinSuccess();
         TankTraceUtil.logBattleList("loadAllBattles after battleItemsPacketJoinSuccess");
         
         Model.popObject();
         //this.achievementService.setPanelPartition(2);
      }
      
      private function ensureCreateDataFromBattleList(param1:Object) : void
      {
         var _loc2_:Object = null;
         var _loc3_:* = null;
         var _loc4_:IGameObject = null;
         var _loc5_:MapInfoCC = null;
         var _loc6_:BattleCreateCC = null;
         var _loc7_:Object = null;
         var _loc8_:int = 0;
         if(param1 == null)
         {
            return;
         }
         if(param1.maps != null)
         {
            for each(_loc2_ in param1.maps)
            {
               _loc4_ = this.battleSelectSpace.getObject(Long.getLong(int(_loc2_.preview) * 1000,int(_loc2_.preview) * 1000));
               if(_loc4_ == null)
               {
                  _loc4_ = this.battleSelectSpace.createObject(Long.getLong(int(_loc2_.preview) * 1000,int(_loc2_.preview) * 1000),this.mapGameClass,String(_loc2_.mapId) + String(_loc2_.theme));
                  _loc5_ = new MapInfoCC();
                  _loc5_.additionalCrystalsPercent = _loc2_.additionalCrystalsPercent;
                  _loc5_.enabled = _loc2_.enabled;
                  _loc5_.mapId = String(_loc2_.mapId);
                  _loc5_.mapName = String(_loc2_.mapName);
                  _loc5_.maxPeople = int(_loc2_.maxPeople);
                  _loc5_.preview = ImageResource(resourceRegistry.getResource(Long.getLong(0,int(_loc2_.preview))));
                  _loc5_.rankLimit = new Range(int(_loc2_.maxRank),int(_loc2_.minRank));
                  _loc5_.supportedModes = new Vector.<BattleMode>();
                  for each(_loc3_ in _loc2_.supportedModes)
                  {
                     _loc5_.supportedModes.push(EnumUtils.stringToBattleMode(String(_loc3_)));
                  }
                  _loc5_.theme = EnumUtils.stringToMapTheme(String(_loc2_.theme));
                  _loc5_.defaultTheme = _loc5_.theme;
                  Model.object = _loc4_;
                  this.mapInfoModel.putInitParams(_loc5_);
                  this.mapInfoModel.objectLoaded();
                  Model.popObject();
               }
            }
         }
         if(param1.battleLimits == null && param1.maxRangeLength == null)
         {
            return;
         }
         _loc6_ = new BattleCreateCC();
         _loc6_.battleCreationDisabled = Boolean(param1.battleCreationDisabled);
         _loc6_.battlesLimits = new Vector.<BattleLimits>();
         if(param1.battleLimits != null)
         {
            for each(_loc7_ in param1.battleLimits)
            {
               _loc6_.battlesLimits.push(new BattleLimits(int(_loc7_.scoreLimit),int(_loc7_.timeLimitInSec)));
            }
         }
         while(_loc6_.battlesLimits.length < BattleMode.values.length)
         {
            _loc6_.battlesLimits.push(new BattleLimits(999,1800));
         }
         _loc6_.maxRangeLength = param1.maxRangeLength == null ? 31 : int(param1.maxRangeLength);
         _loc8_ = Math.max(1,_loc6_.maxRangeLength);
         _loc6_.maxRange = new Range(31,1);
         _loc6_.defaultRange = new Range(Math.min(_loc8_,31),1);
         _loc6_.ultimatesEnabled = true;
         Model.object = this.battleSelectObject;
         this.battleCreateModel.putInitParams(_loc6_);
         this.battleCreateModel.objectLoaded();
         this.battleCreateModel.objectLoadedPost();
         Model.popObject();
         TankTraceUtil.logCreateBattle("BattleListPacketHandler.ensureCreateData maps=" + MapInfoModel.getMaps().length + " limits=" + _loc6_.battlesLimits.length);
      }
      
      private function selectBattle(param1:SelectBattleInOutPacket) : void
      {
         var battleGameObject:IGameObject = this.battleSelectSpace.getObjectByName(param1.battleId);
         BattleSelectionTrace.acknowledge(param1.battleId,battleGameObject);
         BattleSelectionTrace.record("OBJECT_RESOLVE","BattleListPacketHandler.selectBattle",param1.battleId,battleGameObject,"lookup=exact");
         TankTraceUtil.logBattleListStale("selectBattle response battleId=" + param1.battleId + " exists=" + (battleGameObject != null));
         if(battleGameObject == null)
         {
            var resolveError:Error = new Error("Battle object not found in BattleListPacketHandler.selectBattle: " + param1.battleId);
            BattleSelectionTrace.record("SELECTION_REJECTED","BattleListPacketHandler.selectBattle",param1.battleId,null,"reason=battle_object_not_found");
            BattleSelectionTrace.error("selectBattle","BattleListPacketHandler",param1.battleId,null,resolveError);
            throw resolveError;
         }

         var _loc2_:IGameObject = this.battleSelectSpace.getObjectByName("BattleSelectObject");
         BattleSelectionTrace.record("OBJECT_RESOLVE","BattleListPacketHandler.selectBattleModelObject","BattleSelectObject",_loc2_,"lookup=exact");
         try
         {
            Model.object = _loc2_;
            this.battleSelectModel.select(battleGameObject);
            Model.popObject();
         }
         catch(e:Error)
         {
            BattleSelectionTrace.error("selectBattleModel","BattleListPacketHandler",param1.battleId,battleGameObject,e);
            throw e;
         }
      }
      
      private function createBattle(param1:BattleCreatedInPacket) : void
      {
         var battleData:Object = JSON.parse(param1.battlesJson);
         if(battleData != null && battleData.battleId != undefined && battleData.battleId != null)
         {
            BattleSelectionTrace.recordBattleCreated(String(battleData.battleId));
         }
         this.addBattle(battleData);
      }
      
      private function removeBattle(param1:RemoveBattleInPacket) : void
      {
         BattleSelectionTrace.recordBattleRemoved(param1.battleId);
         var _loc2_:IGameObject = this.battleSelectSpace.getObjectByName(param1.battleId);
         var _loc3_:String = this.trimBattleId(param1.battleId);
         var _loc4_:IGameObject = _loc3_ == param1.battleId ? null : this.battleSelectSpace.getObjectByName(_loc3_);
         TankTraceUtil.logBattleListStale("removeBattle packet id=" + param1.battleId + " exactExists=" + (_loc2_ != null) + " trimmed=" + _loc3_ + " trimmedExists=" + (_loc4_ != null));
         if(_loc2_ == null)
         {
            TankTraceUtil.logBattleList("removeBattle ignored missing id=" + param1.battleId);
            return;
         }
         if(_loc2_ != null)
         {
            platform.client.fp10.core.model.impl.Model.object = _loc2_;
            this.battleSelectSpace.destroyObject(_loc2_.id);
            Model.popObject();
         }
      }
      
      private function collectLiveBattleIds(param1:Object) : Object
      {
         var _loc3_:Object = null;
         var _loc2_:Object = {};
         if(param1 == null || param1.battles == null)
         {
            return _loc2_;
         }
         for each(_loc3_ in param1.battles)
         {
            if(_loc3_ != null && _loc3_.battleId != undefined && _loc3_.battleId != null)
            {
               _loc2_[String(_loc3_.battleId)] = true;
            }
         }
         return _loc2_;
      }

      private function extractBattleIds(param1:Object) : Array
      {
         var battle:Object = null;
         var ids:Array = [];
         if(param1 == null || param1.battles == null)
         {
            return ids;
         }
         for each(battle in param1.battles)
         {
            if(battle != null && battle.battleId != undefined && battle.battleId != null)
            {
               ids.push(String(battle.battleId));
            }
         }
         return ids;
      }
      
      private function removeStaleBattles(param1:Object) : void
      {
         var _loc2_:IGameObject = null;
         var _loc3_:Vector.<IGameObject> = new Vector.<IGameObject>();
         for each(_loc2_ in this.battleSelectSpace.objects)
         {
            if(this.isBattleInfoObject(_loc2_) && !Boolean(param1[_loc2_.name]))
            {
               _loc3_.push(_loc2_);
            }
         }
         for each(_loc2_ in _loc3_)
         {
            TankTraceUtil.logBattleList("removeStaleBattle id=" + _loc2_.name);
            this.battleSelectSpace.destroyObject(_loc2_.id);
         }
      }
      
      private function isBattleInfoObject(param1:IGameObject) : Boolean
      {
         return param1 != null && (param1.gameClass == dmBattleInfoGameClass || param1.gameClass == teamBattleInfoGameClass);
      }

      private function addBattle(battleData:Object) : void
      {
         TankTraceUtil.logBattleList("addBattle id=" + battleData.battleId + " mode=" + battleData.battleMode + " name=" + battleData.name);
         TankTraceUtil.logBattleListStale("addBattleFromSnapshot id=" + battleData.battleId + " mode=" + battleData.battleMode + " name=" + battleData.name);
         var battleInfoGameClass:IGameClass = dmBattleInfoGameClass;
         if(battleData.battleMode != "DM")
         {
            battleInfoGameClass = teamBattleInfoGameClass;
         }

         if(this.battleSelectSpace.getObjectByName(battleData.battleId) != null)
         {
            this.battleSelectSpace.destroyObject(this.battleSelectSpace.getObjectByName(battleData.battleId).id);
         }

         var battleGameObject:IGameObject = this.battleSelectSpace.createObject(IdTool.getNextId(), battleInfoGameClass, battleData.battleId);
         BattleSelectionTrace.recordBattleObjectCreated(String(battleData.battleId));
         TankTraceUtil.logBattleList("addBattle createdObject id=" + battleGameObject.id + " name=" + battleGameObject.name);
         
         var battleParamInfoCC:BattleParamInfoCC = new BattleParamInfoCC();
         var mapObjectId:Long = Long.getLong(battleData.preview * 1000, battleData.preview * 1000);
         battleParamInfoCC.map = this.battleSelectSpace.getObject(mapObjectId);
         TankTraceUtil.logBattleList("addBattle map preview=" + battleData.preview + " mapNull=" + (battleParamInfoCC.map == null));
         if(battleParamInfoCC.map == null)
         {
            battleParamInfoCC.map = this.createFallbackMapObject(battleData,mapObjectId);
         }
         battleParamInfoCC.params = new BattleCreateParameters();
         battleParamInfoCC.params.battleId = battleData.battleId;
         battleParamInfoCC.params.battleMode = EnumUtils.stringToBattleMode(battleData.battleMode);
         battleParamInfoCC.params.maxPeopleCount = battleData.maxPeople;
         battleParamInfoCC.params.mapId = this.getBattleDataString(battleData,"mapName",this.getBattleDataString(battleData,"mapId",this.getBattleDataString(battleData,"map",String(battleData.preview))));
         battleParamInfoCC.params.name = battleData.name;
         battleParamInfoCC.params.privateBattle = battleData.privateBattle;
         battleParamInfoCC.params.proBattle = battleData.proBattle;
         battleParamInfoCC.params.rankRange = new Range(battleData.maxRank,battleData.minRank);
         battleParamInfoCC.params.equipmentConstraintsMode = EnumUtils.stringToEquipmentConstraintsMode(battleData.equipmentConstraintsMode);
         battleParamInfoCC.params.parkourMode = battleData.parkourMode;
         battleParamInfoCC.params.limits = new BattleLimits();

         // Load BattleParamInfoModel
         Model.object = battleGameObject;
         this.battleParamsInfoModel.putInitParams(battleParamInfoCC);
         Model.popObject();
         TankTraceUtil.logBattleList("addBattle paramInfoLoaded id=" + battleData.battleId);

         var battleInfoCC:BattleInfoCC = new BattleInfoCC();
         battleInfoCC.roundStarted = true;
         battleInfoCC.suspicionLevel = EnumUtils.stringToBattleSuspicionLevel(battleData.suspicionLevel);
         battleInfoCC.timeLeftInSec = 0;

         // Load BattleInfoModel
         Model.object = battleGameObject;
         this.battleInfoModel.putInitParams(battleInfoCC);
         Model.popObject();
         TankTraceUtil.logBattleList("addBattle battleInfoLoaded id=" + battleData.battleId);

         if (battleData.battleMode == "DM")
         {
            var battleDMInfoCC:BattleDMInfoCC = new BattleDMInfoCC();
            battleDMInfoCC.users = new Vector.<BattleInfoUser>();
            TankTraceUtil.logBattleList("addBattle DM users=" + (battleData.users == null ? -1 : battleData.users.length));

            for each (var userName:String in battleData.users)
            {
               var user:BattleInfoUser = new BattleInfoUser();
               user.user = userName;
               battleDMInfoCC.users.push(user);
            }

            // Load BattleDMInfoModel
            Model.object = battleGameObject;
            this.battleInfoDmModel.putInitParams(battleDMInfoCC);
            this.battleInfoDmModel.objectLoaded();
            Model.popObject();
            TankTraceUtil.logBattleList("addBattle dmModelLoaded id=" + battleData.battleId);
         } else 
         {
            var teamBattleInfoCC:TeamBattleInfoCC = new TeamBattleInfoCC();
            teamBattleInfoCC.usersBlue = new Vector.<BattleInfoUser>();
            teamBattleInfoCC.usersRed = new Vector.<BattleInfoUser>();
            TankTraceUtil.logBattleList("addBattle TEAM red=" + (battleData.usersRed == null ? -1 : battleData.usersRed.length) + " blue=" + (battleData.usersBlue == null ? -1 : battleData.usersBlue.length));

            for each (userName in battleData.usersBlue)
            {
               user = new BattleInfoUser();
               user.user = userName;
               teamBattleInfoCC.usersBlue.push(user);
            }

            for each (userName in battleData.usersRed)
            {
               user = new BattleInfoUser();
               user.user = userName;
               teamBattleInfoCC.usersRed.push(user);
            }

            // Load TeamBattleInfoModel
            Model.object = battleGameObject;
            this.battleTeamInfoModel.putInitParams(teamBattleInfoCC);
            this.battleTeamInfoModel.objectLoaded();
            Model.popObject();
            TankTraceUtil.logBattleList("addBattle teamModelLoaded id=" + battleData.battleId);
         }
      }

      private function createFallbackMapObject(battleData:Object, mapObjectId:Long) : IGameObject
      {
         var supportedModes:Vector.<BattleMode> = new Vector.<BattleMode>();
         supportedModes.push(EnumUtils.stringToBattleMode(battleData.battleMode));

         var mapInfoCC:MapInfoCC = new MapInfoCC();
         mapInfoCC.enabled = true;
         mapInfoCC.mapId = this.getBattleDataString(battleData,"mapId",this.getBattleDataString(battleData,"map",String(battleData.preview)));
         mapInfoCC.mapName = this.getFallbackMapName(battleData,mapInfoCC.mapId);
         mapInfoCC.maxPeople = battleData.maxPeople;
         mapInfoCC.preview = ImageResource(resourceRegistry.getResource(Long.getLong(0,battleData.preview)));
         mapInfoCC.rankLimit = new Range(battleData.maxRank,battleData.minRank);
         mapInfoCC.supportedModes = supportedModes;
         if(battleData.theme != undefined)
         {
            mapInfoCC.theme = EnumUtils.stringToMapTheme(battleData.theme);
            mapInfoCC.defaultTheme = mapInfoCC.theme;
         }

         var mapObject:IGameObject = this.battleSelectSpace.createObject(mapObjectId,this.mapGameClass,mapInfoCC.mapId + (mapInfoCC.theme == null ? "" : mapInfoCC.theme.toString()));
         Model.object = mapObject;
         this.mapInfoModel.putInitParams(mapInfoCC);
         this.mapInfoModel.objectLoaded();
         Model.popObject();
         TankTraceUtil.logBattleList("createdFallbackMap preview=" + battleData.preview + " mapId=" + mapInfoCC.mapId + " mapName=" + mapInfoCC.mapName + " keys=" + this.getObjectKeys(battleData));
         return mapObject;
      }

      private function getFallbackMapName(battleData:Object, mapId:String) : String
      {
         var mapName:String = this.getBattleDataString(battleData,"mapName",null);
         if(mapName == null || mapName == "")
         {
            mapName = BattleCreatePacketHandler.getKnownMapName(mapId,String(battleData.preview));
         }
         return mapName == null ? "" : mapName;
      }

      private function getBattleDataString(param1:Object, param2:String, param3:String) : String
      {
         if(param1[param2] == undefined || param1[param2] == null)
         {
            return param3;
         }
         return String(param1[param2]);
      }

      private function getObjectKeys(param1:Object) : String
      {
         var _loc3_:String = null;
         var _loc2_:Array = [];
         for(_loc3_ in param1)
         {
            _loc2_.push(_loc3_);
         }
         return _loc2_.join(",");
      }

      private function trimBattleId(param1:String) : String
      {
         if(param1 == null)
         {
            return null;
         }
         return param1.replace(/^\s+|\s+$/g,"");
      }
      
      private function unloadAllBattles() : void
      {
         BattleSelectionTrace.clearBattleSet("BattleListPacketHandler.unloadAllBattles");
         TankTraceUtil.logBattleList("unloadAllBattles start");
         var battleSelectObject:IGameObject = this.battleSelectSpace.getObject(SpaceAndGameObjectIds.BATTLE_SELECT_OBJECT_ID);
         if(battleSelectObject != null)
         {
            Model.object = battleSelectObject;
            try
            {
               this.battleSelectModel.objectUnloaded();
            }
            catch(e:Error)
            {
               TankTraceUtil.logBattleList("unloadAllBattles ERROR objectUnloaded " + e.name + " " + e.message + " stack=" + e.getStackTrace());
            }
            Model.popObject();
         }
         else
         {
            TankTraceUtil.logBattleList("unloadAllBattles battleSelectObjectNull");
         }
         var _loc1_:Vector.<IGameObject> = new Vector.<IGameObject>();
         for each(var _loc3_ in this.battleSelectSpace.objects)
         {
            _loc1_.push(_loc3_);
         }
         _loc1_.reverse();
         for each(_loc3_ in _loc1_)
         {
            this.battleSelectSpace.destroyObject(_loc3_.id);
         }
         TankTraceUtil.logBattleList("unloadAllBattles end destroyed=" + _loc1_.length);
      }
   }
}
