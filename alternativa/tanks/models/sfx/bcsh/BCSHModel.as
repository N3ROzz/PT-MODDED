package alternativa.tanks.models.sfx.bcsh
{
   import alternativa.osgi.service.logging.LogService;
   import flash.filters.BitmapFilter;
   import platform.client.fp10.core.model.ObjectLoadListener;
   import projects.tanks.client.battlefield.models.tankparts.sfx.bcsh.BCSHModelBase;
   import projects.tanks.client.battlefield.models.tankparts.sfx.bcsh.BCSHStruct;
   import projects.tanks.client.battlefield.models.tankparts.sfx.bcsh.IBCSHModelBase;
   
   [ModelInfo]
   public class BCSHModel extends BCSHModelBase implements IBCSHModelBase, ObjectLoadListener, IBcsh
   {
      
      [Inject] // added
      public static var logService:LogService;
      
      public function BCSHModel()
      {
         super();
      }
      
      [Obfuscation(rename="false")]
      public function objectLoaded() : void
      {
         var _loc3_:BCSHStruct = null;
         var _loc1_:Object = {};
         var _loc2_:Vector.<BCSHStruct> = getInitParam().data;
         for each(_loc3_ in _loc2_)
         {
            _loc1_[_loc3_.key] = new BCSHData(_loc3_);
         }
         putData(Object,_loc1_);
      }
      
      public function createFilter(param1:String) : BitmapFilter
      {
         var _loc2_:Object = Object(getData(Object));
         if(_loc2_ == null)
         {
            return null;
         }
         var _loc3_:BCSHData = _loc2_[param1];
         if(_loc3_ != null)
         {
            return _loc3_.createFilter();
         }
         return null;
      }

      public function createFilterForKeys(param1:Array) : BitmapFilter
      {
         var _loc4_:String = null;
         var _loc5_:String = null;
         var _loc2_:Object = Object(getData(Object));
         if(_loc2_ == null)
         {
            return null;
         }
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc4_ = param1[_loc3_];
            if(_loc2_[_loc4_] != null)
            {
               return BCSHData(_loc2_[_loc4_]).createFilter();
            }
            _loc3_++;
         }
         for(_loc5_ in _loc2_)
         {
            return BCSHData(_loc2_[_loc5_]).createFilter();
         }
         return null;
      }
   }
}
