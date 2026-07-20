package alternativa.tanks.service.battlelist
{
   import alternativa.tanks.controllers.battlelist.BattleByURLNotFoundEvent;
   import alternativa.tanks.controllers.battlelist.BattleListController;
   import alternativa.tanks.controllers.battlelist.BattleSelectedEvent;
   import alternativa.tanks.controllers.battlelist.CreateBattleClickEvent;
   import alternativa.tanks.service.battlecreate.IBattleCreateFormService;
   import alternativa.tanks.service.battleinfo.IBattleInfoFormService;
   import alternativa.tanks.view.battleinfo.BattleInfoBaseParams;
   import alternativa.types.Long;
   import flash.events.EventDispatcher;
   import platform.client.fp10.core.type.IGameObject;
   import projects.tanks.client.battleservice.model.types.BattleSuspicionLevel;
   import utils.TankTraceUtil;
   import utils.BattleSelectionTrace;
   
   public class BattleListFormService extends EventDispatcher implements IBattleListFormService
   {
      
      [Inject] // added
      public static var battleCreateFormService:IBattleCreateFormService;
      
      [Inject] // added
      public static var battleInfoFormService:IBattleInfoFormService;
      
      private var battleListController:BattleListController;
      
      public function BattleListFormService()
      {
         super();
         TankTraceUtil.logBattleList("BattleListFormService.constructor");
      }
      
      public function createAndShow() : void
      {
         TankTraceUtil.logBattleList("BattleListFormService.createAndShow start existingController=" + (this.battleListController != null));
         if(this.battleListController != null)
         {
            this.hideAndDestroy();
         }
         this.battleListController = new BattleListController();
         TankTraceUtil.logBattleList("BattleListFormService.createAndShow controllerCreated");
         this.battleListController.showForm();
         TankTraceUtil.logBattleList("BattleListFormService.createAndShow formShown");
         this.battleListController.addEventListener(CreateBattleClickEvent.CREATE_BATTLE_CLICK,this.onCreateBattleClick);
         this.battleListController.addEventListener(BattleSelectedEvent.BATTLE_SELECTED,this.onBattleSelected);
         this.battleListController.addEventListener(BattleByURLNotFoundEvent.BATTLE_BY_URL_NOT_FOUND,this.onBattleByURLNotFound);
         TankTraceUtil.logBattleList("BattleListFormService.createAndShow listenersAdded");
      }
      
      public function hideAndDestroy() : void
      {
         TankTraceUtil.logBattleList("BattleListFormService.hideAndDestroy controllerNull=" + (this.battleListController == null));
         if(this.battleListController == null)
         {
            return;
         }
         this.battleListController.removeEventListener(CreateBattleClickEvent.CREATE_BATTLE_CLICK,this.onCreateBattleClick);
         this.battleListController.removeEventListener(BattleSelectedEvent.BATTLE_SELECTED,this.onBattleSelected);
         this.battleListController.removeEventListener(BattleByURLNotFoundEvent.BATTLE_BY_URL_NOT_FOUND,this.onBattleByURLNotFound);
         this.battleListController.hideForm();
         this.battleListController.destroy();
         this.battleListController = null;
      }
      
      public function battleItemRecord(param1:BattleInfoBaseParams) : void
      {
         TankTraceUtil.logBattleList("BattleListFormService.battleItemRecord controllerNull=" + (this.battleListController == null) + " paramsNull=" + (param1 == null));
         this.battleListController.battleItemRecord(param1);
      }
      
      public function selectBattleItemFromServer(param1:IGameObject) : void
      {
         this.battleListController.selectBattleItemFromServer(param1);
      }
      
      public function updateSuspicious(param1:String, param2:BattleSuspicionLevel) : void
      {
         this.battleListController.updateSuspicious(param1,param2);
      }
      
      public function removeBattleItem(param1:String) : void
      {
         this.battleListController.removeBattle(param1);
      }
      
      public function updateUsersCount(param1:String) : void
      {
         this.battleListController.updateUsersCount(param1);
      }
      
      public function updateBattleName(param1:String) : void
      {
         this.battleListController.updateBattleName(param1);
      }
      
      private function onBattleSelected(param1:BattleSelectedEvent) : void
      {
         BattleSelectionTrace.record("EVENT_DISPATCH","BattleListFormService",param1.selectedItem == null ? "" : param1.selectedItem.name,param1.selectedItem,"event=BattleListFormServiceEvent");
         dispatchEvent(new BattleListFormServiceEvent(BattleListFormServiceEvent.BATTLE_SELECTED,param1.selectedItem));
         battleCreateFormService.hideForm();
      }
      
      private function onBattleByURLNotFound(param1:BattleByURLNotFoundEvent) : void
      {
         dispatchEvent(new BattleByURLNotFoundEvent(BattleByURLNotFoundEvent.BATTLE_BY_URL_NOT_FOUND,param1.battleId));
      }
      
      public function swapTeams(param1:String) : void
      {
         this.battleListController.swapTeams(param1);
      }
      
      public function battleItemsPacketJoinSuccess() : void
      {
         TankTraceUtil.logBattleList("BattleListFormService.battleItemsPacketJoinSuccess controllerNull=" + (this.battleListController == null));
         this.battleListController.battleItemsPacketJoinSuccess();
      }
      
      private function onCreateBattleClick(param1:CreateBattleClickEvent) : void
      {
         TankTraceUtil.logCreateBattle("BattleListFormService.onCreateBattleClick");
         battleCreateFormService.showForm();
         battleInfoFormService.removeFormFromStage();
      }
      
      public function checkBattleButton() : void
      {
         this.battleListController.resetBattleButtonState();
      }
   }
}
