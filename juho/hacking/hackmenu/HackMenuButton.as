package juho.hacking.hackmenu
{
   import controls.Label;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.FocusEvent;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.geom.Vector3D;
   import flash.text.AntiAliasType;
   import flash.text.GridFitType;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;
   import flash.ui.Keyboard;
   import fonts.TanksFontService;

   public class HackMenuButton extends Sprite
      {
         private var bg:Shape;
         private var textLabel:Label;
         private var callback:Function;
         private var args:Array;
         private var w:Number = 0;
         private var h:Number = 0;
         private var over:Boolean;
   
         public function HackMenuButton(param1:String, param2:Number, param3:Number, param4:Function = null, param5:Array = null)
         {
            this.bg = new Shape();
            this.textLabel = new Label();
            this.w = param2;
            this.h = param3;
            this.callback = param4;
            this.args = param5;
            addChild(this.bg);
            this.textLabel.size = 12;
            this.textLabel.bold = true;
            this.textLabel.color = HackMenuTheme.TEXT;
            addChild(this.textLabel);
            this.label = param1;
            buttonMode = true;
            mouseChildren = false;
            addEventListener(MouseEvent.CLICK,this.onClick);
            addEventListener(MouseEvent.MOUSE_OVER,this.onOver);
            addEventListener(MouseEvent.MOUSE_OUT,this.onOut);
            this.draw();
         }
   
         public function set label(param1:String) : void
         {
            this.textLabel.text = param1;
            this.textLabel.x = Math.round((this.w - this.textLabel.width) / 2);
            this.textLabel.y = Math.round((this.h - this.textLabel.height) / 2) - 1;
         }
   
         public function dispose() : void
         {
            removeEventListener(MouseEvent.CLICK,this.onClick);
            removeEventListener(MouseEvent.MOUSE_OVER,this.onOver);
            removeEventListener(MouseEvent.MOUSE_OUT,this.onOut);
            this.callback = null;
            this.args = null;
         }
   
         private function draw() : void
         {
            this.bg.graphics.clear();
            this.bg.graphics.lineStyle(1,HackMenuTheme.BORDER);
            this.bg.graphics.beginFill(this.over ? HackMenuTheme.ROW_HOVER : HackMenuTheme.ROW_BG);
            this.bg.graphics.drawRoundRect(0,0,this.w,this.h,5,5);
            this.bg.graphics.endFill();
         }
   
         private function onClick(param1:MouseEvent) : void
         {
            if(this.callback != null) this.callback.apply(null,this.args == null ? [] : this.args);
         }
         private function onOver(param1:MouseEvent) : void { this.over = true; this.draw(); }
         private function onOut(param1:MouseEvent) : void { this.over = false; this.draw(); }
      }
}
