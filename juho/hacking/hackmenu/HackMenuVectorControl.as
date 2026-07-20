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

   public class HackMenuVectorControl extends Sprite
      {
         private var fields:Array = [];
         private var value:Vector3D;
         private var callback:Function;
   
         public function HackMenuVectorControl(param1:Vector3D, param2:Function)
         {
            this.value = param1;
            this.callback = param2;
            this.addField("X",param1.x,0);
            this.addField("Y",param1.y,104);
            this.addField("Z",param1.z,208);
         }
   
         public function dispose() : void
         {
            var _loc1_:HackMenuNumberField = null;
            for each(_loc1_ in this.fields) _loc1_.dispose();
            this.fields.length = 0;
            this.callback = null;
         }
   
         private function addField(param1:String, param2:Number, param3:Number) : void
         {
            var _loc4_:Label = new Label();
            var _loc5_:HackMenuNumberField;
            _loc4_.text = param1;
            _loc4_.size = 11;
            _loc4_.color = HackMenuTheme.MUTED;
            _loc4_.x = param3;
            _loc4_.y = 7;
            addChild(_loc4_);
            _loc5_ = new HackMenuNumberField(param2,function(param4:Number):void
            {
               if(param1 == "X") value.x = param4;
               else if(param1 == "Y") value.y = param4;
               else value.z = param4;
               if(callback != null) callback(value);
            });
            _loc5_.x = param3 + 16;
            addChild(_loc5_);
            this.fields.push(_loc5_);
         }
      }
}
