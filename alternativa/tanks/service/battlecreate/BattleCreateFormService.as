package alternativa.tanks.service.battlecreate
{
   import flash.events.EventDispatcher;
   import utils.TankTraceUtil;
   
   public class BattleCreateFormService extends EventDispatcher implements IBattleCreateFormService
   {
      
      private var _battleCreationDisabled:Boolean;
      
      public function BattleCreateFormService()
      {
         super();
      }
      
      public function showForm() : void
      {
         TankTraceUtil.logCreateBattle("BattleCreateFormService.showForm listeners=" + this.hasEventListener(BattleCreateFormServiceEvent.SHOW_FORM));
         dispatchEvent(new BattleCreateFormServiceEvent(BattleCreateFormServiceEvent.SHOW_FORM));
      }
      
      public function hideForm() : void
      {
         TankTraceUtil.logCreateBattle("BattleCreateFormService.hideForm listeners=" + this.hasEventListener(BattleCreateFormServiceEvent.HIDE_FORM));
         dispatchEvent(new BattleCreateFormServiceEvent(BattleCreateFormServiceEvent.HIDE_FORM));
      }
      
      public function get battleCreationDisabled() : Boolean
      {
         return this._battleCreationDisabled;
      }
      
      public function set battleCreationDisabled(param1:Boolean) : void
      {
         this._battleCreationDisabled = param1;
      }
   }
}
