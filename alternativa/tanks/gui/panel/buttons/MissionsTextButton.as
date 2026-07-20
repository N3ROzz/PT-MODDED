package alternativa.tanks.gui.panel.buttons
{
   import alternativa.tanks.gui.dailyquests.DailyQuestChangesIndicator;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   
   public class MissionsTextButton extends OriginalMainPanelWideButton
   {
      
      private static const startIconClass:Class = DailyQuestsButton_startIconClass;
      
      private static const startIcon:BitmapData = Bitmap(new startIconClass()).bitmapData;
      
      public function MissionsTextButton()
      {
         super(startIcon);
         this.setOriginalIconCoords(3,4);
         var _loc1_:DailyQuestChangesIndicator = new DailyQuestChangesIndicator();
         addChild(_loc1_);
         _loc1_.x = 72;
         _loc1_.y = -4;
      }
   }
}
