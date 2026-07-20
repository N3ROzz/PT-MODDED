package alternativa.tanks.model.battleselect
{
   import alternativa.tanks.controllers.battlelist.BattleByURLNotFoundEvent;
   import alternativa.tanks.service.battle.BattleFriendNotifier;
   import alternativa.tanks.service.battleinfo.IBattleInfoFormService;
   import alternativa.tanks.service.battlelist.BattleListFormServiceEvent;
   import alternativa.tanks.service.battlelist.IBattleListFormService;
   import alternativa.tanks.tracker.ITrackerService;
   import flash.utils.clearTimeout;
   import flash.utils.setTimeout;
   import platform.client.fp10.core.model.ObjectLoadPostListener;
   import platform.client.fp10.core.model.ObjectUnloadListener;
   import platform.client.fp10.core.type.IGameObject;
   import projects.tanks.client.battleselect.model.battleselect.BattleSelectModelBase;
   import projects.tanks.client.battleselect.model.battleselect.IBattleSelectModelBase;
   import alternativa.tanks.model.info.param.BattleParams;
   import utils.TankTraceUtil;
   import utils.BattleSelectionTrace;
   
   [ModelInfo]
   public class BattleSelectModel extends BattleSelectModelBase implements IBattleSelectModelBase, ObjectLoadPostListener, ObjectUnloadListener
   {
      
      [Inject] // added
      public static var battleListFormService:IBattleListFormService;
      
      [Inject] // added
      public static var battleInfoFormService:IBattleInfoFormService;
      
      [Inject] // added
      public static var trackerService:ITrackerService;
      
      private var battleFriendNotifier:BattleFriendNotifier;
      
      private var selectTimeoutId:int = -1;
      
      public function BattleSelectModel()
      {
         super();
      }
      
      public function select(param1:IGameObject) : void
      {
         TankTraceUtil.logBattleList("BattleSelectModel.select battle=" + (param1 == null ? "null" : param1.name));
         BattleSelectionTrace.record("MODEL_SELECT_ACK","BattleSelectModel.select",param1 == null ? "" : param1.name,param1,"");
         battleListFormService.selectBattleItemFromServer(param1);
         this.clearSelectTimeout();
      }
      
      public function objectLoadedPost() : void
      {
         TankTraceUtil.logBattleList("BattleSelectModel.objectLoadedPost start serviceNull=" + (battleListFormService == null));
         if(this.battleFriendNotifier != null)
         {
            this.battleFriendNotifier.destroy();
            this.battleFriendNotifier = null;
         }
         battleListFormService.removeEventListener(BattleListFormServiceEvent.BATTLE_SELECTED,getFunctionWrapper(this.onBattleSelected));
         battleListFormService.removeEventListener(BattleByURLNotFoundEvent.BATTLE_BY_URL_NOT_FOUND,getFunctionWrapper(this.onBattleByURLNotFound));
         this.battleFriendNotifier = new BattleFriendNotifier();
         battleListFormService.createAndShow();
         TankTraceUtil.logBattleList("BattleSelectModel.objectLoadedPost after createAndShow");
         battleListFormService.addEventListener(BattleListFormServiceEvent.BATTLE_SELECTED,getFunctionWrapper(this.onBattleSelected));
         battleListFormService.addEventListener(BattleByURLNotFoundEvent.BATTLE_BY_URL_NOT_FOUND,getFunctionWrapper(this.onBattleByURLNotFound));
         trackerService.trackEvent("battleList","init","");
         TankTraceUtil.logBattleList("BattleSelectModel.objectLoadedPost end");
      }
      
      public function objectUnloaded() : void
      {
         TankTraceUtil.logBattleList("BattleSelectModel.objectUnloaded start");
         if(this.battleFriendNotifier != null)
         {
            this.battleFriendNotifier.destroy();
            this.battleFriendNotifier = null;
         }
         if(battleInfoFormService != null)
         {
            battleInfoFormService.destroy();
         }
         if(battleListFormService != null)
         {
            battleListFormService.removeEventListener(BattleListFormServiceEvent.BATTLE_SELECTED,getFunctionWrapper(this.onBattleSelected));
            battleListFormService.removeEventListener(BattleByURLNotFoundEvent.BATTLE_BY_URL_NOT_FOUND,getFunctionWrapper(this.onBattleByURLNotFound));
            battleListFormService.hideAndDestroy();
         }
         this.clearSelectTimeout();
         TankTraceUtil.logBattleList("BattleSelectModel.objectUnloaded end");
      }
      
      private function onBattleSelected(param1:BattleListFormServiceEvent) : void
      {
         var event:BattleListFormServiceEvent = param1;
         this.clearSelectTimeout();
         var battleId:String = BattleParams(param1.selectedItem.adapt(BattleParams)).getConstructor().params.battleId;
         BattleSelectionTrace.record("MODEL_SELECTION_EVENT","BattleSelectModel.onBattleSelected",battleId,param1.selectedItem,"payloadVariant=" + BattleSelectionTrace.BUILD_VARIANT);
         TankTraceUtil.markBattleSelect(battleId);
         server.onSelect(battleId,param1.selectedItem);
      }
      
      private function onBattleByURLNotFound(param1:BattleByURLNotFoundEvent) : void
      {
         server.search(param1.battleId);
      }
      
      public function battleItemsPacketJoinSuccess() : void
      {
         TankTraceUtil.logBattleList("BattleSelectModel.battleItemsPacketJoinSuccess");
         battleListFormService.battleItemsPacketJoinSuccess();
      }
      
      private function clearSelectTimeout() : void
      {
         if(this.selectTimeoutId != -1)
         {
            clearTimeout(this.selectTimeoutId);
         }
         this.selectTimeoutId = -1;
      }
   }
}
