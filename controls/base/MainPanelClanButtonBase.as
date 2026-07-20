package controls.base
{
   import alternativa.tanks.gui.panel.buttons.MainPanelSmallButton;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   
   public class MainPanelClanButtonBase extends MainPanelSmallButton
   {
      
      private static var iconClass:Class = MainPanelClanButtonBase_iconClass;
      
      private static var iconData:BitmapData = Bitmap(new iconClass()).bitmapData;
      
      public function MainPanelClanButtonBase()
      {
         super(iconData,6,3);
      }
      
      override public function set label(param1:String) : void
      {
      }
      
      protected function setIconCoords(param1:int, param2:int) : void
      {
         if(_icon != null)
         {
            _icon.x = param1;
            _icon.y = param2;
         }
      }
   }
}
