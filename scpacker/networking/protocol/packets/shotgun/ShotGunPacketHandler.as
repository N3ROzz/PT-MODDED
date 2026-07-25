package scpacker.networking.protocol.packets.shotgun
{
   import scpacker.networking.protocol.AbstractPacketHandler;
   import alternativa.types.Long;
   import alternativa.tanks.battle.BattleUtils;
   import scpacker.networking.protocol.AbstractPacket;
   import alternativa.tanks.models.weapon.shotgun.aiming.ShotgunAimingModel;
   import projects.tanks.client.battlefield.models.tankparts.weapons.shotgun.ShotgunHittingModelBase;
   import alternativa.tanks.models.weapons.discrete.DiscreteWeaponCommunicationModel;
   import projects.tanks.client.battlefield.models.tankparts.weapons.common.discrete.DiscreteWeaponCommunicationModelBase;
   import utils.TankNameGameObjectMapper;
   import platform.client.fp10.core.type.IGameObject;
   import platform.client.fp10.core.model.impl.Model;
   import alternativa.tanks.models.tank.configuration.TankConfiguration;
   import scpacker.utils.CoreUtils;
   import utils.HammerDiagnostics;
   
   public class ShotGunPacketHandler extends AbstractPacketHandler
   {
      private var shotgunModel:DiscreteWeaponCommunicationModel;
      
      public function ShotGunPacketHandler()
      {
         super();
         this.id = 70;
         this.shotgunModel = DiscreteWeaponCommunicationModel(modelRegistry.getModel(DiscreteWeaponCommunicationModelBase.modelId));
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case ShotgunShootInPacket.id:
               this.shoot(param1 as ShotgunShootInPacket);
         }
      }
      
      private function shoot(param1:ShotgunShootInPacket) : void
      {
         if(HammerDiagnostics.ENABLED)
         {
            HammerDiagnostics.log("HAMMER_INBOUND_SHOT_RECEIVED","packetId=471157826 shooter=" + param1.shooter + " directionNull=" + int(param1.shootDirection == null));
            HammerDiagnostics.logTargetHits("HAMMER_INBOUND_PACKET_TARGETS",param1.targets);
         }
         var shooterGameObject:IGameObject = TankNameGameObjectMapper.getGameObjectByTankName(param1.shooter);
         var turretGameObject:IGameObject = CoreUtils.getTurretObjectByTankName(param1.shooter);
         if(HammerDiagnostics.ENABLED)
         {
            HammerDiagnostics.log("HAMMER_INBOUND_OBJECTS_RESOLVED","shooterObject=" + int(shooterGameObject != null) + " turretObject=" + int(turretGameObject != null));
         }
         Model.object = turretGameObject;
         try
         {
            this.shotgunModel.shoot(shooterGameObject,param1.shootDirection,param1.targets);
            if(HammerDiagnostics.ENABLED)
            {
               HammerDiagnostics.log("HAMMER_INBOUND_DISPATCH_RETURNED","shooter=" + param1.shooter);
            }
         }
         catch(error:Error)
         {
            HammerDiagnostics.logError("HAMMER_INBOUND_DISPATCH_FAILED",error);
            throw error;
         }          finally          {             Model.popObject();          }
         //WeaponsManager.newname_5991__END(newname_2399__END.getUser(param1.shooter)).newname_7050__END(newname_2399__END.getUser(param1.shooter),BattleUtils.getVector3(param1.shootDirection),param1.targets);
      }
   }
}

