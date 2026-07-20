package juho.hacking.hacks
{
   import alternativa.tanks.models.weapon.shaft.ShaftAimFovSettings;
   import alternativa.tanks.models.weapon.shaft.ShaftVisualSettings;
   import juho.hacking.Hack;
   
   public class ShaftFovHack extends Hack
   {
      
      private static const NAME:String = "Shaft FOV";
      
      private static const ID:String = "SHAFT_FOV";
      
      private static const PROP_MULTIPLIER:String = "Aim FOV";
      
      private static const PROP_HIDE_LASER:String = "Hide Laser";
      
      private static const PROP_HIDE_SPRITES:String = "Hide Map Sprites";
      
      public function ShaftFovHack()
      {
         super(NAME,ID);
         var hasSavedState:Boolean = this.hasSavedEnabledState();
         this.addSliderProperty(PROP_MULTIPLIER,ShaftAimFovSettings.DEFAULT_MULTIPLIER,ShaftAimFovSettings.MIN_MULTIPLIER,ShaftAimFovSettings.MAX_MULTIPLIER,ShaftAimFovSettings.STEP,this.multiplierChanged);
         this.addProperty(PROP_HIDE_LASER,false,"Boolean",this.hideLaserChanged);
         this.addProperty(PROP_HIDE_SPRITES,false,"Boolean",this.hideSpritesChanged);
         if(!hasSavedState)
         {
            this.enable();
         }
         else
         {
            this.applyState();
         }
      }
      
      override public function enable() : void
      {
         super.enable();
         this.applyState();
      }
      
      override public function disable() : void
      {
         super.disable();
         this.applyState();
      }
      
      private function multiplierChanged(value:*) : void
      {
         this.applyState();
      }
      
      private function hideLaserChanged(value:*) : void
      {
         this.applyState();
      }
      
      private function hideSpritesChanged(value:*) : void
      {
         this.applyState();
      }
      
      private function applyState() : void
      {
         ShaftAimFovSettings.enabled = this.isEnabled;
         ShaftAimFovSettings.multiplier = Number(this.getProperty(PROP_MULTIPLIER).value);
         ShaftVisualSettings.hideLocalLaser = this.isEnabled && Boolean(this.getProperty(PROP_HIDE_LASER).value);
         ShaftVisualSettings.setHideMapSprites(this.isEnabled && Boolean(this.getProperty(PROP_HIDE_SPRITES).value));
      }
   }
}
