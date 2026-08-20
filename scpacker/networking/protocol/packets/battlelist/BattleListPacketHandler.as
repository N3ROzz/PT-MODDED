package scpacker.networking.protocol.packets.battlelist
{
   import alternativa.tanks.model.battleselect.BattleSelectModel;
   import alternativa.tanks.model.item.BattleItemModel;
   import alternativa.tanks.model.item.dm.BattleDMItemModel;
   import alternativa.tanks.model.item.team.BattleTeamItemModel;
   import alternativa.types.Long;
   import platform.client.fp10.core.model.impl.Model;
   import platform.client.fp10.core.type.IGameClass;
   import platform.client.fp10.core.type.IGameObject;
   import platform.client.fp10.core.type.ISpace;
   import projects.tanks.client.battleselect.model.battleselect.BattleSelectModelBase;
   import projects.tanks.client.battleselect.model.item.BattleItemCC;
   import projects.tanks.client.battleselect.model.item.BattleSuspicionLevel;
   import projects.tanks.client.battleselect.model.item.BattleItemModelBase;
   import projects.tanks.client.battleselect.model.item.dm.BattleDMItemCC;
   import projects.tanks.client.battleselect.model.item.dm.BattleDMItemModelBase;
   import projects.tanks.client.battleselect.model.item.team.BattleTeamItemCC;
   import projects.tanks.client.battleselect.model.item.team.BattleTeamItemModelBase;
   import projects.tanks.client.battleservice.Range;
   import scpacker.SpaceAndGameObjectIds;
   import scpacker.networking.protocol.AbstractPacket;
   import scpacker.networking.protocol.AbstractPacketHandler;
   import scpacker.utils.EnumUtils;
   import scpacker.utils.IdTool;

   public class BattleListPacketHandler extends AbstractPacketHandler
   {
      public static var dmBattleListGameClass:IGameClass;
      public static var teamBattleListGameClass:IGameClass;
      public static var dmBattleInfoGameClass:IGameClass;
      public static var teamBattleInfoGameClass:IGameClass;

      private var battleSelectModel:BattleSelectModel;
      private var battleItemModel:BattleItemModel;
      private var battleDMItemModel:BattleDMItemModel;
      private var battleTeamItemModel:BattleTeamItemModel;
      private var battleSelectSpace:ISpace;
      private var battleInfoSpace:ISpace;
      private var battleSelectObject:IGameObject;

      public function BattleListPacketHandler()
      {
         super();
         this.id = 31;
         this.battleSelectModel = BattleSelectModel(modelRegistry.getModel(BattleSelectModelBase.modelId));
         this.battleItemModel = BattleItemModel(modelRegistry.getModel(BattleItemModelBase.modelId));
         this.battleDMItemModel = BattleDMItemModel(modelRegistry.getModel(BattleDMItemModelBase.modelId));
         this.battleTeamItemModel = BattleTeamItemModel(modelRegistry.getModel(BattleTeamItemModelBase.modelId));

         var _loc1_:Vector.<Long> = new Vector.<Long>();
         _loc1_.push(BattleItemModelBase.modelId);
         _loc1_.push(BattleDMItemModelBase.modelId);
         dmBattleListGameClass = gameTypeRegistry.createClass(Long.getLong(5823623,5812059),_loc1_);

         _loc1_ = new Vector.<Long>();
         _loc1_.push(BattleItemModelBase.modelId);
         _loc1_.push(BattleTeamItemModelBase.modelId);
         teamBattleListGameClass = gameTypeRegistry.createClass(Long.getLong(58236221,58120558),_loc1_);

         _loc1_ = new Vector.<Long>();
         _loc1_.push(Long.getLong(-792493736,-1341047415));
         _loc1_.push(Long.getLong(-2130078691,1389558371));
         _loc1_.push(Long.getLong(-1650234228,-1891188141));
         dmBattleInfoGameClass = gameTypeRegistry.createClass(Long.getLong(5823622,5812058),_loc1_);

         _loc1_ = new Vector.<Long>();
         _loc1_.push(Long.getLong(-792493736,-1341047415));
         _loc1_.push(Long.getLong(-1459499568,-1422309214));
         _loc1_.push(Long.getLong(-1650234228,-1891188141));
         teamBattleInfoGameClass = gameTypeRegistry.createClass(Long.getLong(58236223,58120559),_loc1_);

         this.battleSelectSpace = spaceRegistry.getSpace(SpaceAndGameObjectIds.BATTLE_SELECT_SPACE_ID);
         this.battleInfoSpace = spaceRegistry.getSpace(SpaceAndGameObjectIds.BATTLE_INFO_SPACE_ID);
      }

      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case BattleCreatedInPacket.id:
               this.addBattle(JSON.parse(BattleCreatedInPacket(param1).battlesJson));
               break;
            case LoadAllBattlesInPacket.id:
               this.loadAllBattles(LoadAllBattlesInPacket(param1));
               break;
            case RemoveBattleInPacket.id:
               this.removeBattle(RemoveBattleInPacket(param1));
               break;
            case SelectBattleInOutPacket.id:
               this.selectBattle(SelectBattleInOutPacket(param1));
               break;
            case UnloadBattleSelectSpaceInPacket.id:
               this.unloadAllBattles();
         }
      }

      private function loadAllBattles(param1:LoadAllBattlesInPacket) : void
      {
         var _loc1_:Object = JSON.parse(param1.battlesJson);
         var _loc2_:Object = this.collectBattleIds(_loc1_);
         this.battleSelectObject = this.battleSelectSpace.getObject(SpaceAndGameObjectIds.BATTLE_SELECT_OBJECT_ID);
         if(this.battleSelectObject == null)
         {
            throw new Error("BattleSelectObject is missing");
         }
         Model.object = this.battleSelectObject;
         try
         {
            this.battleSelectModel.objectLoadedPost();
            this.removeStaleBattles(_loc2_);
            if(_loc1_ != null && _loc1_.battles != null)
            {
               for each(var _loc3_:Object in _loc1_.battles)
               {
                  this.addBattle(_loc3_);
               }
            }
            this.battleSelectModel.battleItemsPacketJoinSuccess();
         }
         finally
         {
            Model.popObject();
         }
      }

      private function collectBattleIds(param1:Object) : Object
      {
         var _loc1_:Object = {};
         if(param1 == null || param1.battles == null)
         {
            return _loc1_;
         }
         for each(var _loc2_:Object in param1.battles)
         {
            if(_loc2_ != null && _loc2_.battleId != null && String(_loc2_.battleId) != "")
            {
               _loc1_[String(_loc2_.battleId)] = true;
            }
         }
         return _loc1_;
      }

      private function removeStaleBattles(param1:Object) : void
      {
         var _loc1_:Vector.<IGameObject> = new Vector.<IGameObject>();
         for each(var _loc2_:IGameObject in this.battleSelectSpace.objects)
         {
            if(this.isBattleListObject(_loc2_) && !param1.hasOwnProperty(_loc2_.name))
            {
               _loc1_.push(_loc2_);
            }
         }
         for each(_loc2_ in _loc1_)
         {
            this.battleSelectSpace.destroyObject(_loc2_.id);
            this.destroyBattleInfo(_loc2_.name);
         }
      }

      private function isBattleListObject(param1:IGameObject) : Boolean
      {
         return param1 != null && (param1.gameClass == dmBattleListGameClass || param1.gameClass == teamBattleListGameClass);
      }

      private function destroyBattleInfo(param1:String) : void
      {
         var _loc1_:Vector.<IGameObject> = this.snapshot(this.battleInfoSpace);
         for each(var _loc2_:IGameObject in _loc1_)
         {
            if(_loc2_.name == param1)
            {
               this.battleInfoSpace.destroyObject(_loc2_.id);
            }
         }
      }

      private function addBattle(param1:Object) : void
      {
         var _loc1_:IGameObject = this.battleSelectSpace.getObjectByName(String(param1.battleId));
         if(_loc1_ != null)
         {
            this.battleSelectSpace.destroyObject(_loc1_.id);
         }

         var _loc2_:Boolean = String(param1.battleMode) == "DM";
         var _loc3_:IGameObject = this.battleSelectSpace.createObject(IdTool.getNextId(),_loc2_ ? dmBattleListGameClass : teamBattleListGameClass,String(param1.battleId));
         var _loc4_:BattleItemCC = new BattleItemCC();
         _loc4_.battleId = String(param1.battleId);
         _loc4_.battleMode = EnumUtils.stringToBattleMode(String(param1.battleMode));
         _loc4_.equipmentConstraintsMode = EnumUtils.stringToEquipmentConstraintsMode(String(param1.equipmentConstraintsMode));
         _loc4_.map = this.battleSelectSpace.getObject(Long.getLong(int(param1.preview) * 1000,int(param1.preview) * 1000));
         if(_loc4_.map == null)
         {
            trace("[BATTLE_LIST] event=MAP_RESOLUTION_FAILED battleId=" + _loc4_.battleId + " preview=" + param1.preview);
         }
         _loc4_.maxPeople = int(param1.maxPeople);
         _loc4_.name = String(param1.name);
         _loc4_.parkourMode = Boolean(param1.parkourMode);
         _loc4_.privateBattle = Boolean(param1.privateBattle);
         _loc4_.proBattle = Boolean(param1.proBattle);
         _loc4_.rankRange = new Range(int(param1.maxRank),int(param1.minRank));
         _loc4_.suspicionLevel = this.toBattleItemSuspicion(String(param1.suspicionLevel));

         Model.object = _loc3_;
         try
         {
            this.battleItemModel.putInitParams(_loc4_);
            if(_loc2_)
            {
               var _loc5_:BattleDMItemCC = new BattleDMItemCC(new Vector.<String>());
               if(param1.users != null)
               {
                  for each(var _loc6_:String in param1.users)
                  {
                     _loc5_.users.push(_loc6_);
                  }
               }
               this.battleDMItemModel.putInitParams(_loc5_);
               this.battleDMItemModel.objectLoaded();
            }
            else
            {
               var _loc7_:BattleTeamItemCC = new BattleTeamItemCC(new Vector.<String>(),new Vector.<String>());
               if(param1.usersBlue != null)
               {
                  for each(_loc6_ in param1.usersBlue)
                  {
                     _loc7_.usersBlue.push(_loc6_);
                  }
               }
               if(param1.usersRed != null)
               {
                  for each(_loc6_ in param1.usersRed)
                  {
                     _loc7_.usersRed.push(_loc6_);
                  }
               }
               this.battleTeamItemModel.putInitParams(_loc7_);
               this.battleTeamItemModel.objectLoaded();
            }
            this.battleItemModel.objectLoadedPost();
         }
         finally
         {
            Model.popObject();
         }
      }

      private function removeBattle(param1:RemoveBattleInPacket) : void
      {
         var _loc1_:IGameObject = this.battleSelectSpace.getObjectByName(param1.battleId);
         if(_loc1_ != null)
         {
            Model.object = _loc1_;
            try
            {
               this.battleSelectSpace.destroyObject(_loc1_.id);
            }
            finally
            {
               Model.popObject();
            }
         }
      }

      private function toBattleItemSuspicion(param1:String) : BattleSuspicionLevel
      {
         if(param1 == "HIGH")
         {
            return BattleSuspicionLevel.HIGH;
         }
         if(param1 == "LOW")
         {
            return BattleSuspicionLevel.LOW;
         }
         return BattleSuspicionLevel.NONE;
      }

      private function selectBattle(param1:SelectBattleInOutPacket) : void
      {
         var _loc1_:IGameObject = this.battleSelectSpace.getObject(SpaceAndGameObjectIds.BATTLE_SELECT_OBJECT_ID);
         if(_loc1_ == null)
         {
            return;
         }
         Model.object = _loc1_;
         try
         {
            this.battleSelectModel.select(param1.battleId);
         }
         finally
         {
            Model.popObject();
         }
      }

      private function unloadAllBattles() : void
      {
         var _loc1_:Vector.<IGameObject> = this.snapshot(this.battleSelectSpace);
         _loc1_.reverse();
         this.destroyObjects(this.battleSelectSpace,_loc1_);
         this.destroyObjects(this.battleInfoSpace,this.snapshot(this.battleInfoSpace));
      }

      private function snapshot(param1:ISpace) : Vector.<IGameObject>
      {
         var _loc1_:Vector.<IGameObject> = new Vector.<IGameObject>();
         for each(var _loc2_:IGameObject in param1.objects)
         {
            _loc1_.push(_loc2_);
         }
         return _loc1_;
      }

      private function destroyObjects(param1:ISpace, param2:Vector.<IGameObject>) : void
      {
         for each(var _loc1_:IGameObject in param2)
         {
            param1.destroyObject(_loc1_.id);
         }
      }
   }
}
