package alternativa.tanks.models.sfx.bcsh
{
   import flash.filters.BitmapFilter;
   
   [ModelInterface]
   public interface IBcsh
   {
      
      function createFilter(param1:String) : BitmapFilter;

      function createFilterForKeys(param1:Array) : BitmapFilter;
   }
}
