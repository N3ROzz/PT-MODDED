package alternativa.tanks.models.weapon.shaft
{
   import alternativa.engine3d.core.Object3D;
   
   public class ShaftVisualSettings
   {
      
      public static var hideLocalLaser:Boolean = false;
      
      private static var hideMapSprites:Boolean = false;
      
      private static const mapSprites:Vector.<Object3D> = new Vector.<Object3D>();
      
      public function ShaftVisualSettings()
      {
         throw new Error("ShaftVisualSettings is a static utility class and cannot be instantiated");
      }
      
      public static function setHideMapSprites(value:Boolean) : void
      {
         var sprite:Object3D = null;
         hideMapSprites = value;
         for each(sprite in mapSprites)
         {
            if(sprite != null)
            {
               sprite.visible = !hideMapSprites;
            }
         }
      }
      
      public static function registerMapSprite(sprite:Object3D) : void
      {
         if(mapSprites.indexOf(sprite) < 0)
         {
            mapSprites.push(sprite);
         }
         sprite.visible = !hideMapSprites;
      }
      
      public static function clearMapSprites() : void
      {
         mapSprites.length = 0;
      }
   }
}
