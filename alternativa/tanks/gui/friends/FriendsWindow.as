package alternativa.tanks.gui.friends
{
   import alternativa.osgi.service.locale.ILocaleService;
   import alternativa.tanks.gui.friends.list.AcceptedList;
   import alternativa.tanks.gui.friends.list.IncomingList;
   import alternativa.tanks.gui.friends.list.OutgoingList;
   import alternativa.tanks.gui.friends.list.refferals.ReferralForm;
   import alternativa.tanks.service.referrals.notification.NewReferralsNotifierService;
   import alternativa.tanks.service.referrals.notification.NewReferralsNotifierServiceEvent;
   import controls.TankWindowInner;
   import controls.base.LabelBase;
   import controls.base.TankInputBase;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.FocusEvent;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.utils.clearTimeout;
   import flash.utils.setTimeout;
   import forms.ColorConstants;
   import forms.TankWindowWithHeader;
   import forms.events.LoginFormEvent;
   import platform.clients.fp10.libraries.alternativapartners.service.IPartnerService;
   import projects.tanks.clients.fp10.libraries.TanksLocale;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.alertservices.AlertServiceEvent;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.alertservices.IAlertService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.battle.activator.BattleLinkActivatorServiceEvent;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.battle.activator.IBattleLinkActivatorService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.blur.IBlurService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.dialogs.gui.DialogWindow;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.friends.FriendState;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.IFriendActionService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.IFriendInfoService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.FriendStateChangeEvent;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.NewFriendEvent;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.logging.gamescreen.UserChangeGameScreenService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.user.IUserInfoService;
   import utils.TankTraceUtil;
   
   public class FriendsWindow extends DialogWindow
   {
      
      [Inject] // added
      public static var localeService:ILocaleService;
      
      [Inject] // added
      public static var battleLinkActivatorService:IBattleLinkActivatorService;
      
      [Inject] // added
      public static var friendInfoService:IFriendInfoService;
      
      [Inject] // added
      public static var friendsActionService:IFriendActionService;
      
      [Inject] // added
      public static var blurService:IBlurService;
      
      [Inject] // added
      public static var alertService:IAlertService;
      
      [Inject] // added
      public static var userChangeGameScreenService:UserChangeGameScreenService;
      
      //[Inject]
      //public static var clanUserInfoService:ClanUserInfoService;
      
      [Inject] // added
      public static var userInfoService:IUserInfoService;
      
      [Inject] // added
      public static var newReferralsNotifierService:NewReferralsNotifierService;
      
      [Inject] // added
      public static var partnerService:IPartnerService;
      
      public static const WINDOW_MARGIN:int = 12;
      
      public static const DEFAULT_BUTTON_WIDTH:int = 100;
      
      public static const BUTTON_WITH_ICON_WIDTH:int = 115;
      
      public static const WINDOW_WIDTH:int = 468 + WINDOW_MARGIN * 2 + 4;
      
      private static const WINDOW_HEIGHT:int = 485;
      
      private static const SEARCH_TIMEOUT:int = 600;
      
      private var window:TankWindowWithHeader;
      
      private var windowInner:TankWindowInner;
      
      private var windowSize:Point;
      
      private var incomingButton:FriendsWindowStateBigButton;
      
      private var outgoingButton:FriendsWindowStateBigButton;
      
      private var acceptedFriendButton:FriendsWindowStateBigButton;
      
      private var referralsButton:FriendsWindowStateBigButton;
      
      private var closeButton:FriendWindowButton;
      
      private var rejectAllIncomingButton:RejectAllIncomingButton;
      
      private var acceptedList:AcceptedList;
      
      private var incomingList:IncomingList;
      
      private var outgoingList:OutgoingList;
      
      private var referralsForm:ReferralForm;
      
      private var currentList:IFriendsListState;
      
      private var addRequestView:AddRequestView;
      
      private var filterTextInput:TankInputBase;
      
      private var filterLabel:LabelBase;
      
      private var filterTimeout:uint;
      
      public function FriendsWindow()
      {
         super();
         this.initWindow();
         this.initButtons();
         this.initLists();
         this.addFriendRequestView();
         this.addFilterView();
         this.initOthers();
         this.resize();
         addEventListener(Event.ADDED_TO_STAGE,this.added);
      }
      
      private function added(param1:Event) : void
      {
         this.updateClanButton();
      }
      
      public function updateClanButton() : void
      {
      }
      
      private function initWindow() : void
      {
         this.window = TankWindowWithHeader.createWindow(TanksLocale.TEXT_HEADER_FRIENDS);
         addChild(this.window);
         this.windowSize = new Point(WINDOW_WIDTH,WINDOW_HEIGHT);
         this.windowInner = new TankWindowInner(0,0,TankWindowInner.GREEN);
         addChild(this.windowInner);
      }
      
      private function initButtons() : void
      {
         this.acceptedFriendButton = new FriendsWindowStateBigButton(FriendsWindowState.ACCEPTED);
         this.acceptedFriendButton.text = localeService.getText(TanksLocale.TEXT_FRIENDS);
         this.acceptedFriendButton.addEventListener(MouseEvent.CLICK,this.onChangeState);
         addChild(this.acceptedFriendButton);
         this.referralsButton = new FriendsWindowStateBigButton(FriendsWindowState.REFERRALS);
         this.referralsButton.text = localeService.getText(TanksLocale.TEXT_REFERRALS_BUTTON_LABEL);
         this.referralsButton.addEventListener(MouseEvent.CLICK,this.onChangeState);
         addChild(this.referralsButton);
         this.referralsButton.visible = false;
         this.incomingButton = new FriendsWindowStateBigButton(FriendsWindowState.INCOMING);
         this.incomingButton.text = "Incoming Requests";
         this.incomingButton.addEventListener(MouseEvent.CLICK,this.onChangeState);
         addChild(this.incomingButton);
         this.outgoingButton = new FriendsWindowStateBigButton(FriendsWindowState.OUTGOING);
         this.outgoingButton.text = "Sent requests";
         this.outgoingButton.addEventListener(MouseEvent.CLICK,this.onChangeState);
         addChild(this.outgoingButton);
         this.rejectAllIncomingButton = new RejectAllIncomingButton();
         this.rejectAllIncomingButton.label = localeService.getText(TanksLocale.TEXT_FRIENDS_DECLINE_ALL_BUTTON);
         this.rejectAllIncomingButton.addEventListener(MouseEvent.CLICK,this.onClickRejectAllIncoming);
         addChild(this.rejectAllIncomingButton);
         this.closeButton = new FriendWindowButton();
         this.closeButton.label = localeService.getText(TanksLocale.TEXT_FRIENDS_CLOSE);
         addChild(this.closeButton);
      }
      
      private function isReferralsButtonNeed() : Boolean
      {
         return !partnerService.isRunningInsidePartnerEnvironment() || Boolean(partnerService.hasSocialFunction());
      }
      
      private function initLists() : void
      {
         this.acceptedList = new AcceptedList();
         this.incomingList = new IncomingList(this.rejectAllIncomingButton);
         this.outgoingList = new OutgoingList();
         this.referralsForm = new ReferralForm();
      }
      
      private function initOthers() : void
      {
         battleLinkActivatorService.addEventListener(BattleLinkActivatorServiceEvent.ACTIVATE_LINK,this.onBattleLinkClick);
         newReferralsNotifierService.addEventListener(NewReferralsNotifierServiceEvent.NEW_REFERRALS_COUNT_UPDATED,this.onUpdateNewReferralsCount);
         newReferralsNotifierService.addEventListener(NewReferralsNotifierServiceEvent.REFERRAL_ADDED,this.onReferralAdded);
      }
      
      private function addFriendRequestView() : void
      {
         this.addRequestView = new AddRequestView();
         addChild(this.addRequestView);
         this.addRequestView.show();
      }
      
      private function addFilterView() : void
      {
         this.filterTextInput = new TankInputBase();
         this.filterTextInput.maxChars = 20;
         this.filterTextInput.restrict = "0-9.a-zA-z_\\-*";
         this.filterTextInput.addEventListener(FocusEvent.FOCUS_IN,this.onFocusInFilter);
         this.filterTextInput.addEventListener(FocusEvent.FOCUS_OUT,this.onFocusOutFilter);
         this.filterTextInput.addEventListener(LoginFormEvent.TEXT_CHANGED,this.onFilterTextChange);
         addChild(this.filterTextInput);
         this.filterLabel = new LabelBase();
         this.filterLabel.mouseEnabled = false;
         this.filterLabel.color = ColorConstants.LIST_LABEL_HINT;
         this.filterLabel.text = localeService.getText(TanksLocale.TEXT_FRIENDS_FIND_IN_LIST_HINT);
         addChild(this.filterLabel);
         this.updateFilterLabel();
      }
      
      private function onReferralAdded(param1:NewReferralsNotifierServiceEvent) : void
      {
         this.updateNewReferralsCount();
      }
      
      private function onUpdateNewReferralsCount(param1:NewReferralsNotifierServiceEvent) : void
      {
         this.updateNewReferralsCount();
      }
      
      private function updateNewReferralsCount() : void
      {
         this.referralsButton.newRequestCount = newReferralsNotifierService.getNewReferralsCount();
      }
      
      private function onClickRejectAllIncoming(param1:MouseEvent) : void
      {
         var _loc2_:String = localeService.getText(TanksLocale.TEXT_FRIENDS_DECLINE_ALL_REQUESTS_ALERT);
         alertService.showAlert(_loc2_,Vector.<String>([localeService.getText(TanksLocale.TEXT_ALERT_ANSWER_YES),localeService.getText(TanksLocale.TEXT_ALERT_ANSWER_NO)]));
         alertService.addEventListener(AlertServiceEvent.ALERT_BUTTON_PRESSED,this.onConfirmRejectAllIncoming);
      }
      
      private function onConfirmRejectAllIncoming(param1:AlertServiceEvent) : void
      {
         alertService.removeEventListener(AlertServiceEvent.ALERT_BUTTON_PRESSED,this.onConfirmRejectAllIncoming);
         if(param1.typeButton == localeService.getText(TanksLocale.TEXT_ALERT_ANSWER_YES))
         {
            friendsActionService.rejectAllIncoming();
         }
      }
      
      private function onBattleLinkClick(param1:BattleLinkActivatorServiceEvent) : void
      {
         this.hide();
      }
      
      private function resize() : void
      {
         this.window.width = this.windowSize.x;
         this.window.height = this.windowSize.y;
         this.acceptedFriendButton.x = WINDOW_MARGIN;
         this.acceptedFriendButton.width = DEFAULT_BUTTON_WIDTH;
         this.acceptedFriendButton.y = WINDOW_MARGIN;
         this.incomingButton.width = 116;
         this.incomingButton.x = this.windowSize.x - WINDOW_MARGIN - this.incomingButton.width;
         this.incomingButton.y = WINDOW_MARGIN;
         this.outgoingButton.width = DEFAULT_BUTTON_WIDTH;
         this.outgoingButton.x = this.incomingButton.x - this.outgoingButton.width - 6;
         this.outgoingButton.y = WINDOW_MARGIN;
         this.referralsButton.x = this.acceptedFriendButton.x + this.acceptedFriendButton.width + 6;
         this.referralsButton.width = DEFAULT_BUTTON_WIDTH;
         this.referralsButton.y = WINDOW_MARGIN;
         this.closeButton.width = DEFAULT_BUTTON_WIDTH;
         this.closeButton.x = this.windowSize.x - this.closeButton.width - WINDOW_MARGIN;
         this.closeButton.y = this.windowSize.y - this.closeButton.height - WINDOW_MARGIN;
         this.rejectAllIncomingButton.width = DEFAULT_BUTTON_WIDTH;
         this.rejectAllIncomingButton.x = this.closeButton.x - this.rejectAllIncomingButton.width - 6;
         this.rejectAllIncomingButton.y = this.windowSize.y - this.rejectAllIncomingButton.height - WINDOW_MARGIN;
         this.windowInner.x = WINDOW_MARGIN;
         this.windowInner.y = this.acceptedFriendButton.y + this.acceptedFriendButton.height + 1;
         this.windowInner.width = this.windowSize.x - WINDOW_MARGIN * 2;
         this.windowInner.height = this.windowSize.y - this.windowInner.y - this.closeButton.height - 18;
         var _loc1_:int = 4;
         var _loc2_:int = this.windowInner.x + _loc1_;
         var _loc3_:int = this.windowInner.y + _loc1_;
         var _loc4_:int = this.windowInner.width - _loc1_ * 2 + 2;
         var _loc5_:int = this.windowInner.height - _loc1_ * 2;
         this.acceptedList.resize(_loc4_,_loc5_);
         this.acceptedList.x = _loc2_;
         this.acceptedList.y = _loc3_;
         this.incomingList.resize(_loc4_,_loc5_);
         this.incomingList.x = _loc2_;
         this.incomingList.y = _loc3_;
         this.outgoingList.resize(_loc4_,_loc5_);
         this.outgoingList.x = _loc2_;
         this.outgoingList.y = _loc3_;
         this.referralsForm.x = _loc2_ - 4;
         this.referralsForm.y = _loc3_;
         this.referralsForm.resize(_loc4_ + 6,_loc5_);
         this.addRequestView.y = this.windowSize.y - this.addRequestView.height - WINDOW_MARGIN;
         this.filterTextInput.width = 235;
         this.filterTextInput.x = WINDOW_MARGIN;
         this.filterTextInput.y = this.windowSize.y - this.filterTextInput.height - WINDOW_MARGIN;
         this.filterLabel.x = this.filterTextInput.x + 3;
         this.filterLabel.y = this.filterTextInput.y + 7;
      }
      
      private function onChangeState(param1:MouseEvent) : void
      {
         TankTraceUtil.logFriends("FriendsWindow.changeState state=" + FriendsWindowButtonType(param1.currentTarget).getType().value);
         this.show(FriendsWindowButtonType(param1.currentTarget).getType());
      }
      
      public function destroy() : void
      {
         this.acceptedFriendButton.removeEventListener(MouseEvent.CLICK,this.onChangeState);
         this.incomingButton.removeEventListener(MouseEvent.CLICK,this.onChangeState);
         this.outgoingButton.removeEventListener(MouseEvent.CLICK,this.onChangeState);
         this.referralsButton.removeEventListener(MouseEvent.CLICK,this.onChangeState);
         battleLinkActivatorService.removeEventListener(BattleLinkActivatorServiceEvent.ACTIVATE_LINK,this.onBattleLinkClick);
         newReferralsNotifierService.removeEventListener(NewReferralsNotifierServiceEvent.REFERRAL_ADDED,this.onReferralAdded);
         newReferralsNotifierService.removeEventListener(NewReferralsNotifierServiceEvent.NEW_REFERRALS_COUNT_UPDATED,this.onUpdateNewReferralsCount);
         this.rejectAllIncomingButton.removeEventListener(MouseEvent.CLICK,this.onClickRejectAllIncoming);
         this.filterTextInput.removeEventListener(FocusEvent.FOCUS_IN,this.onFocusInFilter);
         this.filterTextInput.removeEventListener(FocusEvent.FOCUS_OUT,this.onFocusOutFilter);
         this.filterTextInput.removeEventListener(LoginFormEvent.TEXT_CHANGED,this.onFilterTextChange);
         clearTimeout(this.filterTimeout);
         this.hide();
      }
      
      private function hide() : void
      {
         dialogService.removeDialog(this);
         if(this.closeButton.hasEventListener(MouseEvent.CLICK))
         {
            this.closeButton.removeEventListener(MouseEvent.CLICK,this.onCloseButtonClick);
         }
         if(this.currentList != null)
         {
            this.currentList.hide();
            this.currentList = null;
         }
         friendInfoService.removeEventListener(NewFriendEvent.ACCEPTED_CHANGE,this.onUpdateAcceptedCounter);
         friendInfoService.removeEventListener(NewFriendEvent.INCOMING_CHANGE,this.onUpdateIncomingCounter);
         friendInfoService.removeEventListener(FriendStateChangeEvent.CHANGE,this.onUpdateOutgoingCounter);
         this.addRequestView.hide();
         clearTimeout(this.filterTimeout);
      }
      
      private function onUpdateIncomingCounter(param1:NewFriendEvent) : void
      {
         this.updateIncomingCounter();
      }
      
      private function onUpdateAcceptedCounter(param1:NewFriendEvent) : void
      {
         this.updateAcceptedCounter();
      }
      
      private function updateIncomingCounter() : void
      {
         this.incomingButton.setRequestCount(friendInfoService.incomingFriendsLength,friendInfoService.newIncomingFriendsLength);
      }
      
      private function updateAcceptedCounter() : void
      {
         this.acceptedFriendButton.setRequestCount(friendInfoService.acceptedFriendsLength,friendInfoService.newAcceptedFriendsLength);
      }
      
      private function onUpdateOutgoingCounter(param1:FriendStateChangeEvent) : void
      {
         this.updateOutgoingCounter();
      }
      
      private function updateOutgoingCounter() : void
      {
         this.outgoingButton.setRequestCount(friendInfoService.getFriendsIdByState(FriendState.OUTGOING).length,0);
      }
      
      public function show(param1:FriendsWindowState) : void
      {
         TankTraceUtil.logFriends("FriendsWindow.show requestedState=" + param1.value);
         if(param1 == FriendsWindowState.CLAN_MEMBERS)
         {
            param1 = FriendsWindowState.ACCEPTED;
         }
         this.updateAcceptedCounter();
         this.updateIncomingCounter();
         this.updateOutgoingCounter();
         if(param1 != FriendsWindowState.REFERRALS)
         {
            this.updateReferralsCounter();
         }
         friendInfoService.addEventListener(NewFriendEvent.ACCEPTED_CHANGE,this.onUpdateAcceptedCounter);
         friendInfoService.addEventListener(NewFriendEvent.INCOMING_CHANGE,this.onUpdateIncomingCounter);
         friendInfoService.addEventListener(FriendStateChangeEvent.CHANGE,this.onUpdateOutgoingCounter);
         var _loc2_:IFriendsListState = this.getFriendsListByState(param1);
         this.updateState(param1);
         _loc2_.initList();
         addChild(Sprite(_loc2_));
         this.currentList = _loc2_;
         this.currentList.resetFilter();
      }
      
      private function getFriendsListByState(param1:FriendsWindowState) : IFriendsListState
      {
         switch(param1)
         {
            case FriendsWindowState.ACCEPTED:
               return this.acceptedList;
            case FriendsWindowState.INCOMING:
               return this.incomingList;
            case FriendsWindowState.OUTGOING:
               return this.outgoingList;
            case FriendsWindowState.CLAN_MEMBERS:
               return this.acceptedList;
            default:
               return this.referralsForm;
         }
      }
      
      private function updateReferralsCounter() : void
      {
         newReferralsNotifierService.requestNewReferralsCount();
      }
      
      private function onFocusInFilter(param1:FocusEvent) : void
      {
         this.filterLabel.visible = false;
      }
      
      private function onFocusOutFilter(param1:FocusEvent) : void
      {
         this.updateFilterLabel();
      }
      
      private function onFilterTextChange(param1:LoginFormEvent) : void
      {
         clearTimeout(this.filterTimeout);
         this.filterTimeout = setTimeout(this.applyFilter,SEARCH_TIMEOUT);
         if(this.filterTextInput.value.length > 0)
         {
            this.filterLabel.visible = false;
         }
      }
      
      private function applyFilter() : void
      {
         if(this.currentList != null)
         {
            this.currentList.filter("uid",this.filterTextInput.value);
         }
      }
      
      private function clearFilter() : void
      {
         clearTimeout(this.filterTimeout);
         this.filterTextInput.value = "";
         this.updateFilterLabel();
         if(this.currentList != null)
         {
            this.currentList.resetFilter();
         }
      }
      
      private function updateFilterLabel() : void
      {
         this.filterLabel.visible = this.filterTextInput.visible && this.filterTextInput.value.length == 0;
      }
      
      private function updateState(param1:FriendsWindowState) : void
      {
         this.currentState = param1;
         if(this.currentList != null)
         {
            this.currentList.hide();
            this.currentList = null;
         }
         dialogService.addDialog(this);
         if(!this.closeButton.hasEventListener(MouseEvent.CLICK))
         {
            this.closeButton.addEventListener(MouseEvent.CLICK,this.onCloseButtonClick);
         }
      }
      
      private function onCloseButtonClick(param1:MouseEvent = null) : void
      {
         this.closeWindow();
      }
      
      private function closeWindow() : void
      {
         userChangeGameScreenService.friendWindowClosed();
         display.stage.focus = null;
         this.hide();
      }
      
      public function set currentState(param1:FriendsWindowState) : void
      {
         TankTraceUtil.logFriends("FriendsWindow.currentState state=" + param1.value);
         if(param1 == FriendsWindowState.CLAN_MEMBERS)
         {
            param1 = FriendsWindowState.ACCEPTED;
         }
         switch(param1)
         {
            case FriendsWindowState.ACCEPTED:
               this.acceptedFriendButton.enable = false;
               this.referralsButton.enable = true;
               this.incomingButton.enable = true;
               this.outgoingButton.enable = true;
               this.rejectAllIncomingButton.visible = false;
               this.windowInner.visible = true;
               this.addRequestView.hide();
               this.filterTextInput.visible = true;
               this.clearFilter();
               break;
            case FriendsWindowState.INCOMING:
               this.acceptedFriendButton.enable = true;
               this.referralsButton.enable = true;
               this.incomingButton.enable = false;
               this.outgoingButton.enable = true;
               this.rejectAllIncomingButton.visible = true;
               this.windowInner.visible = true;
               this.addRequestView.hide();
               this.filterTextInput.visible = true;
               this.clearFilter();
               break;
            case FriendsWindowState.OUTGOING:
               this.acceptedFriendButton.enable = true;
               this.referralsButton.enable = true;
               this.incomingButton.enable = true;
               this.outgoingButton.enable = false;
               this.rejectAllIncomingButton.visible = false;
               this.windowInner.visible = true;
               this.filterTextInput.visible = false;
               this.filterLabel.visible = false;
               this.clearFilter();
               this.addRequestView.show();
               break;
            case FriendsWindowState.REFERRALS:
               this.acceptedFriendButton.enable = true;
               this.referralsButton.enable = false;
               this.incomingButton.enable = true;
               this.outgoingButton.enable = true;
               this.rejectAllIncomingButton.visible = false;
               this.windowInner.visible = false;
               this.addRequestView.hide();
               this.filterTextInput.visible = false;
               this.filterLabel.visible = false;
               this.clearFilter();
               break;
            case FriendsWindowState.CLAN_MEMBERS:
               this.acceptedFriendButton.enable = true;
               this.referralsButton.enable = true;
               this.incomingButton.enable = true;
               this.outgoingButton.enable = true;
               this.rejectAllIncomingButton.visible = false;
               this.windowInner.visible = true;
               this.addRequestView.hide();
               this.filterTextInput.visible = true;
               this.clearFilter();
         }
      }
      
      override protected function cancelKeyPressed() : void
      {
         this.onCloseButtonClick();
      }
   }
}
