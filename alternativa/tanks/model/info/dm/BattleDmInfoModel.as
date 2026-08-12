package alternativa.tanks.model.info.dm
{
   import alternativa.tanks.controllers.BattleSelectVectorUtil;
   import alternativa.tanks.model.info.BattleParamsUtils;
   import alternativa.tanks.service.battle.IBattleUserInfoService;
   import alternativa.tanks.service.battleinfo.IBattleInfoFormService;
   import alternativa.tanks.service.battlelist.IBattleListFormService;
   import alternativa.tanks.view.battleinfo.BattleInfoBaseParams;
   import alternativa.tanks.view.battleinfo.dm.BattleInfoDmParams;
   import alternativa.types.Long;
   import platform.client.fp10.core.model.ObjectLoadPostListener;
   import platform.client.fp10.core.model.ObjectUnloadListener;
   import alternativa.tanks.view.battleinfo.BattleInfoViewEvent;
   import projects.tanks.client.battleselect.model.battle.dm.BattleDMInfoModelBase;
   import projects.tanks.client.battleselect.model.battle.dm.IBattleDMInfoModelBase;
   import projects.tanks.client.battleselect.model.battle.entrance.user.BattleInfoUser;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.IFriendInfoService;
   import utils.BattleSelectionTrace;
   import alternativa.osgi.service.locale.ILocaleService;
   import alternativa.tanks.model.info.IBattleInfo;
   import alternativa.tanks.model.battle.BattleEntranceModel;
   import alternativa.tanks.tracker.ITrackerService;
   import projects.tanks.client.battleservice.BattleCreateParameters;
   import projects.tanks.clients.fp10.libraries.TanksLocale;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.alertservices.IAlertService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.alertservices.AlertServiceEvent;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.logging.battlelist.UserBattleSelectActionsService;
   import utils.TankTraceUtil;
   
   [ModelInfo]
   public class BattleDmInfoModel extends BattleDMInfoModelBase implements IBattleDMInfoModelBase, ObjectLoadPostListener, ObjectUnloadListener
   {
      
      [Inject] // added
      public static var battleListFormService:IBattleListFormService;
      
      [Inject] // added
      public static var friendsInfoService:IFriendInfoService;
      
      [Inject] // added
      public static var battleInfoFormService:IBattleInfoFormService;
      
      [Inject] // added
      public static var battleUserInfoService:IBattleUserInfoService;

      [Inject]
      public static var alertService:IAlertService;

      [Inject]
      public static var localeService:ILocaleService;

      [Inject]
      public static var trackerService:ITrackerService;

      [Inject]
      public static var userBattleSelectActionsService:UserBattleSelectActionsService;

      private var fightCommandFlag:ServerFightCommandAlreadySentFlag = new ServerFightCommandAlreadySentFlag();
      
      public function BattleDmInfoModel()
      {
         super();
      }
      
      public function removeUser(param1:String) : void
      {
         if(!this.userExists(param1))
         {
            return;
         }
         BattleSelectVectorUtil.deleteElementInUsersVector(this.data().users,param1);
         BattleParamsUtils.unregisterUser(param1,this.data());
         this.updateUsersCount();
         battleInfoFormService.removeUser(param1);
      }
      
      public function addUser(param1:BattleInfoUser) : void
      {
         if(this.userExists(param1.user))
         {
            return;
         }
         this.data().users.push(param1);
         BattleParamsUtils.registerUser(param1,this.data(),object);
         battleInfoFormService.addUser(param1);
         this.updateUsersCount();
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
      
      public function objectLoadedPost() : void
      {
         var _loc1_:BattleInfoDmParams = new BattleInfoDmParams();
         putData(BattleInfoDmParams,_loc1_);
         _loc1_.users = getInitParam().users.concat();
         BattleParamsUtils.setBattleInfoParams(object,_loc1_);
         BattleParamsUtils.registerUsers(object,_loc1_.users,_loc1_);
         battleInfoFormService.showDmForm(this.data());
         battleInfoFormService.addEventListener(BattleInfoViewEvent.ENTER_BATTLE,getFunctionWrapper(this.onEnterBattle));
      }
      
      public function reloadCC() : void
      {
         var _loc1_:BattleInfoDmParams = BattleInfoDmParams(getData(BattleInfoDmParams));
         var _loc2_:Vector.<BattleInfoUser> = getInitParam().users == null ? new Vector.<BattleInfoUser>() : getInitParam().users.concat();
         BattleParamsUtils.reconcileUsers(object,_loc2_,_loc1_);
         _loc1_.users = _loc2_;
         BattleParamsUtils.setBattleInfoParams(object,_loc1_);
      }
      
      private function data() : BattleInfoDmParams
      {
         return BattleInfoDmParams(getData(BattleInfoDmParams));
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
         trackerService.trackEvent("battleList","StartDMBattle","");
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
            server.fight();
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
