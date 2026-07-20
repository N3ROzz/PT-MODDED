package alternativa.tanks.model.userproperties
{
   import alternativa.osgi.service.display.IDisplay;
   import alternativa.tanks.gui.panel.MainPanel;
   import alternativa.tanks.gui.panel.PlayerInfo;
   import alternativa.tanks.service.money.IMoneyService;
   import alternativa.tanks.service.panel.IPanelView;
   import alternativa.tanks.service.panel.PanelInitedEvent;
   import alternativa.tanks.tracker.ITrackerService;
   import alternativa.types.Long;
   import controls.panel.UpdateRankNotice;
   import platform.client.fp10.core.model.ObjectLoadListener;
   import platform.client.fp10.core.model.ObjectLoadPostListener;
   import projects.tanks.client.panel.model.profile.userproperties.IUserPropertiesModelBase;
   import projects.tanks.client.panel.model.profile.userproperties.UserPropertiesModelBase;
   import projects.tanks.client.users.model.userbattlestatistics.rank.RankBounds;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.clan.ClanUserInfoEvent;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.clan.ClanUserInfoService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.helper.IHelpService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.user.IUserInfoLabelUpdater;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.user.IUserInfoService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.user.UserInfoLabelUpdaterEvent;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.userproperties.IUserPropertiesService;
   import utils.TankTraceUtil;
   
   [ModelInfo]
   public class UserPropertiesModel extends UserPropertiesModelBase implements IUserPropertiesModelBase, ObjectLoadListener, ObjectLoadPostListener, IUserProperties
   {
      
      [Inject] // added
      public static var panelView:IPanelView;
      
      [Inject] // added
      public static var display:IDisplay;
      
      [Inject] // added
      public static var helpService:IHelpService;
      
      [Inject] // added
      public static var userPropertiesService:IUserPropertiesService;
      
      [Inject] // added
      public static var moneyService:IMoneyService;
      
      [Inject] // added
      public static var trackerService:ITrackerService;
      
      [Inject] // added
      public static var clanUserInfoService:ClanUserInfoService;
      
      [Inject] // added
      public static var userInfoService:IUserInfoService;
      
      private var CHANNEL:String = "UserPropertiesModel";
      
      private var _id:String;
      
      private var _name:String;
      
      private var _score:int;
      
      private var _rank:int;
      
      private var _nextScore:int;
      
      private var _place:int;
      
      private var _userRating:Number;
      
      private var _initialUserRating:Number;
      
      private var _currentRankScore:int;
      
      private var _localUserInfoUpdater:IUserInfoLabelUpdater;
      
      public function UserPropertiesModel()
      {
         super();
      }
      
      public function objectLoaded() : void
      {
         userPropertiesService.init(getInitParam().id,getInitParam().uid,getInitParam().score,getInitParam().rank,getInitParam().userProfileUrl,getInitParam().registrationTimestamp,getInitParam().hasSpectatorPermissions,getInitParam().canUseGroup);
      }
      
      public function objectLoadedPost() : void
      {
         this._id = getInitParam().id;
         this._name = getInitParam().uid;
         this._nextScore = getInitParam().rankBounds.topBound;
         this._score = getInitParam().score;
         this._currentRankScore = getInitParam().rankBounds.lowBound;
         this._rank = getInitParam().rank;
         this._place = getInitParam().place;
         this._userRating = getInitParam().userRating;
         this._initialUserRating = getInitParam().userRating;
         if(clanUserInfoService != null)
         {
            clanUserInfoService.removeEventListener(ClanUserInfoEvent.ON_JOIN_CLAN,this.onClanUserInfoChanged);
            clanUserInfoService.removeEventListener(ClanUserInfoEvent.ON_LEAVE_CLAN,this.onClanUserInfoChanged);
            clanUserInfoService.addEventListener(ClanUserInfoEvent.ON_JOIN_CLAN,this.onClanUserInfoChanged);
            clanUserInfoService.addEventListener(ClanUserInfoEvent.ON_LEAVE_CLAN,this.onClanUserInfoChanged);
         }

         //panelView.addEventListener(PanelInitedEvent.TYPE,getFunctionWrapper(this.onPanelInitialized));
         // original line above replaced with the line below
         panelView.addEventListener(PanelInitedEvent.TYPE,this.onPanelInitialized);

         if(getInitParam().daysFromLastVisit > 0)
         {
            trackerService.trackEvent("lobby","ReturnVisit",getInitParam().daysFromRegistration.toString());
            trackerService.trackEvent("lobby","DaysLastVisit",getInitParam().daysFromLastVisit.toString());
         }
      }
      
      private function onPanelInitialized(param1:PanelInitedEvent) : void
      {
         //panelView.removeEventListener(PanelInitedEvent.TYPE,getFunctionWrapper(this.onPanelInitialized));
         // original line above replaced with the line below
         panelView.removeEventListener(PanelInitedEvent.TYPE,this.onPanelInitialized);
         var _loc2_:MainPanel = panelView.getPanel();
         _loc2_.rank = this._rank;
         this.updateScore(this._score);
         _loc2_.playerInfo.userId = this._id;
         _loc2_.playerInfo.clanUserInfoService = clanUserInfoService;
         _loc2_.playerInfo.playerName = this._name;
         this.subscribeLocalClanTagUpdater();
         moneyService.init(getInitParam().crystals);
         this.updateUserRating(this._userRating);
      }
      
      public function updateScore(param1:int, param2:Boolean = false) : void
      {
         var _loc2_:int = this._score;
         TankTraceUtil.logRatings("UserPropertiesModel.updateScore old=" + _loc2_ + " new=" + param1 + " silent=" + param2 + " next=" + this._nextScore + " low=" + this._currentRankScore);
         this._score = param1;
         panelView.getPanel().playerInfo.updateScore(param1,this._nextScore);
         this.updateProgress(param2);
         if(param1 != _loc2_)
         {
            userPropertiesService.updateScore(param1);
         }
      }
      
      public function updateRank(param1:int, param2:int, param3:RankBounds, param4:int, param5:Boolean, param6:Boolean, param7:Boolean = false) : void
      {
         var _loc7_:int = this._rank;
         TankTraceUtil.logRatings("UserPropertiesModel.updateRank oldRank=" + _loc7_ + " newRank=" + param1 + " oldScore=" + this._score + " newScore=" + param2 + " low=" + param3.lowBound + " top=" + param3.topBound + " reward=" + param4 + " alert=" + !param6 + " silent=" + param7);
         this._rank = param1;
         this._score = param2;
         this._nextScore = param3.topBound;
         this._currentRankScore = param3.lowBound;
         var _loc8_:MainPanel = panelView.getPanel();
         _loc8_.rank = param1;
         _loc8_.playerInfo.updateScore(this._score,param3.topBound);
         if(!param6 && param1 != _loc7_)
         {
            display.stage.addChild(new UpdateRankNotice(param1,param4));
         }
         this.updateProgress(param7);
         //userPropertiesService.updateCanUseGroup(param5);
         if(param1 != _loc7_)
         {
            userPropertiesService.updateRank(param1);
         }
         trackerService.trackEvent("battle","UpdateRank",String(param1));
      }
      
      private function updateProgress(param1:Boolean = false) : void
      {
         var _loc1_:int = 0;
         if(this._nextScore != 0)
         {
            _loc1_ = (this._score - this._currentRankScore) / (this._nextScore - this._currentRankScore) * 10000;
         }
         else
         {
            _loc1_ = 10000;
         }
         if(param1)
         {
            panelView.getPanel().playerInfo.setProgressSilently(_loc1_);
         }
         else
         {
            panelView.getPanel().playerInfo.progress = _loc1_;
         }
      }
      
      public function getId() : String
      {
         return this._id;
      }
      
      public function getName() : String
      {
         return this._name;
      }
      
      public function getScore() : int
      {
         return this._score;
      }
      
      public function getRank() : int
      {
         return this._rank;
      }
      
      public function getNextScore() : int
      {
         return this._nextScore;
      }
      
      public function getPlace() : int
      {
         return this._place;
      }
      
      public function changeCrystal(param1:int) : void
      {
         moneyService.setServerCrystals(param1);
      }
      
      public function updateUid(param1:String) : void
      {
         this.getPlayerInfo().playerName = param1;
      }
      
      private function getPlayerInfo() : PlayerInfo
      {
         return panelView.getPanel().playerInfo;
      }
      
      private function subscribeLocalClanTagUpdater() : void
      {
         if(userInfoService == null || this._id == null || this._id == "")
         {
            return;
         }
         if(this._localUserInfoUpdater != null)
         {
            this._localUserInfoUpdater.removeEventListener(UserInfoLabelUpdaterEvent.CHANGE_CLAN_TAG,this.onLocalClanTagChanged);
         }
         this._localUserInfoUpdater = userInfoService.getOrCreateUpdater(this._id);
         if(this._localUserInfoUpdater != null)
         {
            this._localUserInfoUpdater.addEventListener(UserInfoLabelUpdaterEvent.CHANGE_CLAN_TAG,this.onLocalClanTagChanged);
         }
      }
      
      private function onLocalClanTagChanged(param1:UserInfoLabelUpdaterEvent) : void
      {
         if(param1 != null && param1.userId != null && param1.userId != "" && param1.userId != this._id)
         {
            return;
         }
         this.refreshTopBarClanTag();
      }
      
      private function onClanUserInfoChanged(param1:ClanUserInfoEvent) : void
      {
         this.refreshTopBarClanTag();
      }
      
      private function refreshTopBarClanTag() : void
      {
         if(panelView == null || panelView.getPanel() == null || panelView.getPanel().playerInfo == null)
         {
            return;
         }
         this.getPlayerInfo().refreshClanTag();
      }
      
      public function onJoinClan() : void
      {
         //clanUserInfoService.onJoinClan();
      }
      
      public function onLeaveClan() : void
      {
         //clanUserInfoService.onLeaveClan();
      }
      
      public function updateGearScore(param1:int) : void
      {
         // GearScore is not displayed in the original ratings panel.
      }
      
      public function updateUserRating(param1:Number, param2:int = -1) : void
      {
         var _loc2_:PlayerInfo = this.getPlayerInfo();
         var _loc3_:int = param2;
         TankTraceUtil.logRatings("UserPropertiesModel.updateUserRating initialRating=" + this._initialUserRating + " currentRating=" + this._userRating + " newRating=" + param1 + " oldPlace=" + this._place + " requestedPlace=" + param2 + " initPlace=" + getInitParam().place);
         if(_loc3_ <= 0)
         {
            _loc3_ = getInitParam().place;
         }
         if(_loc3_ > 0)
         {
            this._place = _loc3_;
         }
         if(this._initialUserRating < param1)
         {
            _loc2_.ratingChangeStatus = 1;
         }
         else if(this._initialUserRating > param1)
         {
            _loc2_.ratingChangeStatus = -1;
         }
         else
         {
            _loc2_.ratingChangeStatus = 0;
         }
         this._userRating = param1;
         _loc2_.userRating = param1;
         _loc2_.ratingPlace = this._place;
      }
   }
}
