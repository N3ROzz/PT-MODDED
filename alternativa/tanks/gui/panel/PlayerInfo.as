package alternativa.tanks.gui.panel
{
   import alternativa.tanks.gui.panel.helpers.PlayerInfoHelper;
   import controls.Label;
   import controls.Money;
   import controls.panel.Indicators;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.filters.GlowFilter;
   import alternativa.osgi.service.locale.ILocaleService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.clan.ClanUserInfoService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.clan.UserClanInfo;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.rank.RankService;
   
   public class PlayerInfo extends Sprite
   {
      
      [Inject] // added
      public static var rankService:RankService;
      
      [Inject] // added
      public static var localeService:ILocaleService;
      
      private const normalGlowColor:uint = 1244928;
      
      private const minusGlowColor:uint = 16728064;
      
      private const ratingBadColor:uint = 16717056;
      
      private const ratingNeutralColor:uint = 11711154;
      
      private const ratingGoodColor:uint = 1244928;
      
      private var _playerName:String;
      
      private var _userId:String;
      
      private var _clanUserInfoService:ClanUserInfoService;
      
      private var _rank:int;
      
      private var _score:int = 0;
      
      private var _scoreRemain:int = 0;
      
      private var _progress:int = 0;
      
      private var _newProgress:int;
      
      private var _crystals:int = 0;
      
      private var _userRating:Number = 0;
      
      private var _ratingPlace:int = 0;
      
      private var _ratingChangeStatus:int = 0;
      
      public var indicators:Indicators = new Indicators();
      
      private var glowAlpha:Object = new Object();
      
      private var glowColor:Object = new Object();
      
      private var glowDelta:Number = 0.02;
      
      private var _width:int;
      
      public function PlayerInfo()
      {
         super();
         addChild(this.indicators);
         this.indicators.scoreLabel.visible = this.indicators.kd_icon.visible = this.indicators.kdRatio.visible = true;
         addEventListener(Event.ADDED_TO_STAGE,this.configUI);
      }
      
      public function set playerName(param1:String) : void
      {
         this._playerName = param1;
         this.updateInfo();
      }
      
      public function get playerName() : String
      {
         return this._playerName;
      }
      
      public function set userId(param1:String) : void
      {
         this._userId = param1;
         this.updateInfo();
      }
      
      public function get userId() : String
      {
         return this._userId;
      }
      
      public function set clanUserInfoService(param1:ClanUserInfoService) : void
      {
         this._clanUserInfoService = param1;
         this.updateInfo();
      }
      
      public function refreshClanTag() : void
      {
         this.updateInfo();
      }
      
      public function get rank() : int
      {
         return this._rank;
      }
      
      public function set rank(param1:int) : void
      {
         this._rank = param1;
         this.updateInfo();
      }
      
      public function updateScore(param1:int, param2:int) : void
      {
         if(param1 != this._score && this._score != 0)
         {
            this.flashLabel(this.indicators.playerInfo,param1 > this._score ? this.normalGlowColor : this.minusGlowColor);
         }
         this._score = param1;
         this._scoreRemain = param2;
         this.updateInfo();
      }
      
      public function get progress() : int
      {
         return this._progress;
      }
      
      public function set progress(param1:int) : void
      {
         if(this._progress == 0)
         {
            this._progress = param1;
         }
         else
         {
            this._newProgress = param1;
            this._progress = param1;
            this.indicators.newprogress = param1;
         }
         this.updateInfo();
      }
      
      public function setProgressSilently(param1:int) : void
      {
         this._newProgress = param1;
         this._progress = param1;
         this.updateInfo();
      }
      
      public function set crystals(param1:int) : void
      {
         if(param1 != this._crystals && this._crystals != 0)
         {
            this.flashLabel(this.indicators.crystalInfo,param1 > this._crystals ? this.normalGlowColor : this.minusGlowColor);
         }
         this._crystals = param1;
         this.updateInfo();
      }
      
      private function configUI(param1:Event) : void
      {
         removeEventListener(Event.ADDED_TO_STAGE,this.configUI);
         this.indicators.x = 59;
         PlayerInfoHelper.setDefaultSharpnessAndThickness(this.indicators.crystalInfo);
         PlayerInfoHelper.setDefaultSharpnessAndThickness(this.indicators.kdRatio);
         PlayerInfoHelper.setDefaultSharpnessAndThickness(this.indicators.playerInfo);
         PlayerInfoHelper.setDefaultSharpnessAndThickness(this.indicators.scoreLabel);
      }
      
      private function updateInfo() : void
      {
         this.indicators.playerInfo.text = String(this._score) + " / " + String(this._scoreRemain) + "   " + rankService.getRankName(this._rank) + " " + this.getDisplayPlayerName();
         this.indicators.progress = this._progress;
         this.indicators.crystalInfo.text = Money.numToString(this._crystals,false);
         this.indicators.kdRatio.text = String(int(this._userRating));
         this.indicators.scoreLabel.text = this._width > 520 ? this.getRatingLabel() + String(this._ratingPlace) : "#" + this._ratingPlace.toString();
         this.updateRatingColor();
         this.updateRatingIcon();
         this.width = this._width;
      }
      
      private function getDisplayPlayerName() : String
      {
         var _loc1_:UserClanInfo = null;
         if(this._playerName == null)
         {
            return "";
         }
         if(this.hasClanTagPrefix(this._playerName))
         {
            return this._playerName;
         }
         if(this._clanUserInfoService == null || this._userId == null || this._userId == "")
         {
            return this._playerName;
         }
         _loc1_ = this._clanUserInfoService.userClanInfoByUserId(this._userId);
         if(_loc1_ == null || !_loc1_.isInClan || _loc1_.clanTag == null || _loc1_.clanTag == "")
         {
            return this._playerName;
         }
         return "[" + _loc1_.clanTag + "] " + this._playerName;
      }
      
      private function hasClanTagPrefix(param1:String) : Boolean
      {
         return param1 != null && param1.length > 3 && param1.charAt(0) == "[" && param1.indexOf("] ") > 1;
      }
      
      private function getRatingLabel() : String
      {
         var _loc1_:String = null;
         if(localeService != null)
         {
            _loc1_ = localeService.getText("MAIN_PANEL_RATING_LABEL");
            if(_loc1_ != null && _loc1_ != "MAIN_PANEL_RATING_LABEL")
            {
               return _loc1_;
            }
         }
         return "Rating: ";
      }
      
      private function flashLabel(param1:Label, param2:uint = 16711680) : void
      {
         this.glowAlpha[param1.name] = 1;
         this.glowColor[param1.name] = param2;
         param1.addEventListener(Event.ENTER_FRAME,this.glowFrame);
      }
      
      private function glowFrame(param1:Event) : void
      {
         var _loc2_:Label = param1.target as Label;
         var _loc3_:GlowFilter = new GlowFilter(this.glowColor[_loc2_.name],this.glowAlpha[_loc2_.name],4,4,3,1,false);
         _loc2_.filters = [_loc3_];
         this.glowAlpha[_loc2_.name] -= this.glowDelta;
         if(this.glowAlpha[_loc2_.name] < 0)
         {
            _loc2_.filters = [];
            _loc2_.removeEventListener(Event.ENTER_FRAME,this.glowFrame);
         }
      }
      
      override public function set width(param1:Number) : void
      {
         this._width = int(param1);
         this.indicators.width = param1;
      }
      
      private function updateWidth() : void
      {
         this.width = this._width;
      }
      
      public function set gearScore(param1:int) : void
      {
         // GearScore is intentionally hidden here; the original panel shows rating.
      }
      
      public function set userRating(param1:Number) : void
      {
         if(param1 != this._userRating && this._userRating != 0)
         {
            this.flashLabel(this.indicators.kdRatio,param1 > this._userRating ? this.normalGlowColor : this.minusGlowColor);
         }
         this._userRating = param1;
         this.updateInfo();
      }
      
      public function get userRating() : Number
      {
         return this._userRating;
      }
      
      public function set ratingPlace(param1:int) : void
      {
         if(param1 != this._ratingPlace && this._ratingPlace != 0)
         {
            this.flashLabel(this.indicators.scoreLabel,param1 > this._ratingPlace ? this.minusGlowColor : this.normalGlowColor);
         }
         this._ratingPlace = param1;
         this.updateInfo();
      }
      
      public function get ratingPlace() : int
      {
         return this._ratingPlace;
      }
      
      public function set ratingChangeStatus(param1:int) : void
      {
         this._ratingChangeStatus = param1;
         this.updateInfo();
      }
      
      public function get ratingChangeStatus() : int
      {
         return this._ratingChangeStatus;
      }
      
      private function updateRatingColor() : void
      {
         switch(this._ratingChangeStatus + 1)
         {
            case 0:
               this.indicators.kdRatio.color = this.ratingBadColor;
               break;
            case 1:
               this.indicators.kdRatio.color = this.ratingNeutralColor;
               break;
            case 2:
               this.indicators.kdRatio.color = this.ratingGoodColor;
         }
      }
      
      private function updateRatingIcon() : void
      {
         var _loc1_:Function = null;
         if(this.indicators.kd_icon == null)
         {
            return;
         }
         _loc1_ = this.indicators.kd_icon["set package finally"] as Function;
         if(_loc1_ != null)
         {
            _loc1_.call(this.indicators.kd_icon,this._ratingChangeStatus + 2);
         }
         else
         {
            this.indicators.kd_icon.gotoAndStop(this._ratingChangeStatus + 2);
         }
      }
   }
}
