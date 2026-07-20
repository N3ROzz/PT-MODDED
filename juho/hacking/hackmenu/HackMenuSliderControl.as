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

   public class HackMenuSliderControl extends Sprite
      {
         private var track:Shape = new Shape();
         private var fill:Shape = new Shape();
         private var thumb:Shape = new Shape();
         private var valueLabel:Label = new Label();
         private var callback:Function;
         private var min:Number = 0;
         private var max:Number = 0;
         private var step:Number = 0;
         private var value:Number = 0;
         private var suffix:String;
         private var dragging:Boolean;
         private const trackWidth:Number = 210;
   
         public function HackMenuSliderControl(param1:Number, param2:Number, param3:Number, param4:Number, param5:Function, param6:String)
         {
            this.value = param1;
            this.min = param2;
            this.max = param3;
            this.step = param4;
            this.callback = param5;
            this.suffix = param6;
            addChild(this.track);
            addChild(this.fill);
            addChild(this.thumb);
            this.valueLabel.size = 12;
            this.valueLabel.color = HackMenuTheme.TEXT;
            this.valueLabel.x = 222;
            this.valueLabel.y = 4;
            addChild(this.valueLabel);
         this.thumb.addEventListener(MouseEvent.MOUSE_DOWN,this.onDown);
            this.track.addEventListener(MouseEvent.MOUSE_DOWN,this.onDown);
            this.fill.addEventListener(MouseEvent.MOUSE_DOWN,this.onDown);
            this.draw();
         }
   
         public function dispose() : void
         {
            this.thumb.removeEventListener(MouseEvent.MOUSE_DOWN,this.onDown);
            this.track.removeEventListener(MouseEvent.MOUSE_DOWN,this.onDown);
            this.fill.removeEventListener(MouseEvent.MOUSE_DOWN,this.onDown);
            if(stage != null)
            {
               stage.removeEventListener(MouseEvent.MOUSE_MOVE,this.onMove);
               stage.removeEventListener(MouseEvent.MOUSE_UP,this.onUp);
            }
            this.callback = null;
         }
   
         private function onDown(param1:MouseEvent) : void
         {
            if(stage == null) return;
            this.dragging = true;
            stage.addEventListener(MouseEvent.MOUSE_MOVE,this.onMove);
            stage.addEventListener(MouseEvent.MOUSE_UP,this.onUp);
            this.updateFromMouse();
         }
   
         private function onMove(param1:MouseEvent) : void
         {
            if(this.dragging) this.updateFromMouse();
         }
   
         private function onUp(param1:MouseEvent) : void
         {
            this.dragging = false;
            if(stage != null)
            {
               stage.removeEventListener(MouseEvent.MOUSE_MOVE,this.onMove);
               stage.removeEventListener(MouseEvent.MOUSE_UP,this.onUp);
            }
         }
   
         private function updateFromMouse() : void
         {
            var _loc1_:Number = Math.max(0,Math.min(this.trackWidth,this.mouseX));
            var _loc2_:Number = this.min + _loc1_ / this.trackWidth * (this.max - this.min);
            if(this.step > 0) _loc2_ = Math.round(_loc2_ / this.step) * this.step;
            _loc2_ = Math.max(this.min,Math.min(this.max,_loc2_));
            if(_loc2_ == this.value) return;
            this.value = Number(_loc2_.toFixed(2));
            this.draw();
            if(this.callback != null) this.callback(this.value);
         }
   
         private function draw() : void
         {
            var _loc1_:Number = this.max == this.min ? 0 : (this.value - this.min) / (this.max - this.min) * this.trackWidth;
            this.track.graphics.clear();
            this.track.graphics.beginFill(HackMenuTheme.DISABLED);
            this.track.graphics.drawRoundRect(0,10,this.trackWidth,4,4,4);
            this.track.graphics.endFill();
         this.fill.graphics.clear();
         if(_loc1_ > 0 && isFinite(_loc1_))
         {
            this.fill.graphics.beginFill(HackMenuTheme.ACCENT);
            this.fill.graphics.drawRoundRect(0,10,_loc1_,4,4,4);
            this.fill.graphics.endFill();
         }
            this.thumb.graphics.clear();
            this.thumb.graphics.beginFill(HackMenuTheme.TEXT);
            this.thumb.graphics.drawCircle(_loc1_,12,7);
            this.thumb.graphics.endFill();
            this.valueLabel.text = this.format(this.value) + (this.suffix.length > 0 ? " " + this.suffix : "");
         }
   
         private function format(param1:Number) : String
         {
            return Math.abs(param1 - Math.round(param1)) < 0.001 ? String(Math.round(param1)) : String(Number(param1.toFixed(2)));
         }
      }
}
