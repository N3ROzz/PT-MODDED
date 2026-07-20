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

   public class HackMenuToggle extends Sprite
      {
         private var track:Shape = new Shape();
         private var knob:Shape = new Shape();
         private var callback:Function;
         private var _checked:Boolean;
   
         public function HackMenuToggle(param1:Boolean, param2:Function)
         {
            this._checked = param1;
            this.callback = param2;
            addChild(this.track);
            addChild(this.knob);
            buttonMode = true;
            mouseChildren = false;
            addEventListener(MouseEvent.CLICK,this.onClick);
            this.draw();
         }
   
         public function get checked() : Boolean { return this._checked; }
         public function set checked(param1:Boolean) : void { this._checked = param1; this.draw(); }
   
         public function dispose() : void
         {
            removeEventListener(MouseEvent.CLICK,this.onClick);
            this.callback = null;
         }
   
         private function onClick(param1:MouseEvent) : void
         {
            this._checked = !this._checked;
            this.draw();
            if(this.callback != null) this.callback(this._checked);
         }
   
         private function draw() : void
         {
            this.track.graphics.clear();
            this.track.graphics.beginFill(this._checked ? HackMenuTheme.ACTIVE : HackMenuTheme.DISABLED);
            this.track.graphics.drawRoundRect(0,0,42,22,11,11);
            this.track.graphics.endFill();
            this.knob.graphics.clear();
            this.knob.graphics.beginFill(0xFFFFFF);
            this.knob.graphics.drawCircle(this._checked ? 31 : 11,11,8);
            this.knob.graphics.endFill();
         }
      }
}
