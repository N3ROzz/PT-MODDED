package alternativa.tanks.gui.panel.buttons
{
   import alternativa.tanks.gui.friends.button.friends.NewRequestIndicator;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   
   public class FriendsTopBarButton extends OriginalMainPanelWideButton
   {
      
      private static const SHOW_FRIENDS_BITMAP:Class = FriendsButton_SHOW_FRIENDS_BITMAP;
      
      private static const SHOW_FRIENDS_BITMAP_DATA:BitmapData = Bitmap(new SHOW_FRIENDS_BITMAP()).bitmapData;
      
      public function FriendsTopBarButton()
      {
         super(SHOW_FRIENDS_BITMAP_DATA);
         this.setOriginalIconCoords(2,2);
         var _loc1_:NewRequestIndicator = new NewRequestIndicator();
         addChild(_loc1_);
         _loc1_.x = 76;
         _loc1_.y = -4;
         mouseChildren = false;
      }
   }
}
