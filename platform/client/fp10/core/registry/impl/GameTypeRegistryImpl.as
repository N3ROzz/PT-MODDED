package platform.client.fp10.core.registry.impl
{
   import alternativa.types.Long;
   import flash.utils.Dictionary;
   import platform.client.fp10.core.registry.GameTypeRegistry;
   import platform.client.fp10.core.type.IGameClass;
   import platform.client.fp10.core.type.impl.GameClass;
   
   public class GameTypeRegistryImpl implements GameTypeRegistry
   {
      
      private var _classes:Dictionary;
      
      public function GameTypeRegistryImpl()
      {
         super();
         this._classes = new Dictionary();
      }
      
      public function createClass(param1:Long, param2:Vector.<Long>) : GameClass
      {
         var _loc3_:GameClass = this._classes[param1];
         if(_loc3_ == null)
         {
            _loc3_ = new GameClass(param1,param2);
            this._classes[param1] = _loc3_;
            return _loc3_;
         }
         if(this.modelDefinitionsEqual(_loc3_.models,param2))
         {
            return _loc3_;
         }
         throw new ArgumentError("Conflicting GameClass registration: id=" + this.formatId(param1) + " existingModels=" + this.formatModelIds(_loc3_.models) + " incomingModels=" + this.formatModelIds(param2));
      }

      private function modelDefinitionsEqual(param1:Vector.<Long>, param2:Vector.<Long>) : Boolean
      {
         var _loc3_:int = param1 == null ? 0 : param1.length;
         var _loc4_:int = param2 == null ? 0 : param2.length;
         var _loc5_:int = 0;
         var _loc6_:Long = null;
         var _loc7_:Long = null;
         if(_loc3_ != _loc4_)
         {
            return false;
         }
         while(_loc5_ < _loc3_)
         {
            _loc6_ = param1[_loc5_];
            _loc7_ = param2[_loc5_];
            if(_loc6_ == null || _loc7_ == null)
            {
               if(_loc6_ != _loc7_)
               {
                  return false;
               }
            }
            else if(_loc6_.high != _loc7_.high || _loc6_.low != _loc7_.low)
            {
               return false;
            }
            _loc5_++;
         }
         return true;
      }

      private function formatModelIds(param1:Vector.<Long>) : String
      {
         var _loc2_:Array = [];
         var _loc3_:int = 0;
         if(param1 != null)
         {
            while(_loc3_ < param1.length)
            {
               _loc2_.push(this.formatId(param1[_loc3_]));
               _loc3_++;
            }
         }
         return "[" + _loc2_.join(",") + "]";
      }

      private function formatId(param1:Long) : String
      {
         return param1 == null ? "null" : "(" + param1.high + "," + param1.low + ")";
      }
      
      public function destroyClass(param1:Long) : void
      {
         this._classes[param1] = null;
      }
      
      public function getClass(param1:Long) : IGameClass
      {
         return this._classes[param1];
      }
      
      public function get classes() : Dictionary
      {
         return this._classes;
      }
   }
}
