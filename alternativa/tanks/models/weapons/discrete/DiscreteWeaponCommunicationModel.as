package alternativa.tanks.models.weapons.discrete
{
   import alternativa.math.Vector3;
   import alternativa.tanks.battle.BattleUtils;
   import alternativa.tanks.battle.events.BattleEventDispatcher;
   import alternativa.tanks.battle.events.StateCorrectionEvent;
   import platform.client.fp10.core.type.IGameObject;
   import projects.tanks.client.battlefield.models.tankparts.weapons.common.TargetPosition;
   import projects.tanks.client.battlefield.models.tankparts.weapons.common.discrete.DiscreteWeaponCommunicationModelBase;
   import projects.tanks.client.battlefield.models.tankparts.weapons.common.discrete.IDiscreteWeaponCommunicationModelBase;
   import projects.tanks.client.battlefield.models.tankparts.weapons.common.discrete.TargetHit;
   import projects.tanks.client.battlefield.types.Vector3d;
   import utils.HammerDiagnostics;
   
   [ModelInfo]
   public class DiscreteWeaponCommunicationModel extends DiscreteWeaponCommunicationModelBase implements IDiscreteWeaponCommunicationModelBase, DiscreteWeapon
   {
      
      [Inject] // added
      public static var battleEventDispatcher:BattleEventDispatcher;
      
      public function DiscreteWeaponCommunicationModel()
      {
         super();
      }
      
      [Obfuscation(rename="false")]
      public function shoot(param1:IGameObject, param2:Vector3d, param3:Vector.<TargetHit>) : void
      {
         HammerDiagnostics.logTargetHits("HAMMER_INBOUND_MODEL_SHOT",param3);
         var _loc4_:DiscreteWeaponListener = DiscreteWeaponListener(object.event(DiscreteWeaponListener));
         _loc4_.onShot(param1,BattleUtils.getVector3(param2),param3);
      }
      
      public function tryToShoot(param1:int, param2:Vector3, param3:Vector.<TargetPosition>) : void
      {
         HammerDiagnostics.logTargets("HAMMER_OUTBOUND_MODEL_TARGETS",param3);
         if(HammerDiagnostics.ENABLED)
         {
            HammerDiagnostics.log("HAMMER_MANDATORY_UPDATE_BEGIN");
         }
         battleEventDispatcher.dispatchEvent(StateCorrectionEvent.MANDATORY_UPDATE);
         if(HammerDiagnostics.ENABLED)
         {
            HammerDiagnostics.log("HAMMER_MANDATORY_UPDATE_RETURNED");
            HammerDiagnostics.log("HAMMER_NETWORK_SEND_BEGIN","packetId=-541655881");
         }
         try
         {
            server.tryToShoot(param1,BattleUtils.getVector3d(param2),param3);
            if(HammerDiagnostics.ENABLED)
            {
               HammerDiagnostics.log("HAMMER_NETWORK_SEND_RETURNED","packetId=-541655881");
            }
         }
         catch(error:Error)
         {
            HammerDiagnostics.logError("HAMMER_NETWORK_SEND_FAILED",error);
            throw error;
         }
      }
      
      public function tryToDummyShoot(param1:int, param2:Vector3) : void
      {
         battleEventDispatcher.dispatchEvent(StateCorrectionEvent.MANDATORY_UPDATE);
         server.tryToDummyShoot(param1,BattleUtils.getVector3d(param2));
      }
   }
}
