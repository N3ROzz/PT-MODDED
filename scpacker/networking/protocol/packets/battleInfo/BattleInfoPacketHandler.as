package scpacker.networking.protocol.packets.battleInfo
{
   import alternativa.tanks.model.battle.BattleEntranceModel;
   import alternativa.tanks.model.info.BattleInfoModel;
   import alternativa.tanks.model.info.dm.BattleDmInfoModel;
   import alternativa.tanks.model.info.team.BattleTeamInfoModel;
   import alternativa.types.Long;
   import platform.client.fp10.core.model.impl.Model;
   import platform.client.fp10.core.type.IGameClass;
   import platform.client.fp10.core.type.IGameObject;
   import platform.client.fp10.core.type.ISpace;
   import projects.tanks.client.battleselect.model.battle.BattleInfoCC;
   import projects.tanks.client.battleselect.model.battle.BattleInfoModelBase;
   import projects.tanks.client.battleselect.model.battle.dm.BattleDMInfoCC;
   import projects.tanks.client.battleselect.model.battle.dm.BattleDMInfoModelBase;
   import projects.tanks.client.battleselect.model.battle.entrance.BattleEntranceCC;
   import projects.tanks.client.battleselect.model.battle.entrance.BattleEntranceModelBase;
   import projects.tanks.client.battleselect.model.battle.entrance.user.BattleInfoUser;
   import projects.tanks.client.battleselect.model.battle.team.TeamBattleInfoCC;
   import projects.tanks.client.battleselect.model.battle.team.TeamBattleInfoModelBase;
   import projects.tanks.client.battleservice.BattleCreateParameters;
   import projects.tanks.client.battleservice.Range;
   import projects.tanks.client.battleservice.model.createparams.BattleLimits;
   import projects.tanks.client.battleservice.model.types.BattleSuspicionLevel;
   import scpacker.SpaceAndGameObjectIds;
   import scpacker.networking.protocol.AbstractPacket;
   import scpacker.networking.protocol.AbstractPacketHandler;
   import scpacker.networking.protocol.packets.battlelist.BattleListPacketHandler;
   import scpacker.utils.EnumUtils;
   import scpacker.utils.IdTool;
   import utils.RuntimeLifecycleDiagnostics;

   public class BattleInfoPacketHandler extends AbstractPacketHandler
   {
      private var battleInfoModel:BattleInfoModel;
      private var battleDmInfoModel:BattleDmInfoModel;
      private var teamBattleInfoModel:BattleTeamInfoModel;
      private var battleEntranceModel:BattleEntranceModel;
      private var battleSelectSpace:ISpace;
      private var battleInfoSpace:ISpace;

      public function BattleInfoPacketHandler()
      {
         super();
         this.id = 33;
         this.battleInfoModel = BattleInfoModel(modelRegistry.getModel(BattleInfoModelBase.modelId));
         this.battleDmInfoModel = BattleDmInfoModel(modelRegistry.getModel(BattleDMInfoModelBase.modelId));
         this.teamBattleInfoModel = BattleTeamInfoModel(modelRegistry.getModel(TeamBattleInfoModelBase.modelId));
         this.battleEntranceModel = BattleEntranceModel(modelRegistry.getModel(BattleEntranceModelBase.modelId));
         this.battleSelectSpace = spaceRegistry.getSpace(SpaceAndGameObjectIds.BATTLE_SELECT_SPACE_ID);
         this.battleInfoSpace = spaceRegistry.getSpace(SpaceAndGameObjectIds.BATTLE_INFO_SPACE_ID);
      }

      public function invoke(param1:AbstractPacket) : void
      {
         var _loc1_:int = param1.getId();
         RuntimeLifecycleDiagnostics.recordPreInitHandler("PREINIT_HANDLER_ENTER",_loc1_,this.id);
         switch(_loc1_)
         {
            case JoinedDmBattleInPacket.id:
               this.addUserDm(JoinedDmBattleInPacket(param1));
               break;
            case JoinedTeamBattleInPacket.id:
               this.addUserTeam(JoinedTeamBattleInPacket(param1));
               break;
            case BattleStoppedInPacket.id:
               this.battleStop(BattleStoppedInPacket(param1));
               break;
            case EquipmentNotMatchConstraintsInPacket.id:
               this.equipmentNotMatchConstraintsDm(EquipmentNotMatchConstraintsInPacket(param1).battleId);
               break;
            case EquipmentNotMatchTeamConstraintsInPacket.id:
               this.equipmentNotMatchConstraintsTeam(EquipmentNotMatchTeamConstraintsInPacket(param1).battleId);
               break;
            case FightFailedServerHaltingInPacket.id:
               this.fightFailedServerIsHalting(FightFailedServerHaltingInPacket(param1));
               break;
            case UnloadBattleInfoInPacket.id:
               this.unload(UnloadBattleInfoInPacket(param1));
               break;
            case LeftPacketInPacket.id:
               this.removeUser(LeftPacketInPacket(param1));
               break;
            case RoundFinishedInPacket.id:
               this.roundFinish(RoundFinishedInPacket(param1));
               break;
            case RoundStartedInPacket.id:
               this.roundStart(RoundStartedInPacket(param1));
               break;
            case LoadBattleInfoInPacket.id:
               this.loadBattleInfo(LoadBattleInfoInPacket(param1));
               break;
            case SwapTeamsInPacket.id:
               this.swapTeams(SwapTeamsInPacket(param1));
               break;
            case UpdateBattleNameInPacket.id:
               this.updateName(UpdateBattleNameInPacket(param1));
               break;
            case UpdateTeamScoreInPacket.id:
               this.updateTeamScore(UpdateTeamScoreInPacket(param1));
               break;
            case UpdatePlayerDmKillsInPacket.id:
               this.updateUserKills(UpdatePlayerDmKillsInPacket(param1));
               break;
            case UpdatePlayerTeamScoreInPacket.id:
               this.updateUserScore(UpdatePlayerTeamScoreInPacket(param1));
               break;
            case UpdatePlayerSuspiciousStateInPacket.id:
               this.updateUserSuspiciousState(UpdatePlayerSuspiciousStateInPacket(param1));
         }
         RuntimeLifecycleDiagnostics.recordPreInitHandler("PREINIT_HANDLER_EXIT",_loc1_,this.id);
      }

      private function withBattleInfo(param1:String, param2:Function) : void
      {
         var _loc1_:IGameObject = this.battleInfoSpace.getObjectByName(param1);
         Model.withObject(_loc1_,param2);
      }

      private function battleStop(param1:BattleStoppedInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            battleInfoModel.roundFinished();
         });
      }

      private function fightFailedServerIsHalting(param1:FightFailedServerHaltingInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            battleEntranceModel.fightFailedServerIsHalting();
         });
      }

      private function removeUser(param1:LeftPacketInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            if(Model.object.hasModel(BattleDmInfoModel))
            {
               battleDmInfoModel.removeUser(param1.userId);
            }
            else
            {
               teamBattleInfoModel.removeUser(param1.userId);
            }
         });
      }

      private function roundFinish(param1:RoundFinishedInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            battleInfoModel.roundFinished();
         });
      }

      private function roundStart(param1:RoundStartedInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            battleInfoModel.roundStarted(5);
         });
      }

      private function updateName(param1:UpdateBattleNameInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            battleInfoModel.setBattleName(param1.battleName);
         });
      }

      private function updateUserSuspiciousState(param1:UpdatePlayerSuspiciousStateInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            battleInfoModel.updateUserSuspiciousState(param1.userId,param1.suspicious);
         });
      }

      private function updateUserKills(param1:UpdatePlayerDmKillsInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            battleDmInfoModel.updateUserScore(param1.userId,param1.kills);
         });
      }

      private function updateUserScore(param1:UpdatePlayerTeamScoreInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            teamBattleInfoModel.updateUserScore(param1.userId,param1.score);
         });
      }

      private function updateTeamScore(param1:UpdateTeamScoreInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            teamBattleInfoModel.updateTeamScore(param1.team,param1.score);
         });
      }

      private function addUserDm(param1:JoinedDmBattleInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            battleDmInfoModel.addUser(param1.userInfo);
         });
      }

      private function addUserTeam(param1:JoinedTeamBattleInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            teamBattleInfoModel.addUser(param1.userInfo,param1.team);
         });
      }

      private function swapTeams(param1:SwapTeamsInPacket) : void
      {
         this.withBattleInfo(param1.battleId,function():void
         {
            teamBattleInfoModel.swapTeams();
         });
      }

      private function equipmentNotMatchConstraintsDm(param1:String) : void
      {
         this.withBattleInfo(param1,function():void
         {
            battleDmInfoModel.equipmentNotMatchConstraints();
         });
      }

      private function equipmentNotMatchConstraintsTeam(param1:String) : void
      {
         this.withBattleInfo(param1,function():void
         {
            teamBattleInfoModel.equipmentNotMatchConstraints();
         });
      }

      private function loadBattleInfo(param1:LoadBattleInfoInPacket) : void
      {
         var _loc1_:Object = JSON.parse(param1.battlesJson);
         var _loc2_:IGameClass = _loc1_.battleMode == "DM" ? BattleListPacketHandler.dmBattleInfoGameClass : BattleListPacketHandler.teamBattleInfoGameClass;
         var _loc3_:IGameObject = this.battleInfoSpace.createObject(IdTool.getNextId(),_loc2_,String(_loc1_.itemId));
         var _loc4_:BattleCreateParameters = this.createBattleParameters(_loc1_);
         var _loc5_:BattleInfoCC = new BattleInfoCC();
         _loc5_.battleId = _loc4_.battleId;
         _loc5_.battleMode = _loc4_.battleMode;
         _loc5_.dependentCooldownEnabled = _loc4_.dependentCooldownEnabled;
         _loc5_.equipmentConstraintsMode = _loc4_.equipmentConstraintsMode;
         _loc5_.esportDropTiming = _loc4_.esportDropTiming;
         _loc5_.limits = _loc4_.limits;
         _loc5_.map = this.battleSelectSpace.getObject(Long.getLong(_loc1_.preview * 1000,_loc1_.preview * 1000));
         _loc5_.maxPeopleCount = _loc4_.maxPeopleCount;
         _loc5_.name = _loc4_.name;
         _loc5_.parkourMode = _loc4_.parkourMode;
         _loc5_.proBattle = _loc4_.proBattle;
         _loc5_.randomGold = _loc4_.randomGold;
         _loc5_.rankRange = _loc4_.rankRange;
         _loc5_.reArmorEnabled = _loc4_.reArmorEnabled;
         _loc5_.reducedResistance = _loc4_.reducedResistances;
         _loc5_.roundStarted = Boolean(_loc1_.roundStarted);
         _loc5_.spectator = Boolean(_loc1_.spectator);
         _loc5_.suspicionLevel = BattleSuspicionLevel.NONE;
         _loc5_.timeLeftInSec = int(_loc1_.timeLeftInSec);
         _loc5_.userPaidNoSuppliesBattle = Boolean(_loc1_.userPaidNoSuppliesBattle);
         _loc5_.withoutBonuses = _loc4_.withoutBonuses;
         _loc5_.withoutCrystals = _loc4_.withoutCrystals;
         _loc5_.withoutDrones = _loc4_.withoutDrones;
         _loc5_.withoutGoldBoxes = _loc4_.withoutGoldBoxes;
         _loc5_.withoutGoldSiren = _loc4_.withoutGoldSiren;
         _loc5_.withoutGoldZone = _loc4_.withoutGoldZone;
         _loc5_.withoutMedkit = _loc4_.withoutMedkit;
         _loc5_.withoutMines = _loc4_.withoutMines;
         _loc5_.withoutSupplies = _loc4_.withoutSupplies;
         _loc5_.withoutUpgrades = _loc4_.withoutUpgrades;

         var _loc6_:BattleEntranceCC = new BattleEntranceCC(int(_loc1_.proBattleEnterPrice),_loc1_.proBattleTimeLeftInSec == -1 ? 0 : int(_loc1_.proBattleTimeLeftInSec));
         Model.object = _loc3_;
         try
         {
            this.battleEntranceModel.putInitParams(_loc6_);
            this.battleEntranceModel.objectLoaded();
            this.battleInfoModel.putInitParams(_loc5_);
            this.battleInfoModel.objectLoaded();
            if(_loc1_.battleMode == "DM")
            {
               var _loc7_:BattleDMInfoCC = new BattleDMInfoCC();
               _loc7_.users = this.buildUsers(_loc1_.users);
               this.battleDmInfoModel.putInitParams(_loc7_);
               this.battleDmInfoModel.objectLoadedPost();
            }
            else
            {
               var _loc8_:TeamBattleInfoCC = new TeamBattleInfoCC();
               _loc8_.autoBalance = Boolean(_loc1_.autoBalance);
               _loc8_.friendlyFire = Boolean(_loc1_.friendlyFire);
               _loc8_.scoreBlue = this.getTeamScore(_loc1_,["scoreBlue","blueScore","score_blue","blue_score"]);
               _loc8_.scoreRed = this.getTeamScore(_loc1_,["scoreRed","redScore","score_red","red_score"]);
               _loc8_.usersBlue = this.buildUsers(_loc1_.usersBlue);
               _loc8_.usersRed = this.buildUsers(_loc1_.usersRed);
               this.teamBattleInfoModel.putInitParams(_loc8_);
               this.teamBattleInfoModel.objectLoadedPost();
            }
         }
         finally
         {
            Model.popObject();
         }
         RuntimeLifecycleDiagnostics.recordBattleInfo("BATTLE_INFO_LOAD_END","battleId=" + _loc1_.itemId + " mode=" + _loc1_.battleMode);
      }

      private function createBattleParameters(param1:Object) : BattleCreateParameters
      {
         var _loc1_:BattleCreateParameters = new BattleCreateParameters();
         _loc1_.battleId = String(param1.itemId);
         _loc1_.autoBalance = Boolean(param1.autoBalance);
         _loc1_.battleMode = EnumUtils.stringToBattleMode(param1.battleMode);
         _loc1_.equipmentConstraintsMode = EnumUtils.stringToEquipmentConstraintsMode(param1.equipmentConstraintsMode);
         _loc1_.friendlyFire = Boolean(param1.friendlyFire);
         _loc1_.limits = new BattleLimits(int(param1.scoreLimit),int(param1.timeLimitInSec));
         _loc1_.maxPeopleCount = int(param1.maxPeopleCount);
         _loc1_.name = String(param1.name);
         _loc1_.parkourMode = Boolean(param1.parkourMode);
         _loc1_.privateBattle = false;
         _loc1_.proBattle = Boolean(param1.proBattle);
         _loc1_.rankRange = new Range(int(param1.maxRank),int(param1.minRank));
         _loc1_.reArmorEnabled = Boolean(param1.reArmorEnabled);
         _loc1_.withoutBonuses = Boolean(param1.withoutBonuses);
         _loc1_.withoutCrystals = Boolean(param1.withoutCrystals);
         _loc1_.withoutDrones = true;
         _loc1_.withoutSupplies = Boolean(param1.withoutSupplies);
         _loc1_.withoutUpgrades = param1.withoutUpgrades != null && Boolean(param1.withoutUpgrades);
         _loc1_.reducedResistances = Boolean(param1.reducedResistance);
         _loc1_.esportDropTiming = Boolean(param1.esportDropTiming);
         _loc1_.withoutGoldBoxes = Boolean(param1.withoutGoldBoxes);
         _loc1_.withoutGoldSiren = Boolean(param1.withoutGoldSiren);
         _loc1_.withoutGoldZone = Boolean(param1.withoutGoldZone);
         _loc1_.randomGold = Boolean(param1.randomGold);
         _loc1_.withoutMedkit = Boolean(param1.withoutMedkit);
         _loc1_.withoutMines = Boolean(param1.withoutMines);
         _loc1_.dependentCooldownEnabled = Boolean(param1.dependentCooldownEnabled);
         return _loc1_;
      }

      private function buildUsers(param1:Array) : Vector.<BattleInfoUser>
      {
         var _loc1_:Vector.<BattleInfoUser> = new Vector.<BattleInfoUser>();
         if(param1 != null)
         {
            for each(var _loc2_:Object in param1)
            {
               _loc1_.push(this.buildBattleInfoUser(_loc2_));
            }
         }
         return _loc1_;
      }

      private function buildBattleInfoUser(param1:Object) : BattleInfoUser
      {
         var _loc1_:BattleInfoUser = new BattleInfoUser();
         _loc1_.user = param1.user;
         _loc1_.score = Math.max(param1.kills,param1.score);
         _loc1_.suspicious = param1.suspicious;
         return _loc1_;
      }

      private function getTeamScore(param1:Object, param2:Array) : int
      {
         for each(var _loc1_:String in param2)
         {
            if(param1.hasOwnProperty(_loc1_) && param1[_loc1_] != null)
            {
               return int(param1[_loc1_]);
            }
         }
         return 0;
      }

      private function unload(param1:UnloadBattleInfoInPacket) : void
      {
         var _loc1_:IGameObject = this.battleInfoSpace.getObjectByName(param1.battleId);
         if(_loc1_ != null)
         {
            Model.object = _loc1_;
            try
            {
               this.battleInfoSpace.destroyObject(_loc1_.id);
            }
            finally
            {
               Model.popObject();
            }
         }
      }
   }
}
