package juho.hacking.hackmenu
{
   import controls.Label;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;

   public class HackMenuSidebarButton extends Sprite
      {
      public var descriptor:HackMenuViewDescriptor;
      private var bg:Shape = new Shape();
      private var accent:Shape = new Shape();
      private var title:Label = new Label();
      private var callback:Function;
      private var over:Boolean;
      private var _selected:Boolean;
      private var w:Number = 0;
      private var h:Number = 0;
   
      public function HackMenuSidebarButton(param1:HackMenuViewDescriptor, param2:Function)
      {
         this.descriptor = param1;
         this.callback = param2;
         addChild(this.bg);
         addChild(this.accent);
         this.title.text = param1.title;
         this.title.size = 13;
         this.title.color = HackMenuTheme.TEXT;
         addChild(this.title);
         buttonMode = true;
         mouseChildren = false;
         addEventListener(MouseEvent.CLICK,this.onClick);
         addEventListener(MouseEvent.MOUSE_OVER,this.onOver);
         addEventListener(MouseEvent.MOUSE_OUT,this.onOut);
      }
   
      public function set selected(param1:Boolean) : void
      {
         this._selected = param1;
         this.draw();
      }
   
      public function get selected() : Boolean
      {
         return this._selected;
      }
   
      public function setSize(param1:Number, param2:Number) : void
      {
         this.w = param1;
         this.h = param2;
         this.title.x = 13;
         this.title.y = 8;
         this.draw();
      }
   
      public function dispose() : void
      {
         removeEventListener(MouseEvent.CLICK,this.onClick);
         removeEventListener(MouseEvent.MOUSE_OVER,this.onOver);
         removeEventListener(MouseEvent.MOUSE_OUT,this.onOut);
         this.callback = null;
      }
   
      private function draw() : void
      {
         this.bg.graphics.clear();
         this.accent.graphics.clear();
         if(isNaN(this.w) || isNaN(this.h) || !isFinite(this.w) || !isFinite(this.h) || this.w <= 0 || this.h <= 0)
         {
            return;
         }
         this.bg.graphics.beginFill(this._selected ? HackMenuTheme.ROW_BG : (this.over ? HackMenuTheme.ROW_HOVER : HackMenuTheme.SIDEBAR_BG));
         this.bg.graphics.drawRoundRect(0,0,this.w,this.h,6,6);
         this.bg.graphics.endFill();
         if(this._selected)
         {
            this.accent.graphics.beginFill(HackMenuTheme.ACCENT);
            this.accent.graphics.drawRoundRect(0,5,3,this.h - 10,3,3);
            this.accent.graphics.endFill();
         }
         this.title.color = this._selected ? HackMenuTheme.TEXT : HackMenuTheme.MUTED;
      }
   
      private function onClick(param1:MouseEvent) : void
      {
         if(this.callback != null) this.callback(this.descriptor.viewId);
      }
   
      private function onOver(param1:MouseEvent) : void
      {
         this.over = true;
         this.draw();
      }
   
      private function onOut(param1:MouseEvent) : void
      {
         this.over = false;
         this.draw();
      }
      }
}
