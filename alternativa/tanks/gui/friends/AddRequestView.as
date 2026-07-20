package alternativa.tanks.gui.friends
{
   import alternativa.osgi.service.locale.ILocaleService;
   import alternativa.types.Long;
   import controls.ValidationIcon;
   import controls.base.LabelBase;
   import controls.base.TankInputBase;
   import flash.display.Sprite;
   import flash.events.FocusEvent;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.ui.Keyboard;
   import flash.utils.clearTimeout;
   import flash.utils.setTimeout;
   import forms.ColorConstants;
   import forms.events.LoginFormEvent;
   import projects.tanks.clients.fp10.libraries.TanksLocale;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.friends.FriendState;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.uidcheck.UidCheckService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.alertservices.IAlertService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.blur.IBlurService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.FriendActionServiceUidEvent;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.IFriendActionService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.IFriendInfoService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.userproperties.IUserPropertiesService;
   import utils.TankTraceUtil;
   
   public class AddRequestView extends Sprite
   {
      
      [Inject] // added
      public static var friendsActionService:IFriendActionService;

      [Inject] // added
      public static var friendInfoService:IFriendInfoService;
      
      [Inject] // added
      public static var localeService:ILocaleService;
      
      [Inject] // added
      public static var alertService:IAlertService;
      
      [Inject] // added
      public static var blurService:IBlurService;
      
      [Inject] // added
      public static var userPropertiesService:IUserPropertiesService;
      
      [Inject] // added
      public static var uidCheckService:UidCheckService;
      
      private static const SEARCH_TIMEOUT:int = 600;
      
      private var _searchFriendTextInput:TankInputBase;
      
      private var _searchFriendLabel:LabelBase;
      
      private var _addRequestButton:FriendWindowButton;
      
      private var _validateCheckUidIcon:ValidationIcon;
      
      private var _searchFriendTimeOut:uint;
      
      private var _searchFriendUid:String;
      
      private var _searchFriendExist:Boolean;
      
      private var _searchUserId:Long;
      
      public function AddRequestView()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this._searchFriendTextInput = new TankInputBase();
         this._searchFriendTextInput.maxChars = 20;
         this._searchFriendTextInput.restrict = "0-9.a-zA-z_\\-*";
         addChild(this._searchFriendTextInput);
         this._searchFriendLabel = new LabelBase();
         addChild(this._searchFriendLabel);
         this._searchFriendLabel.mouseEnabled = false;
         this._searchFriendLabel.color = ColorConstants.LIST_LABEL_HINT;
         this._searchFriendLabel.text = localeService.getText(TanksLocale.TEXT_FRIENDS_FIND_TO_SEND);
         this._validateCheckUidIcon = new ValidationIcon();
         addChild(this._validateCheckUidIcon);
         this._addRequestButton = new FriendWindowButton();
         addChild(this._addRequestButton);
         this._addRequestButton.label = localeService.getText(TanksLocale.TEXT_FRIENDS_SEND_REQUEST_BUTTON);
         this._addRequestButton.enable = false;
         this.resize();
      }
      
      public function resize() : void
      {
         this._searchFriendTextInput.width = 235;
         this._searchFriendTextInput.x = FriendsWindow.WINDOW_MARGIN;
         this._searchFriendLabel.x = this._searchFriendTextInput.x + 3;
         this._searchFriendLabel.y = this._searchFriendTextInput.y + 7;
         this._validateCheckUidIcon.x = this._searchFriendTextInput.x + this._searchFriendTextInput.width - this._validateCheckUidIcon.width - 15;
         this._validateCheckUidIcon.y = this._searchFriendTextInput.y + 7;
         this._addRequestButton.width = FriendsWindow.DEFAULT_BUTTON_WIDTH;
         this._addRequestButton.x = this._searchFriendTextInput.width + 8;
      }
      
      public function hide() : void
      {
         clearTimeout(this._searchFriendTimeOut);
         this.removeEvents();
         this.clearSearchFriendTextInput();
         this.visible = false;
      }
      
      private function removeEvents() : void
      {
         this._addRequestButton.removeEventListener(MouseEvent.CLICK,this.onClickAddRequestButton);
         this._searchFriendTextInput.removeEventListener(FocusEvent.FOCUS_IN,this.onFocusInSearchFriend);
         this._searchFriendTextInput.removeEventListener(FocusEvent.FOCUS_OUT,this.onFocusOutSearchFriend);
         this._searchFriendTextInput.removeEventListener(LoginFormEvent.TEXT_CHANGED,this.onSearchFriendTextChange);
         this._searchFriendTextInput.removeEventListener(KeyboardEvent.KEY_UP,this.onKeyUp);
         friendsActionService.removeEventListener(FriendActionServiceUidEvent.UID_EXIST,this.onUidExist);
         friendsActionService.removeEventListener(FriendActionServiceUidEvent.UID_NOT_EXIST,this.onUidNotExist);
      }
      
      public function show() : void
      {
         this.visible = true;
         this.setEvents();
         this._searchFriendTextInput.value = "";
         this.updateVisibleSearchFriendLabel();
      }
      
      private function setEvents() : void
      {
         this._addRequestButton.addEventListener(MouseEvent.CLICK,this.onClickAddRequestButton);
         this._searchFriendTextInput.addEventListener(FocusEvent.FOCUS_IN,this.onFocusInSearchFriend);
         this._searchFriendTextInput.addEventListener(FocusEvent.FOCUS_OUT,this.onFocusOutSearchFriend);
         this._searchFriendTextInput.addEventListener(LoginFormEvent.TEXT_CHANGED,this.onSearchFriendTextChange);
         this._searchFriendTextInput.addEventListener(KeyboardEvent.KEY_UP,this.onKeyUp);
         friendsActionService.addEventListener(FriendActionServiceUidEvent.UID_EXIST,this.onUidExist);
         friendsActionService.addEventListener(FriendActionServiceUidEvent.UID_NOT_EXIST,this.onUidNotExist);
      }
      
      private function onClickAddRequestButton(param1:MouseEvent) : void
      {
         TankTraceUtil.logFriends("AddRequestView.clickSend uid=" + this._searchFriendUid + " exists=" + this._searchFriendExist + " buttonEnabled=" + this._addRequestButton.enable);
         this.addRequest();
      }
      
      private function addRequest() : void
      {
         if(this._searchFriendExist && this._searchFriendUid != null)
         {
            TankTraceUtil.logFriends("AddRequestView.sendRequest uid=" + this._searchFriendUid);
            friendsActionService.addByUid(this._searchFriendUid);
            if(friendInfoService != null)
            {
               friendInfoService.setFriendState(this._searchFriendUid,FriendState.OUTGOING);
            }
            this.clearSearchFriendTextInput();
         }
         else
         {
            TankTraceUtil.logFriends("AddRequestView.sendRequestBlocked uid=" + this._searchFriendUid + " exists=" + this._searchFriendExist);
         }
      }
      
      private function clearSearchFriendTextInput() : void
      {
         this._searchFriendTextInput.value = "";
         this._addRequestButton.enable = false;
         this._validateCheckUidIcon.turnOff();
         this._searchFriendExist = false;
         this._searchFriendUid = null;
      }
      
      private function onFocusInSearchFriend(param1:FocusEvent) : void
      {
         this._searchFriendLabel.visible = false;
      }
      
      private function onFocusOutSearchFriend(param1:FocusEvent) : void
      {
         this.updateVisibleSearchFriendLabel();
      }
      
      private function updateVisibleSearchFriendLabel() : void
      {
         if(this._searchFriendTextInput.value.length == 0)
         {
            this._searchFriendLabel.visible = true;
            this._validateCheckUidIcon.turnOff();
            this._searchFriendTextInput.validValue = true;
         }
      }
      
      private function onSearchFriendTextChange(param1:LoginFormEvent) : void
      {
         this._searchFriendExist = false;
         this._addRequestButton.enable = false;
         this._validateCheckUidIcon.startProgress();
         this._validateCheckUidIcon.y = this._searchFriendTextInput.y + 5;
         if(this._searchFriendTextInput.value.length > 0)
         {
            this._searchFriendLabel.visible = false;
         }
         clearTimeout(this._searchFriendTimeOut);
         this._searchFriendTimeOut = setTimeout(this.searchFriendTextChange,SEARCH_TIMEOUT);
      }
      
      private function searchFriendTextChange() : void
      {
         if(this._searchFriendTextInput.value.length == 0)
         {
            this._validateCheckUidIcon.turnOff();
            this._searchFriendTextInput.validValue = true;
         }
         else
         {
            this._searchFriendUid = this._searchFriendTextInput.value;
            TankTraceUtil.logFriends("AddRequestView.checkUid uid=" + this._searchFriendUid);
            friendsActionService.check(this._searchFriendUid);
         }
      }
      
      private function onUidExist(param1:FriendActionServiceUidEvent) : void
      {
         TankTraceUtil.logFriends("AddRequestView.uidExists searchedUid=" + this._searchFriendUid);
         this.checkUid(true);
      }
      
      private function onUidNotExist(param1:FriendActionServiceUidEvent) : void
      {
         TankTraceUtil.logFriends("AddRequestView.uidNotExists searchedUid=" + this._searchFriendUid);
         this.checkUid(false);
      }
      
      private function onKeyUp(param1:KeyboardEvent) : void
      {
         if(param1.keyCode == Keyboard.ENTER)
         {
            this.addRequest();
         }
      }
      
      private function checkUid(param1:Boolean) : *
      {
         this._searchFriendTextInput.validValue = param1;
         if(param1)
         {
            this._validateCheckUidIcon.markAsValid();
            if(userPropertiesService.userName.toLowerCase() != this._searchFriendUid.toLowerCase())
            {
               this._searchFriendExist = true;
               this._addRequestButton.enable = true;
            }
         }
         else
         {
            this._searchFriendUid = null;
            this._validateCheckUidIcon.markAsInvalid();
            this._addRequestButton.enable = false;
         }
         this._validateCheckUidIcon.y = this._searchFriendTextInput.y + 7;
      }
   }
}
