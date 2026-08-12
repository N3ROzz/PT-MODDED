package alternativa.tanks.models.tank.killhandlers
{
   import alternativa.tanks.battle.objects.tank.Tank;
   import alternativa.tanks.models.tank.ITankModel;
   import platform.client.fp10.core.type.IGameObject;
   import utils.RuntimeLifecycleDiagnostics;
   
   public class RemoteTankDieHandler extends CommonTankDieHandler implements TankDieHandler, TankDeathConfirmationHandler
   {
      
      private var respawnDelay:int = 0;
      
      public function RemoteTankDieHandler()
      {
         super();
      }
      
      public function handleTankDie(param1:IGameObject, param2:int) : void
      {
         RuntimeLifecycleDiagnostics.recordDeath("REMOTE_DEATH_HANDLER_ENTER",param1.name,"delay=" + param2,true);
         this.respawnDelay = param2;
         var _loc3_:DeathConfirmationTimeoutTask = new DeathConfirmationTimeoutTask();
         _loc3_.start(param1,this.handleDeathConfirmation);
      }
      
      public function handleDeathConfirmation(param1:IGameObject) : void
      {
         RuntimeLifecycleDiagnostics.recordDeath("REMOTE_DEATH_CONFIRMATION_HANDLER_ENTER",param1.name,"respawnDelay=" + this.respawnDelay,true);
         var _loc2_:ITankModel = null;
         var _loc3_:Tank = null;
         if(this.respawnDelay > 0)
         {
            _loc2_ = getTankModel(param1);
            _loc3_ = _loc2_.getTank();
            if(_loc3_.isInBattle())
            {
               killTank(param1,this.respawnDelay);
            }
            this.respawnDelay = 0;
            _loc3_.isLastHitPointSet = false;
         }
      }
   }
}
