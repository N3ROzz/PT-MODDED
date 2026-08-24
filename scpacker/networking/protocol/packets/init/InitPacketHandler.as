package scpacker.networking.protocol.packets.init
{
   import alternativa.types.Long;
   import alternativa.osgi.OSGi;
   import alternativa.tanks.loader.ILoaderWindowService;
   import alternativa.tanks.servermodels.EntranceModel;
   import platform.client.fp10.core.model.impl.Model;
   import platform.client.fp10.core.resource.BatchResourceLoader;
   import platform.client.fp10.core.type.IGameObject;
   import platform.client.fp10.core.type.impl.GameObject;
   import platform.loading.DispatcherModel;
   import scpacker.networking.protocol.AbstractPacketHandler;
   import scpacker.networking.protocol.AbstractPacket;
   import scpacker.networking.protocol.packets.init.ActivateProtectionInPacket;
   import scpacker.networking.protocol.packets.init.LoadResourcesInPacket;
   import scpacker.networking.protocol.packets.init.HideLoaderInPacket;
   import scpacker.networking.protocol.ProtocolInitializer;
   import scpacker.networking.Network;
   import scpacker.resource.ResourcesLoader;
   import projects.tanks.client.entrance.model.entrance.entrance.EntranceModelBase;
   import platform.client.core.general.spaces.loading.dispatcher.DispatcherModelBase;
   
   public class InitPacketHandler extends AbstractPacketHandler
   {
      private var dispatcherModel:DispatcherModel;
      
      private var entranceModel:EntranceModel;
      
      private var resourcesLoader:ResourcesLoader = new ResourcesLoader();
      
      public function InitPacketHandler()
      {
         super();
         this.id = 4;
         this.dispatcherModel = DispatcherModel(modelRegistry.getModel(DispatcherModelBase.modelId));
         this.entranceModel = EntranceModel(modelRegistry.getModel(EntranceModelBase.modelId));
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case ActivateProtectionInPacket.id:
               this.activateProtection(param1 as ActivateProtectionInPacket);
               break;
            case LoadResourcesInPacket.id:
               this.loadResources(param1 as LoadResourcesInPacket);
               break;
            case HideLoaderInPacket.id:
               this.hideLoader();
         }
      }
      
      private function loadResources(param1:LoadResourcesInPacket) : void
      {
         if(param1.callbackId == 5)
         {
            BatchResourceLoader.battleSelectTraceEnabled = true;
            this.traceRequestedResources(param1.resourcesJson);
         }
         var _loc2_:IGameObject = new GameObject(Long.getLong(1,1),null,"ResourceObject",null);
         Model.object = _loc2_;
         try
         {
            this.dispatcherModel.loadDependencies(this.resourcesLoader.getResourceDependencies(param1.resourcesJson,param1.callbackId));
         }
         finally
         {
            Model.popObject();
         }
      }

      private function traceRequestedResources(param1:String) : void
      {
         try
         {
            var _loc1_:Object = JSON.parse(param1);
            var _loc2_:Network = Network(OSGi.getInstance().getService(Network));
            for each(var _loc3_:Object in _loc1_)
            {
               _loc2_.writeBattleSelectTrace("RESOURCE_REQUEST idHigh=" + _loc3_.idhigh + " idLow=" + _loc3_.idlow + " type=" + _loc3_.type + " versionHigh=" + _loc3_.versionhigh + " versionLow=" + _loc3_.versionlow + " lazy=" + _loc3_.lazy + " fileNames=" + (_loc3_.fileNames == null ? "" : _loc3_.fileNames.join(",")));
            }
         }
         catch(diagnosticError:Error)
         {
         }
      }

      private function hideLoader() : void
      {
         (OSGi.getInstance().getService(ILoaderWindowService) as ILoaderWindowService).hide();
         this.entranceModel.objectLoaded();
         this.entranceModel.objectLoadedPost();
      }
      
      private function activateProtection(param1:ActivateProtectionInPacket) : void
      {
         var _loc2_:ProtocolInitializer = ProtocolInitializer(OSGi.getInstance().getService(ProtocolInitializer));
         _loc2_.InitializeProtection(param1.keys);
      }
   }
}
