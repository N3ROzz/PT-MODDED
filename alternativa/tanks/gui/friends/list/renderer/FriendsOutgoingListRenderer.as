package alternativa.tanks.gui.friends.list.renderer
{
   import alternativa.tanks.gui.friends.FriendActionIndicator;
   import alternativa.tanks.gui.friends.list.renderer.background.RendererBackGroundOutgoingList;
   import fl.controls.listClasses.CellRenderer;
   import fl.controls.listClasses.ListData;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import forms.ColorConstants;
   import forms.userlabel.UserLabel;
   import services.contextmenu.IContextMenuService;
   
   public class FriendsOutgoingListRenderer extends CellRenderer
   {
      
      [Inject] // added
      public static var contextMenuService:IContextMenuService;
      
      private var _labelsContainer:DisplayObject;
      
      private var _userLabel:UserLabel;
      
      private var _cancelRequestIndicator:FriendActionIndicator;
      
      public function FriendsOutgoingListRenderer()
      {
         super();
      }
      
      override public function set data(param1:Object) : void
      {
         _data = param1;
         mouseEnabled = false;
         mouseChildren = true;
         buttonMode = useHandCursor = false;
         var _loc2_:RendererBackGroundOutgoingList = new RendererBackGroundOutgoingList(false);
         var _loc3_:RendererBackGroundOutgoingList = new RendererBackGroundOutgoingList(true);
         setStyle("upSkin",_loc2_);
         setStyle("downSkin",_loc2_);
         setStyle("overSkin",_loc2_);
         setStyle("selectedUpSkin",_loc3_);
         setStyle("selectedOverSkin",_loc3_);
         setStyle("selectedDownSkin",_loc3_);
         this._labelsContainer = this.createLabels(_data);
         if(this._cancelRequestIndicator == null)
         {
            this._cancelRequestIndicator = new FriendActionIndicator(FriendActionIndicator.NO);
            addChild(this._cancelRequestIndicator);
         }
         this._cancelRequestIndicator.visible = false;
         this.addEventListener(Event.RESIZE,this.onResize,false,0,true);
         this.addEventListener(MouseEvent.ROLL_OVER,this.onRollOver,false,0,true);
         this.addEventListener(MouseEvent.ROLL_OUT,this.onRollOut,false,0,true);
         this.resize();
         this._cancelRequestIndicator.addEventListener(MouseEvent.CLICK,this.onClickCancelRequest,false,0,true);
      }
      
      private function onResize(param1:Event) : void
      {
         this.resize();
      }
      
      private function resize() : void
      {
         this._cancelRequestIndicator.x = _width - this._cancelRequestIndicator.width - 6;
      }
      
      private function createLabels(param1:Object) : Sprite
      {
         var _loc2_:Sprite = new Sprite();
         if(param1.id != null)
         {
            this._userLabel = new UserLabel(param1.id);
            this._userLabel.x = -3;
            this._userLabel.y = -1;
            _loc2_.addChild(this._userLabel);
            this._userLabel.setUidColor(ColorConstants.GREEN_LABEL);
         }
         return _loc2_;
      }
      
      private function onRollOver(param1:MouseEvent) : void
      {
         this._cancelRequestIndicator.visible = true;
         super.selected = true;
      }
      
      private function onRollOut(param1:MouseEvent) : void
      {
         this._cancelRequestIndicator.visible = false;
         super.selected = false;
      }
      
      private function onClickCancelRequest(param1:MouseEvent) : void
      {
         contextMenuService.cancelRequest(this._userLabel.userId,this._userLabel.uid);
      }
      
      override public function set listData(param1:ListData) : void
      {
         _listData = param1;
         label = _listData.label;
         if(this._labelsContainer != null)
         {
            setStyle("icon",this._labelsContainer);
         }
      }
      
      override protected function drawBackground() : void
      {
         var _loc1_:String = enabled ? mouseState : "disabled";
         if(selected)
         {
            _loc1_ = "selected" + _loc1_.substr(0,1).toUpperCase() + _loc1_.substr(1);
         }
         _loc1_ += "Skin";
         var _loc2_:DisplayObject = background;
         background = getDisplayObjectInstance(getStyleValue(_loc1_));
         addChildAt(background,0);
         if(_loc2_ != null && _loc2_ != background)
         {
            removeChild(_loc2_);
         }
      }
      
      override public function set selected(param1:Boolean) : void
      {
      }
   }
}
