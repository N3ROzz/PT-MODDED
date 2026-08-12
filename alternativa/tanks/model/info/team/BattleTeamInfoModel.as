package alternativa.tanks.model.info.team
{
   import alternativa.tanks.controllers.BattleSelectVectorUtil;
   import alternativa.tanks.model.info.BattleParamsUtils;
   import alternativa.tanks.service.battle.IBattleUserInfoService;
   import alternativa.tanks.service.battleinfo.IBattleInfoFormService;
   import alternativa.tanks.service.battlelist.IBattleListFormService;
   import alternativa.tanks.view.battleinfo.BattleInfoBaseParams;
   import alternativa.tanks.view.battleinfo.team.BattleInfoTeamParams;
   import alternativa.types.Long;
   import platform.client.fp10.core.model.ObjectLoadPostListener;
   import platform.client.fp10.core.model.ObjectUnloadListener;
   import alternativa.tanks.view.battleinfo.BattleInfoViewEvent;
   import projects.tanks.client.battleselect.model.battle.entrance.user.BattleInfoUser;
   import projects.tanks.client.battleselect.model.battle.team.ITeamBattleInfoModelBase;
   import projects.tanks.client.battleselect.model.battle.team.TeamBattleInfoModelBase;
   import projects.tanks.client.battleservice.model.battle.team.BattleTeam;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.IFriendInfoService;
   import utils.BattleSelectionTrace;
   import alternativa.osgi.service.locale.ILocaleService;
   import alternativa.tanks.model.info.IBattleInfo;
   import alternativa.tanks.tracker.ITrackerService;
   import projects.tanks.client.battleservice.BattleCreateParameters;
   import projects.tanks.clients.fp10.libraries.TanksLocale;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.alertservices.IAlertService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.alertservices.AlertServiceEvent;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.logging.battlelist.UserBattleSelectActionsService;
   import utils.TankTraceUtil;
   
   [ModelInfo]
   public class BattleTeamInfoModel extends TeamBattleInfoModelBase implements ITeamBattleInfoModelBase, ObjectLoadPostListener, ObjectUnloadListener
   {
      
      [Inject] // added
      public static var battleListFormService:IBattleListFormService;
      
      [Inject] // added
      public static var friendsInfoService:IFriendInfoService;
      
      [Inject] // added
      public static var battleUserInfoService:IBattleUserInfoService;
      
      [Inject] // added
      public static var battleInfoFormService:IBattleInfoFormService;

      [Inject]
      public static var alertService:IAlertService;

      [Inject]
      public static var localeService:ILocaleService;

      [Inject]
      public static var trackerService:ITrackerService;

      [Inject]
      public static var userBattleSelectActionsService:UserBattleSelectActionsService;

      private var fightCommandFlag:ServerFightCommandAlreadySentFlag = new ServerFightCommandAlreadySentFlag();

      private var selectedTeam:BattleTeam;
      
      public function BattleTeamInfoModel()
      {
         super();
      }
      
      public function objectLoadedPost() : void
      {
         var _loc1_:BattleInfoTeamParams = null;
         _loc1_ = new BattleInfoTeamParams();
         putData(BattleInfoTeamParams,_loc1_);
         BattleParamsUtils.setBattleInfoParams(object,_loc1_);
         _loc1_.usersBlue = getInitParam().usersBlue.concat();
         _loc1_.usersRed = getInitParam().usersRed.concat();
         BattleParamsUtils.registerUsers(object,_loc1_.usersBlue,_loc1_);
         BattleParamsUtils.registerUsers(object,_loc1_.usersRed,_loc1_);
         _loc1_.scoreBlue = getInitParam().scoreBlue;
         _loc1_.scoreRed = getInitParam().scoreRed;
         battleInfoFormService.showTeamForm(this.data());
         battleInfoFormService.addEventListener(BattleInfoViewEvent.ENTER_BATTLE,getFunctionWrapper(this.onEnterBattle));
      }

      public function reloadCC() : void
      {
         var _loc1_:BattleInfoTeamParams = BattleInfoTeamParams(getData(BattleInfoTeamParams));
         var _loc2_:Vector.<BattleInfoUser> = getInitParam().usersBlue == null ? new Vector.<BattleInfoUser>() : getInitParam().usersBlue.concat();
         var _loc3_:Vector.<BattleInfoUser> = getInitParam().usersRed == null ? new Vector.<BattleInfoUser>() : getInitParam().usersRed.concat();
         var _loc4_:Vector.<BattleInfoUser> = _loc2_.concat(_loc3_);
         BattleParamsUtils.reconcileUsers(object,_loc4_,_loc1_);
         _loc1_.usersBlue = _loc2_;
         _loc1_.usersRed = _loc3_;
         BattleParamsUtils.setBattleInfoParams(object,_loc1_);
         _loc1_.scoreBlue = getInitParam().scoreBlue;
         _loc1_.scoreRed = getInitParam().scoreRed;
      }
     
      
      public function updateTeamScore(param1:BattleTeam, param2:int) : void
      {
         if(param1 == BattleTeam.RED)
         {
            this.data().scoreRed = param2;
         }
         else
         {
            this.data().scoreBlue = param2;
         }
         battleInfoFormService.updateTeamScore(param1,param2);
      }
      
      public function swapTeams() : void
      {
         var _loc1_:BattleInfoTeamParams = this.data();
         var _loc2_:Vector.<BattleInfoUser> = _loc1_.usersBlue;
         var _loc3_:Vector.<BattleInfoUser> = _loc1_.usersRed;
         _loc1_.usersRed = _loc2_;
         _loc1_.usersBlue = _loc3_;
         _loc1_.scoreBlue = _loc1_.scoreRed = 0;
         battleListFormService.swapTeams(object.name);
         battleInfoFormService.swapTeams();
      }
      
      public function addUser(param1:BattleInfoUser, param2:BattleTeam) : void
      {
         if(this.userExists(param1.user))
         {
            return;
         }
         var _loc3_:BattleInfoTeamParams = this.data();
         var _loc4_:Vector.<BattleInfoUser> = param2 == BattleTeam.RED ? _loc3_.usersRed : _loc3_.usersBlue;
         _loc4_.push(param1);
         BattleParamsUtils.registerUser(param1,_loc3_,object);
         battleInfoFormService.addUser(param1,param2);
         this.updateUsersCount();
      }
      
      public function removeUser(param1:String) : void
      {
         if(!this.userExists(param1))
         {
            return;
         }
         BattleSelectVectorUtil.deleteElementInUsersVector(this.data().usersBlue,param1);
         BattleSelectVectorUtil.deleteElementInUsersVector(this.data().usersRed,param1);
         BattleParamsUtils.unregisterUser(param1,this.data());
         this.updateUsersCount();
         battleInfoFormService.removeUser(param1);
      }
      
      public function updateUserScore(param1:String, param2:int) : void
      {
         var _loc3_:BattleInfoUser = this.data().userToInfo.get(param1);
         if(_loc3_ == null)
         {
            return;
         }
         _loc3_.score = param2;
         battleInfoFormService.updateUserScore(param1,param2);
      }
      
      private function data() : BattleInfoTeamParams
      {
         return BattleInfoTeamParams(getData(BattleInfoTeamParams));
      }
      
      private function updateUsersCount() : void
      {
         battleListFormService.updateUsersCount(object.name);
      }

      private function userExists(param1:String) : Boolean
      {
         return this.data().userToInfo.get(param1) != null;
      }

      private function onEnterBattle(param1:BattleInfoViewEvent) : void
      {
         var _loc1_:BattleCreateParameters = this.data().createParams;
         this.selectedTeam = param1.team;
         trackerService.trackEvent("battleList","StartTeamBattle","");
         userBattleSelectActionsService.enterToBattle(_loc1_.battleMode,object.name);
         if(_loc1_.parkourMode)
         {
            alertService.addEventListener(AlertServiceEvent.ALERT_BUTTON_PRESSED,getFunctionWrapper(this.onParkourAlertButtonPressed));
            alertService.showAlert(localeService.getText(TanksLocale.TEXT_BATTLE_ENTER_WARNING_PARKOUR),Vector.<String>([localeService.getText(TanksLocale.TEXT_BATTLE_ENTER_WARNING_PARKOUR_BUTTON_ENTER),localeService.getText(TanksLocale.TEXT_ALERT_ANSWER_CANCEL)]));
         }
         else
         {
            this.sendFight();
         }
      }

      private function onParkourAlertButtonPressed(param1:AlertServiceEvent) : void
      {
         alertService.removeEventListener(AlertServiceEvent.ALERT_BUTTON_PRESSED,getFunctionWrapper(this.onParkourAlertButtonPressed));
         if(param1.typeButton == localeService.getText(TanksLocale.TEXT_BATTLE_ENTER_WARNING_PARKOUR_BUTTON_ENTER))
         {
            this.sendFight();
         }
      }

      private function sendFight() : void
      {
         if(getData(ServerFightCommandAlreadySentFlag) == null)
         {
            putData(ServerFightCommandAlreadySentFlag,this.fightCommandFlag);
            TankTraceUtil.markBattleJoin(object.name);
            server.fight(this.selectedTeam);
         }
      }

      public function equipmentNotMatchConstraints() : void
      {
         clearData(ServerFightCommandAlreadySentFlag);
         alertService.showAlert(localeService.getText(TanksLocale.TEXT_BATTLE_ENTER_ERROR_EQUIPMENT_NOT_MATCH_CONSTRAINTS),Vector.<String>([localeService.getText(TanksLocale.TEXT_CLOSE_LABEL)]));
      }

      public function objectUnloaded() : void
      {
         battleInfoFormService.removeEventListener(BattleInfoViewEvent.ENTER_BATTLE,getFunctionWrapper(this.onEnterBattle));
         alertService.removeEventListener(AlertServiceEvent.ALERT_BUTTON_PRESSED,getFunctionWrapper(this.onParkourAlertButtonPressed));
      }
   }
}

class ServerFightCommandAlreadySentFlag
{
}
