package alternativa.tanks.models.weapon.shaft
{
   public class ShaftAimFovSettings
   {
      
      public static const DEFAULT_MULTIPLIER:Number = 2;
      
      public static const MIN_MULTIPLIER:Number = 1;
      
      public static const MAX_MULTIPLIER:Number = 3;
      
      public static const STEP:Number = 0.1;
      
      private static const MAX_AIM_FOV:Number = Math.PI / 2;
      
      public static var enabled:Boolean = true;
      
      public static var multiplier:Number = DEFAULT_MULTIPLIER;
      
      public function ShaftAimFovSettings()
      {
         throw new Error("ShaftAimFovSettings is a static utility class and cannot be instantiated");
      }
      
      public static function getWideAimFov(param1:Number) : Number
      {
         if(!enabled)
         {
            return param1;
         }
         return Math.min(param1 * multiplier,MAX_AIM_FOV);
      }
   }
}
