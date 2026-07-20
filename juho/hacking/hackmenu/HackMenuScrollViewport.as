package juho.hacking.hackmenu
{
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;

   public class HackMenuScrollViewport extends Sprite
   {
      public var content:Sprite = new Sprite();
      public var viewWidth:Number = 0;

      private var maskShape:Shape = new Shape();
      private var scrollbar:Shape = new Shape();
      private var contentHeight:Number = 0;
      private var viewHeight:Number = 0;
      private var scrollY:Number = 0;

      public function HackMenuScrollViewport()
      {
         super();
         addChild(this.content);
         addChild(this.maskShape);
         addChild(this.scrollbar);
         this.content.mask = this.maskShape;
         addEventListener(MouseEvent.MOUSE_WHEEL,this.onWheel);
      }

      public function setSize(param1:Number, param2:Number) : void
      {
         this.viewWidth = param1;
         this.viewHeight = param2;
         this.maskShape.graphics.clear();
         this.maskShape.graphics.beginFill(0);
         this.maskShape.graphics.drawRect(0,0,param1,param2);
         this.maskShape.graphics.endFill();
         this.clampScroll();
         this.drawScrollbar();
      }

      public function setContentHeight(param1:Number) : void
      {
         this.contentHeight = param1;
         this.clampScroll();
         this.drawScrollbar();
      }

      public function dispose() : void
      {
         removeEventListener(MouseEvent.MOUSE_WHEEL,this.onWheel);
         this.content.mask = null;
      }

      private function onWheel(param1:MouseEvent) : void
      {
         if(this.contentHeight <= this.viewHeight)
         {
            return;
         }
         this.scrollY += param1.delta * 24;
         this.clampScroll();
         this.drawScrollbar();
      }

      private function clampScroll() : void
      {
         var _loc1_:Number = Math.min(0,this.viewHeight - this.contentHeight);
         this.scrollY = Math.max(_loc1_,Math.min(0,this.scrollY));
         this.content.y = this.scrollY;
      }

      private function drawScrollbar() : void
      {
         var _loc1_:Number;
         var _loc2_:Number;
         this.scrollbar.graphics.clear();
         if(this.contentHeight <= this.viewHeight || this.viewHeight <= 0)
         {
            return;
         }
         _loc1_ = Math.max(28,this.viewHeight * this.viewHeight / this.contentHeight);
         _loc2_ = -this.scrollY / (this.contentHeight - this.viewHeight) * (this.viewHeight - _loc1_);
         this.scrollbar.graphics.beginFill(HackMenuTheme.BORDER);
         this.scrollbar.graphics.drawRoundRect(this.viewWidth - 4,_loc2_,4,_loc1_,4,4);
         this.scrollbar.graphics.endFill();
      }
   }
}
