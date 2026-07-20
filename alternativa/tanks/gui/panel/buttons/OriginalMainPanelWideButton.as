package alternativa.tanks.gui.panel.buttons
{
   import controls.Label;
   import controls.base.TankBaseButton;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.filters.DropShadowFilter;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormatAlign;
   
   public class OriginalMainPanelWideButton extends TankBaseButton
   {
      
      public function OriginalMainPanelWideButton(param1:BitmapData)
      {
         this._icon = new Bitmap(param1);
         super();
         this.setIconCoords(3,2);
      }
      
      override public function set label(param1:String) : void
      {
         var _loc2_:Label = this._label;
         _loc2_.autoSize = TextFieldAutoSize.NONE;
         _loc2_.align = TextFormatAlign.CENTER;
         _loc2_.height = 19;
         _loc2_.x = 18;
         _loc2_.y = 4;
         _loc2_.width = 69;
         _loc2_.mouseEnabled = false;
         _loc2_.filters = [new DropShadowFilter(1,45,0,0.7,1,1,1)];
         _loc2_.text = param1;
      }
      
      protected function setOriginalIconCoords(param1:int, param2:int) : void
      {
         this.setIconCoords(param1,param2);
      }
   }
}
