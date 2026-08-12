package scpacker.networking.protocol.packets.layoutswitch
{
   import scpacker.networking.protocol.AbstractPacketHandler;
   import alternativa.osgi.OSGi;
   import alternativa.types.Long;
   import projects.tanks.clients.flash.commons.models.layout.notify.LobbyLayoutNotifyModel;
   import scpacker.networking.protocol.AbstractPacket;
   import projects.tanks.client.commons.models.layout.notify.LobbyLayoutNotifyModelBase;
   import scpacker.networking.protocol.packets.layoutswitch.BeginLayoutSwitchInPacket;
   import scpacker.networking.protocol.packets.layoutswitch.EndLayoutSwitchInPacket;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.layout.ILobbyLayoutService;
   import utils.RuntimeLifecycleDiagnostics;
   
   public class LayoutSwitchPacketHandler extends AbstractPacketHandler
   {
      private var lobbyLayoutNotifyModel:LobbyLayoutNotifyModel;

      private var lobbyLayoutService:ILobbyLayoutService;
      
      public function LayoutSwitchPacketHandler()
      {
         super();
         this.id = 12;
         this.lobbyLayoutNotifyModel = LobbyLayoutNotifyModel(modelRegistry.getModel(LobbyLayoutNotifyModelBase.modelId));
         this.lobbyLayoutService = OSGi.getInstance().getService(ILobbyLayoutService) as ILobbyLayoutService;
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         var _loc2_:int = param1.getId();
         RuntimeLifecycleDiagnostics.recordPreInitHandler("PREINIT_HANDLER_ENTER",_loc2_,this.id);
         switch(_loc2_)
         {
            case BeginLayoutSwitchInPacket.id:
               this.handleBeginLayoutSwitch(param1 as BeginLayoutSwitchInPacket);
               break;
            case EndLayoutSwitchInPacket.id:
               this.handleEndLayoutSwitch(param1 as EndLayoutSwitchInPacket);
         }
         RuntimeLifecycleDiagnostics.recordPreInitHandler("PREINIT_HANDLER_EXIT",_loc2_,this.id);
      }
      
      private function handleBeginLayoutSwitch(param1:BeginLayoutSwitchInPacket) : void
      {
         RuntimeLifecycleDiagnostics.recordLayout("LAYOUT_BEGIN_HANDLER_ENTER","packetCurrentState=" + param1.currentState + " " + this.captureLayoutState());
         this.lobbyLayoutNotifyModel.beginLayoutSwitch(param1.currentState);
         RuntimeLifecycleDiagnostics.recordLayout("LAYOUT_BEGIN_HANDLER_EXIT","packetCurrentState=" + param1.currentState + " " + this.captureLayoutState());
      }
      
      private function handleEndLayoutSwitch(param1:EndLayoutSwitchInPacket) : void
      {
         RuntimeLifecycleDiagnostics.recordLayout("LAYOUT_END_HANDLER_ENTER","origin=" + param1.origin + " packetCurrentState=" + param1.currentState + " " + this.captureLayoutState());
         this.lobbyLayoutNotifyModel.endLayoutSwitch(param1.origin,param1.currentState);
         RuntimeLifecycleDiagnostics.recordLayout("LAYOUT_END_HANDLER_EXIT","origin=" + param1.origin + " packetCurrentState=" + param1.currentState + " " + this.captureLayoutState());
      }

      private function captureLayoutState() : String
      {
         if(this.lobbyLayoutService == null)
         {
            RuntimeLifecycleDiagnostics.updateLayoutState(false,false,"unavailable");
            return "layoutServiceAvailable=0";
         }
         try
         {
            var _loc1_:Boolean = this.lobbyLayoutService.isSwitchInProgress();
            var _loc2_:Boolean = this.lobbyLayoutService.inBattle();
            RuntimeLifecycleDiagnostics.updateLayoutState(_loc1_,_loc2_,String(this.lobbyLayoutService.getCurrentState()));
            return "layoutServiceAvailable=1 serviceSwitchInProgress=" + (_loc1_ ? 1 : 0) + " serviceInBattle=" + (_loc2_ ? 1 : 0) + " serviceCurrentState=" + this.lobbyLayoutService.getCurrentState();
         }
         catch(e:Error)
         {
            return "layoutServiceAvailable=1 layoutStateError=" + e.name;
         }
         return "layoutServiceAvailable=1 layoutStateError=unknown";
      }
   }
}
