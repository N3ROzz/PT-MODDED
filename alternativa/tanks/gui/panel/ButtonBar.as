package alternativa.tanks.gui.panel
{
   import alternativa.osgi.service.locale.ILocaleService;
   import alternativa.tanks.gui.panel.buttons.FriendsTopBarButton;
   import alternativa.tanks.gui.panel.buttons.MainPanelFullscreenButton;
   import alternativa.tanks.gui.panel.buttons.MissionsTextButton;
   import alternativa.tanks.gui.panel.buttons.ShopBarButton;
   import controls.base.MainPanelBattlesButtonBase;
   import controls.base.MainPanelGarageButtonBase;
   import controls.panel.BaseButton;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import forms.*;
   import forms.events.MainButtonBarEvents;
   import projects.tanks.clients.fp10.libraries.TanksLocale;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.clan.ClanUserInfoService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.fullscreen.FullscreenService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.userproperties.IUserPropertiesService;
   import services.buttonbar.IButtonBarService;
   import alternativa.tanks.gui.panel.buttons.ClanButton;
   
   public class ButtonBar extends Sprite
   {
      
      [Inject] // added
      public static var localeService:ILocaleService;
      
      [Inject] // added
      public static var buttonBarService:IButtonBarService;
      
      [Inject] // added
      public static var fullscreenService:FullscreenService;
      
      [Inject] // added
      public static var userPropertiesService:IUserPropertiesService;

      [Inject] // added
      public static var clanUserInfoService:ClanUserInfoService;
      
      private static const SECTION_BUTTON_GAP:int = 6;
      
      public var battlesButton:MainPanelBattlesButtonBase = new MainPanelBattlesButtonBase();
      
      public var garageButton:MainPanelGarageButtonBase = new MainPanelGarageButtonBase();
      
      public var clanButton:ClanButton = new ClanButton();
      
      public var settingsButton:MainPanelConfigButton = new MainPanelConfigButton();
      
      public var closeButton:CloseOrBackButton = new CloseOrBackButton();
      
      public var fullScreenButton:MainPanelFullscreenButton = new MainPanelFullscreenButton();
      
      private var soundButton:MainPanelSoundButton = new MainPanelSoundButton();
      
      private var helpButton:MainPanelHelpButton = new MainPanelHelpButton();
      
      private var shopButton:ShopBarButton = new ShopBarButton();
      
      private var questsButton:MissionsTextButton = new MissionsTextButton();
      
      private var friendsButton:FriendsTopBarButton = new FriendsTopBarButton();
      
      private var _soundOn:Boolean = true;
      
      private var soundIcon:MovieClip;
      
      public function ButtonBar()
      {
         super();
         addChild(this.shopButton);
         addChild(this.questsButton);
         addChild(this.friendsButton);
         addChild(this.battlesButton);
         addChild(this.garageButton);
         addChild(this.clanButton);
         addChild(this.settingsButton);
         addChild(this.soundButton);
         addChild(this.fullScreenButton);
         addChild(this.helpButton);
         addChild(this.closeButton);
         this.shopButton.type = 1;
         this.shopButton.label = "Buy";
         this.shopButton.addEventListener(MouseEvent.CLICK,this.listClick);
         this.battlesButton.type = 2;
         this.battlesButton.label = localeService.getText(TanksLocale.TEXT_MAIN_PANEL_BUTTON_BATTLES);
         this.battlesButton.enable = false;
         this.battlesButton.addEventListener(MouseEvent.CLICK,this.listClick);
         this.garageButton.type = 3;
         this.garageButton.label = localeService.getText(TanksLocale.TEXT_MAIN_PANEL_BUTTON_GARAGE);
         this.garageButton.addEventListener(MouseEvent.CLICK,this.listClick);
         this.clanButton.type = 11;
         this.clanButton.label = localeService.getText(TanksLocale.TEXT_CLAN);
         this.clanButton.addEventListener(MouseEvent.CLICK,this.listClick);
         this.clanButton.enable = true;
         this.clanButton.visible = true;
         this.questsButton.type = 10;
         this.questsButton.label = "Missions";
         this.questsButton.addEventListener(MouseEvent.CLICK,this.listClick);
         this.friendsButton.type = 8;
         this.friendsButton.label = "Friends";
         this.friendsButton.addEventListener(MouseEvent.CLICK,this.listClick);
         this.settingsButton.type = 4;
         this.settingsButton.addEventListener(MouseEvent.CLICK,this.listClick);
         this.soundButton.type = 5;
         this.soundButton.addEventListener(MouseEvent.CLICK,this.listClick);
         this.soundIcon = this.soundButton.getChildByName("icon") as MovieClip;
         this.fullScreenButton.type = 9;
         this.fullScreenButton.addEventListener(MouseEvent.CLICK,this.listClick);
         this.helpButton.type = 6;
         this.helpButton.addEventListener(MouseEvent.CLICK,this.listClick);
         this.closeButton.addEventListener(MouseEvent.CLICK,this.listClick);
         this.draw();
      }
      
      public function draw() : void
      {
         //this.questsButton.visible = userPropertiesService.isQuestsAvailableByRank();
         this.shopButton.x = 0;
         this.questsButton.x = this.shopButton.x + (this.shopButton.visible ? this.shopButton.width + 7 : 0);
         this.friendsButton.x = this.questsButton.x + (this.questsButton.visible ? this.questsButton.width : 0);
         this.battlesButton.x = this.friendsButton.x + this.friendsButton.width;
         this.garageButton.x = this.battlesButton.x + this.battlesButton.width;
         var _loc1_:Number = this.garageButton.x + this.garageButton.width + SECTION_BUTTON_GAP;
         this.clanButton.x = _loc1_;
         if(this.clanButton.visible)
         {
            _loc1_ = this.clanButton.x + this.clanButton.width + 2;
         }
         this.settingsButton.x = _loc1_;
         this.soundButton.x = this.settingsButton.x + this.settingsButton.width;
         this.fullScreenButton.x = this.soundButton.x + this.soundButton.width;
         this.helpButton.x = this.fullScreenButton.x + this.fullScreenButton.width;
         this.closeButton.x = this.helpButton.x + this.helpButton.width + 6;
         this.soundIcon.gotoAndStop(this.soundOn ? 1 : 2);
      }
      
      public function hidePaymentButton() : void
      {
         this.shopButton.width = 0;
         this.shopButton.visible = false;
         this.draw();
         this.resizeParentPanel();
      }
      
      public function hideClanButton() : void
      {
         this.showClanButton();
      }
      
      public function showClanButton() : void
      {
         this.clanButton.enable = true;
         this.clanButton.visible = true;
         this.draw();
         this.resizeParentPanel();
      }

      private function resizeParentPanel() : void
      {
         if(parent != null && parent is MainPanel)
         {
            MainPanel(parent).resize();
         }
      }
      
      public function set soundOn(param1:Boolean) : void
      {
         this._soundOn = param1;
         this.draw();
      }
      
      public function get soundOn() : Boolean
      {
         return this._soundOn;
      }
      
      private function listClick(param1:MouseEvent) : void
      {
         var _loc2_:Object = param1.currentTarget;
         if(_loc2_ == this.clanButton)
         {
            return;
         }
         if(Boolean(_loc2_.enable) || _loc2_ is BaseButton && _loc2_.selected)
         {
            dispatchEvent(new MainButtonBarEvents(_loc2_.type));
            buttonBarService.change(_loc2_.type);
         }
         if(_loc2_ == this.soundButton)
         {
            this.soundOn = !this.soundOn;
         }
      }
   }
}
