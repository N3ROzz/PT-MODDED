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

   public class HackMenuChoiceControl extends Sprite
      {
         private var button:HackMenuButton;
         private var choices:Array;
         private var callback:Function;
         private var popupHost:Sprite;
         private var popup:Sprite;
         private var value:*;
   
         public function HackMenuChoiceControl(param1:*, param2:Array, param3:Function, param4:Sprite)
         {
            this.value = param1;
            this.choices = param2;
            this.callback = param3;
            this.popupHost = param4;
            this.button = new HackMenuButton(this.currentLabel(),150,28,this.togglePopup);
            addChild(this.button);
         }
   
         public function dispose() : void
         {
            this.closePopup();
            this.button.dispose();
            this.callback = null;
            this.popupHost = null;
         }
   
         private function currentLabel() : String
         {
            var _loc1_:Object = null;
            for each(_loc1_ in this.choices)
            {
               if(_loc1_.id == this.value) return String(_loc1_.gameName);
            }
            return this.choices.length > 0 ? String(this.choices[0].gameName) : "No options";
         }
   
         private function togglePopup() : void
         {
            if(this.popup != null) this.closePopup(); else this.openPopup();
         }
   
         private function openPopup() : void
         {
            var _loc1_:Point;
            var _loc2_:Object = null;
            var _loc3_:HackMenuButton = null;
            var _loc4_:Shape = null;
            if(this.popupHost == null || this.choices.length == 0) return;
            this.popup = new Sprite();
            _loc4_ = new Shape();
            _loc4_.graphics.lineStyle(1,HackMenuTheme.BORDER);
            _loc4_.graphics.beginFill(HackMenuTheme.SIDEBAR_BG);
            _loc4_.graphics.drawRoundRect(0,0,154,this.choices.length * 29 + 4,5,5);
            _loc4_.graphics.endFill();
            this.popup.addChild(_loc4_);
            for each(_loc2_ in this.choices)
            {
               _loc3_ = new HackMenuButton(String(_loc2_.gameName),150,27,this.choose,[ _loc2_.id ]);
               _loc3_.x = 2;
               _loc3_.y = 2 + (this.popup.numChildren - 1) * 29;
               this.popup.addChild(_loc3_);
            }
            _loc1_ = this.localToGlobal(new Point(0,30));
            _loc1_ = this.popupHost.globalToLocal(_loc1_);
            this.popup.x = _loc1_.x;
            if(this.popupHost.parent != null && _loc1_.y + this.popup.height > this.popupHost.parent.height - 4)
            {
               this.popup.y = Math.max(4,_loc1_.y - this.popup.height - 30);
            }
            else
            {
               this.popup.y = _loc1_.y;
            }
            this.popupHost.addChild(this.popup);
         }
   
         private function choose(param1:*) : void
         {
            this.value = param1;
            this.button.label = this.currentLabel();
            this.closePopup();
            if(this.callback != null) this.callback(param1);
         }
   
         private function closePopup() : void
         {
            var _loc1_:HackMenuButton = null;
            if(this.popup == null) return;
            while(this.popup.numChildren > 0)
            {
               _loc1_ = this.popup.getChildAt(this.popup.numChildren - 1) as HackMenuButton;
               if(_loc1_ != null) _loc1_.dispose();
               this.popup.removeChildAt(this.popup.numChildren - 1);
            }
            if(this.popup.parent != null) this.popup.parent.removeChild(this.popup);
            this.popup = null;
         }
      }
}
