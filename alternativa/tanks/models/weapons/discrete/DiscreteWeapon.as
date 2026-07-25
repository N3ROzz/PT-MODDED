package alternativa.tanks.models.weapons.discrete
{
   import alternativa.math.Vector3;
   import projects.tanks.client.battlefield.models.tankparts.weapons.common.TargetPosition;
   
   [ModelInterface]
   public interface DiscreteWeapon
   {
      
      function tryToShoot(param1:int, param2:Vector3, param3:Vector.<TargetPosition>) : void;
      
      function tryToDummyShoot(param1:int, param2:Vector3) : void;
   }
}
