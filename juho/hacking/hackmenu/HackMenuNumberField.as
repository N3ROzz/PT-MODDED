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

   public class HackMenuNumberField extends Sprite
      {
         private var bg:Shape;
         private var input:TextField;
         private var callback:Function;
         private var committed:Number = 0;
   
         public function HackMenuNumberField(param1:Number, param2:Function)
         {
            this.bg = new Shape();
            this.input = new TextField();
            this.committed = param1;
            this.callback = param2;
            addChild(this.bg);
            this.draw();
            var _loc3_:TextFormat = TanksFontService.getTextFormat(12);
            _loc3_.color = HackMenuTheme.TEXT;
            this.input.defaultTextFormat = _loc3_;
            this.input.embedFonts = TanksFontService.isEmbedFonts();
            this.input.antiAliasType = AntiAliasType.ADVANCED;
            this.input.gridFitType = GridFitType.PIXEL;
            this.input.type = TextFieldType.INPUT;
            this.input.restrict = "-0-9.";
            this.input.text = String(param1);
            this.input.x = 8;
            this.input.y = 5;
            this.input.width = 94;
            this.input.height = 20;
            addChild(this.input);
            this.input.addEventListener(FocusEvent.FOCUS_OUT,this.onCommit);
            this.input.addEventListener(KeyboardEvent.KEY_DOWN,this.onKeyDown);
         }
   
         public function dispose() : void
         {
            this.input.removeEventListener(FocusEvent.FOCUS_OUT,this.onCommit);
            this.input.removeEventListener(KeyboardEvent.KEY_DOWN,this.onKeyDown);
            this.callback = null;
         }
   
         private function draw() : void
         {
            this.bg.graphics.clear();
            this.bg.graphics.lineStyle(1,HackMenuTheme.BORDER);
            this.bg.graphics.beginFill(HackMenuTheme.SIDEBAR_BG);
            this.bg.graphics.drawRoundRect(0,0,110,28,5,5);
            this.bg.graphics.endFill();
         }
   
         private function onKeyDown(param1:KeyboardEvent) : void
         {
         if(param1.keyCode == Keyboard.ENTER)
         {
            this.commit();
            if(this.input.stage != null)
            {
               this.input.stage.focus = null;
            }
         }
         }
   
         private function onCommit(param1:FocusEvent) : void { this.commit(); }
   
         private function commit() : void
         {
            var _loc1_:Number = Number(this.input.text);
            if(isNaN(_loc1_) || !isFinite(_loc1_))
            {
               this.input.text = String(this.committed);
               return;
            }
            if(_loc1_ == this.committed) return;
            this.committed = _loc1_;
            this.input.text = String(_loc1_);
            if(this.callback != null) this.callback(_loc1_);
         }
      }
}
