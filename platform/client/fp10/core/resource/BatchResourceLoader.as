package platform.client.fp10.core.resource
{
   import alternativa.osgi.OSGi;
   import alternativa.osgi.service.logging.LogService;
   import alternativa.osgi.service.logging.Logger;
   import platform.client.fp10.core.registry.ResourceRegistry;
   import platform.client.fp10.core.service.errormessage.IErrorMessageService;
   import platform.client.fp10.core.service.errormessage.errors.ResourceError;
   import platform.client.fp10.core.type.AutoClosable;
   import flash.utils.getQualifiedClassName;
   import scpacker.networking.Network;
   
   public class BatchResourceLoader implements IResourceLoadingListener, AutoClosable
   {
      
      [Inject] // added
      public static var logService:LogService;
      
      private static var logger:Logger;

      public static var battleSelectTraceEnabled:Boolean;
      
      [Inject] // added
      public static var messageBoxService:IErrorMessageService;
      
      [Inject] // added
      public static var resourceLoader:IResourceLoader;
      
      [Inject] // added
      public static var resourceRegistry:ResourceRegistry;
      
      private var callback:Function;
      
      private var numLoadedResources:int;
      
      private var numResources:int;
      
      public function BatchResourceLoader(param1:Function)
      {
         super();
         if(param1 == null)
         {
            throw new ArgumentError("Parameter listener is null");
         }
         this.callback = param1;
      }
      
      private static function getLogger() : Logger
      {
         return logger || (logger = logService.getLogger(ResourceLogChannel.NAME));
      }
      
      public function load(param1:Vector.<Resource>) : void
      {
         var _loc2_:Resource = null;
         if(param1 == null)
         {
            throw new ArgumentError("Parameter resources is null");
         }
         if(param1.length == 0)
         {
            throw new ArgumentError("Number of resources is zero");
         }
         ++this.numResources;
         for each(_loc2_ in param1)
         {
            if(_loc2_.isHasDependencies())
            {
               _loc2_.setBatchLoader(this);
            }
            else
            {
               this.loadResource(_loc2_);
            }
         }
         this.onResourceLoadingComplete(null);
      }
      
      public function loadResource(param1:Resource) : void
      {
         ++this.numResources;
         resourceLoader.loadResource(param1,this,ResourcePriority.NORMAL);
      }
      
      public function onResourceLoadingStart(param1:Resource) : void
      {
         this.traceResourceLifecycle("RESOURCE_START resource=" + this.resourceIdentity(param1));
      }
      
      public function onResourceLoadingComplete(param1:Resource) : void
      {
         ++this.numLoadedResources;
         this.traceResourceLifecycle("RESOURCE_COMPLETE resource=" + this.resourceIdentity(param1) + " loaded=" + this.numLoadedResources + " total=" + this.numResources);
         if(this.numLoadedResources == this.numResources)
         {
            this.completeBatchLoading();
         }
      }
      
      public function onResourceLoadingError(param1:Resource, param2:String) : void
      {
         getLogger().error("resource: %1, error: %2",[param1,param2]);
         this.traceResourceLifecycle("RESOURCE_ERROR resource=" + this.resourceIdentity(param1) + " error=" + param2 + " loaded=" + (this.numLoadedResources + 1) + " total=" + this.numResources);
         this.onResourceLoadingComplete(param1);
      }
      
      public function onResourceLoadingFatalError(param1:Resource, param2:String) : void
      {
         var _loc3_:ResourceError = new ResourceError(param1,param2);
         getLogger().error(_loc3_.getMessage());
         this.traceResourceLifecycle("RESOURCE_FATAL resource=" + this.resourceIdentity(param1) + " error=" + param2 + " loaded=" + this.numLoadedResources + " total=" + this.numResources);
         messageBoxService.showMessage(_loc3_);
      }

      private function resourceIdentity(param1:Resource) : String
      {
         return param1 == null ? "batch_sentinel" : param1.toString();
      }

      private function traceResourceLifecycle(param1:String) : void
      {
         if(!battleSelectTraceEnabled)
         {
            return;
         }
         try
         {
            Network(OSGi.getInstance().getService(Network)).writeBattleSelectTrace(param1);
         }
         catch(diagnosticError:Error)
         {
         }
      }
      
      public function close() : void
      {
         this.numResources = -1;
         this.callback = null;
      }
      
      private function completeBatchLoading() : void
      {
         this.numResources = 0;
         battleSelectTraceEnabled = false;
         this.callback.call();
      }
   }
}
