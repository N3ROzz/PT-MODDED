package platform.client.fp10.core.model.impl
{
   import alternativa.protocol.ProtocolBuffer;
   import alternativa.types.Long;
   import flash.utils.Dictionary;
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.type.IGameObject;
   import platform.client.fp10.core.type.IGameObjectInternal;
   
   public class Model implements IModel
   {
      
      public static var currentObject:IGameObject;
      
      public static var objects:Vector.<IGameObject> = new Vector.<IGameObject>();

      private static const contextSnapshotOwner:Object = {};

      private static var _popUnderflowGeneration:uint;
      
      protected var initParams:Dictionary = new Dictionary();
      
      public function Model()
      {
         super();
      }
      
      public static function get object() : IGameObject
      {
         return currentObject;
      }
      
      public static function set object(param1:IGameObject) : void
      {
         objects.push(currentObject);
         currentObject = param1;
      }

      public static function get contextDepth() : int
      {
         return objects.length;
      }

      public static function get popUnderflowGeneration() : uint
      {
         return _popUnderflowGeneration;
      }
      
      public static function popObject() : void
      {
         if(objects.length == 0)
         {
            ++_popUnderflowGeneration;
            trace("[MODEL_CONTEXT] event=POP_UNDERFLOW generation=" + _popUnderflowGeneration);
            return;
         }
         currentObject = objects.pop();
      }

      public static function withObject(param1:IGameObject, param2:Function, ... rest) : *
      {
         return invokeWithObjectArgs(param1,param2,rest);
      }

      private static function invokeWithObjectArgs(param1:IGameObject, param2:Function, param3:Array) : *
      {
         if(param2 == null)
         {
            throw new ArgumentError("Model.withObject callback must not be null");
         }
         Model.object = param1;
         try
         {
            return param2.apply(null,param3);
         }
         finally
         {
            Model.popObject();
         }
      }

      public static function captureContextSnapshot() : Object
      {
         return new ModelContextSnapshot(contextSnapshotOwner,currentObject,objects);
      }

      public static function describeContextMismatch(param1:Object) : String
      {
         return getContextSnapshot(param1).describeMismatch(contextSnapshotOwner,currentObject,objects);
      }

      public static function restoreContextSnapshot(param1:Object) : void
      {
         getContextSnapshot(param1).restore(contextSnapshotOwner);
      }

      private static function getContextSnapshot(param1:Object) : ModelContextSnapshot
      {
         var _loc2_:ModelContextSnapshot = param1 as ModelContextSnapshot;
         if(_loc2_ == null || !_loc2_.isOwnedBy(contextSnapshotOwner))
         {
            throw new ArgumentError("Invalid Model context snapshot");
         }
         return _loc2_;
      }
      
      public function invoke(param1:Long, param2:ProtocolBuffer) : void
      {
      }
      
      public function get id() : Long
      {
         return null;
      }
      
      public function putInitParams(param1:Object) : void
      {
         this.initParams[object] = param1;
      }
      
      public function clearInitParams() : void
      {
         delete this.initParams[object];
      }
      
      public function getData(param1:Class) : Object
      {
         return IGameObjectInternal(currentObject).getData(this,param1);
      }
      
      public function putData(param1:Class, param2:Object) : void
      {
         IGameObjectInternal(currentObject).putData(this,param1,param2);
      }
      
      public function clearData(param1:Class) : Object
      {
         return IGameObjectInternal(currentObject).clearData(this,param1);
      }
      
      protected function getFunctionWrapper(param1:Function) : Function
      {
         var wrapper:Function;
         var object:IGameObject = null;
         var f:Function = param1;
         var wrappers:Dictionary = this.getData(Model) as Dictionary;
         if(wrappers == null)
         {
            wrappers = new Dictionary();
            this.putData(Model,wrappers);
         }
         wrapper = wrappers[f];
         if(wrapper == null)
         {
            object = Model.object;
            wrapper = function(... rest):void
            {
               invokeWithObjectArgs(object,f,rest);
            };
            wrappers[f] = wrapper;
         }
         return wrapper;
      }
   }
}

import platform.client.fp10.core.model.impl.Model;
import platform.client.fp10.core.type.IGameObject;

class ModelContextSnapshot
{
   private var owner:Object;

   private var savedCurrentObject:IGameObject;

   private var savedStackReference:Vector.<IGameObject>;

   private var savedStackContents:Vector.<IGameObject>;

   public function ModelContextSnapshot(param1:Object, param2:IGameObject, param3:Vector.<IGameObject>)
   {
      if(param3 == null)
      {
         throw new ArgumentError("Model context stack must not be null");
      }
      this.owner = param1;
      this.savedCurrentObject = param2;
      this.savedStackReference = param3;
      this.savedStackContents = new Vector.<IGameObject>(param3.length);
      var _loc4_:int = 0;
      while(_loc4_ < param3.length)
      {
         this.savedStackContents[_loc4_] = param3[_loc4_];
         _loc4_++;
      }
   }

   public function isOwnedBy(param1:Object) : Boolean
   {
      return this.owner === param1;
   }

   public function describeMismatch(param1:Object, param2:IGameObject, param3:Vector.<IGameObject>) : String
   {
      this.validateOwner(param1);
      var _loc4_:String = "";
      if(param3 !== this.savedStackReference)
      {
         _loc4_ = this.appendMismatch(_loc4_,"STACK_REFERENCE");
      }
      if(param3 == null || param3.length != this.savedStackContents.length)
      {
         _loc4_ = this.appendMismatch(_loc4_,"DEPTH");
      }
      if(param2 !== this.savedCurrentObject)
      {
         _loc4_ = this.appendMismatch(_loc4_,"CURRENT_OBJECT");
      }
      if(param3 != null && param3.length == this.savedStackContents.length)
      {
         var _loc5_:int = 0;
         while(_loc5_ < param3.length)
         {
            if(param3[_loc5_] !== this.savedStackContents[_loc5_])
            {
               _loc4_ = this.appendMismatch(_loc4_,"STACK_CONTENTS");
               break;
            }
            _loc5_++;
         }
      }
      return _loc4_;
   }

   public function restore(param1:Object) : void
   {
      this.validateOwner(param1);
      Model.objects = this.savedStackReference;
      Model.objects.length = 0;
      var _loc2_:int = 0;
      while(_loc2_ < this.savedStackContents.length)
      {
         Model.objects.push(this.savedStackContents[_loc2_]);
         _loc2_++;
      }
      Model.currentObject = this.savedCurrentObject;
   }

   private function validateOwner(param1:Object) : void
   {
      if(this.owner !== param1)
      {
         throw new ArgumentError("Invalid Model context snapshot owner");
      }
   }

   private function appendMismatch(param1:String, param2:String) : String
   {
      return param1.length == 0 ? param2 : param1 + "," + param2;
   }
}
