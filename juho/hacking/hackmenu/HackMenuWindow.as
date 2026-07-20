package juho.hacking.hackmenu
{
   import controls.Label;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.Event;
   import juho.hacking.Hack;
   import juho.hacking.HackRegistry;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.dialogs.gui.DialogWindow;

   public class HackMenuWindow extends DialogWindow
   {
      private static const NORMAL_WIDTH:int = 780;
      private static const NORMAL_HEIGHT:int = 540;
      private static const DEVELOPER_WIDTH:int = 840;
      private static const DEVELOPER_HEIGHT:int = 560;
      private static const MIN_WIDTH:int = 640;
      private static const MIN_HEIGHT:int = 460;
      private static const STAGE_MARGIN:int = 16;

      private static var lastSelectedViewId:String;

      private var chrome:Shape;
      private var title:Label;
      private var modeLabel:Label;
      private var sidebar:HackMenuList;
      private var modulePanel:HackMenuItem;
      private var moduleHost:Sprite;
      private var popupHost:Sprite;
      private var hotkeyLabel:Label;
      private var hotkeyChoice:HackMenuChoiceControl;
      private var headerCloseButton:HackMenuButton;
      private var descriptors:Vector.<HackMenuViewDescriptor>;
      private var windowWidth:Number = NORMAL_WIDTH;
      private var windowHeight:Number = NORMAL_HEIGHT;
      private var disposed:Boolean;
      private var attachedStage:Stage;

      public var _closeButton:HackMenuButton;

      public function HackMenuWindow()
      {
         super();

         this.chrome = new Shape();
         this.moduleHost = new Sprite();
         this.popupHost = new Sprite();
         addChild(this.chrome);

         this.sidebar = new HackMenuList(this.onModuleSelected);
         addChild(this.sidebar);

         addChild(this.moduleHost);

         this.title = new Label();
         this.modeLabel = new Label();
         this.title.text = "PROTANKI TOOLS";
         this.title.size = 16;
         this.title.bold = true;
         this.title.color = HackMenuTheme.TEXT;
         addChild(this.title);

         if(HackMenuPresentationMode.CURRENT == HackMenuPresentationMode.DEVELOPER)
         {
            this.modeLabel.text = "DEVELOPER";
            this.modeLabel.size = 10;
            this.modeLabel.color = HackMenuTheme.WARNING;
            addChild(this.modeLabel);
         }
         this.headerCloseButton = new HackMenuButton("X",32,28,HackMenuHotkeyManager.closeMenu);
         addChild(this.headerCloseButton);

         this.hotkeyLabel = new Label();
         this.hotkeyLabel.text = "Hotkey";
         this.hotkeyLabel.size = 12;
         this.hotkeyLabel.color = HackMenuTheme.MUTED;
         addChild(this.hotkeyLabel);

         this._closeButton = new HackMenuButton("Close",96,30);
         addChild(this._closeButton);

         this.hotkeyChoice = new HackMenuChoiceControl(HackMenuHotkeyManager.getHotkeyCode(),this.getHotkeyChoices(),this.onHotkeyChanged,this.popupHost);
         addChild(this.hotkeyChoice);
         addChild(this.popupHost);

         this.setWindowSize(HackMenuPresentationMode.CURRENT == HackMenuPresentationMode.DEVELOPER ? DEVELOPER_WIDTH : NORMAL_WIDTH,HackMenuPresentationMode.CURRENT == HackMenuPresentationMode.DEVELOPER ? DEVELOPER_HEIGHT : NORMAL_HEIGHT);

         this.descriptors = HackMenuCatalog.descriptors(HackRegistry.allHacks);
         lastSelectedViewId = this.sidebar.setDescriptors(this.descriptors,lastSelectedViewId);
         this.showModule(lastSelectedViewId);

         addEventListener(Event.ADDED_TO_STAGE,this.onAddedToStage);
         addEventListener(Event.REMOVED_FROM_STAGE,this.onRemovedFromStage);
      }

      override protected function cancelKeyPressed() : void
      {
         HackMenuHotkeyManager.closeMenu();
      }

      private function onAddedToStage(param1:Event) : void
      {
         this.resizeToStage();
         if(stage != null)
         {
            this.attachedStage = stage;
            this.attachedStage.addEventListener(Event.RESIZE,this.onStageResize,false,0,true);
         }
      }

      private function onRemovedFromStage(param1:Event) : void
      {
         if(this.attachedStage != null)
         {
            this.attachedStage.removeEventListener(Event.RESIZE,this.onStageResize);
            this.attachedStage = null;
         }
         this.disposeContent();
      }

      private function onStageResize(param1:Event) : void
      {
         this.resizeToStage();
      }

      private function resizeToStage() : void
      {
         var _loc1_:Number = HackMenuPresentationMode.CURRENT == HackMenuPresentationMode.DEVELOPER ? DEVELOPER_WIDTH : NORMAL_WIDTH;
         var _loc2_:Number = HackMenuPresentationMode.CURRENT == HackMenuPresentationMode.DEVELOPER ? DEVELOPER_HEIGHT : NORMAL_HEIGHT;
         if(stage != null)
         {
            _loc1_ = Math.min(_loc1_,Math.max(MIN_WIDTH,stage.stageWidth - STAGE_MARGIN * 2));
            _loc2_ = Math.min(_loc2_,Math.max(MIN_HEIGHT,stage.stageHeight - STAGE_MARGIN * 2));
         }
         this.setWindowSize(_loc1_,_loc2_);
      }

      private function setWindowSize(param1:Number, param2:Number) : void
      {
         var _loc3_:Number = HackMenuTheme.HEADER_HEIGHT;
         var _loc4_:Number = HackMenuTheme.FOOTER_HEIGHT;
         var _loc5_:Number = param2 - _loc3_ - _loc4_;
         this.windowWidth = param1;
         this.windowHeight = param2;
         this.drawChrome();

         this.title.x = 18;
         this.title.y = 13;
         this.modeLabel.x = this.title.x + this.title.width + 12;
         this.modeLabel.y = 17;
         this.headerCloseButton.x = param1 - 42;
         this.headerCloseButton.y = 10;

         this.sidebar.x = 0;
         this.sidebar.y = _loc3_;
         this.sidebar.setSize(HackMenuTheme.SIDEBAR_WIDTH,_loc5_);
         this.moduleHost.x = HackMenuTheme.SIDEBAR_WIDTH;
         this.moduleHost.y = _loc3_;
         if(this.modulePanel != null)
         {
            this.modulePanel.setSize(param1 - HackMenuTheme.SIDEBAR_WIDTH,_loc5_);
         }

         this.hotkeyLabel.x = 18;
         this.hotkeyLabel.y = param2 - 33;
         this.hotkeyChoice.x = 72;
         this.hotkeyChoice.y = param2 - 39;
         this._closeButton.x = param1 - 112;
         this._closeButton.y = param2 - 40;
      }

      private function drawChrome() : void
      {
         this.chrome.graphics.clear();
         this.chrome.graphics.lineStyle(1,HackMenuTheme.BORDER);
         this.chrome.graphics.beginFill(HackMenuTheme.WINDOW_BG);
         this.chrome.graphics.drawRoundRect(0,0,this.windowWidth,this.windowHeight,HackMenuTheme.RADIUS,HackMenuTheme.RADIUS);
         this.chrome.graphics.endFill();
         this.chrome.graphics.beginFill(HackMenuTheme.HEADER_BG);
         this.chrome.graphics.drawRect(1,1,this.windowWidth - 2,HackMenuTheme.HEADER_HEIGHT - 1);
         this.chrome.graphics.endFill();
         this.chrome.graphics.beginFill(HackMenuTheme.HEADER_BG);
         this.chrome.graphics.drawRect(1,this.windowHeight - HackMenuTheme.FOOTER_HEIGHT,this.windowWidth - 2,HackMenuTheme.FOOTER_HEIGHT - 1);
         this.chrome.graphics.endFill();
         this.chrome.graphics.beginFill(HackMenuTheme.DIVIDER);
         this.chrome.graphics.drawRect(0,HackMenuTheme.HEADER_HEIGHT,this.windowWidth,1);
         this.chrome.graphics.drawRect(0,this.windowHeight - HackMenuTheme.FOOTER_HEIGHT,this.windowWidth,1);
         this.chrome.graphics.drawRect(HackMenuTheme.SIDEBAR_WIDTH,HackMenuTheme.HEADER_HEIGHT,1,this.windowHeight - HackMenuTheme.HEADER_HEIGHT - HackMenuTheme.FOOTER_HEIGHT);
         this.chrome.graphics.endFill();
      }

      private function onModuleSelected(param1:String) : void
      {
         if(param1 == null || param1 == lastSelectedViewId && this.modulePanel != null)
         {
            return;
         }
         lastSelectedViewId = param1;
         this.showModule(param1);
      }

      private function showModule(param1:String) : void
      {
         var _loc2_:HackMenuViewDescriptor = this.findDescriptor(param1);
         if(_loc2_ == null)
         {
            return;
         }
         this.disposeModulePanel();
         this.modulePanel = new HackMenuItem(_loc2_,this.popupHost);
         this.moduleHost.addChild(this.modulePanel);
         if(this.windowWidth > 0)
         {
            this.modulePanel.setSize(this.windowWidth - HackMenuTheme.SIDEBAR_WIDTH,this.windowHeight - HackMenuTheme.HEADER_HEIGHT - HackMenuTheme.FOOTER_HEIGHT);
         }
      }

      private function findDescriptor(param1:String) : HackMenuViewDescriptor
      {
         var _loc2_:HackMenuViewDescriptor = null;
         for each(_loc2_ in this.descriptors)
         {
            if(_loc2_.viewId == param1)
            {
               return _loc2_;
            }
         }
         return null;
      }

      private function getHotkeyChoices() : Array
      {
         var _loc1_:Array = [];
         var _loc2_:Object = null;
         for each(_loc2_ in HackMenuHotkeyManager.getHotkeyOptions())
         {
            _loc1_.push({id:_loc2_.keyCode,gameName:_loc2_.label});
         }
         return _loc1_;
      }

      private function onHotkeyChanged(param1:*) : void
      {
         HackMenuHotkeyManager.setHotkeyCode(int(param1));
      }

      private function disposeModulePanel() : void
      {
         if(this.modulePanel == null)
         {
            return;
         }
         this.modulePanel.dispose();
         if(this.modulePanel.parent != null)
         {
            this.modulePanel.parent.removeChild(this.modulePanel);
         }
         this.modulePanel = null;
      }

      private function disposeContent() : void
      {
         if(this.disposed)
         {
            return;
         }
         this.disposed = true;
         removeEventListener(Event.ADDED_TO_STAGE,this.onAddedToStage);
         removeEventListener(Event.REMOVED_FROM_STAGE,this.onRemovedFromStage);
         this.disposeModulePanel();
         this.sidebar.dispose();
         this.hotkeyChoice.dispose();
         this.headerCloseButton.dispose();
         this._closeButton.dispose();
      }
   }
}
