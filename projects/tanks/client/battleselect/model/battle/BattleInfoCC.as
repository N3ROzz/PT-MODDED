package projects.tanks.client.battleselect.model.battle
{
   import platform.client.fp10.core.type.IGameObject;
   import projects.tanks.client.battleservice.BattleMode;
   import projects.tanks.client.battleservice.EquipmentConstraintsMode;
   import projects.tanks.client.battleservice.Range;
   import projects.tanks.client.battleservice.model.createparams.BattleLimits;
   import projects.tanks.client.battleservice.model.types.BattleSuspicionLevel;

   public class BattleInfoCC
   {
      public var battleId:String;
      public var battleMode:BattleMode;
      public var dependentCooldownEnabled:Boolean;
      public var equipmentConstraintsMode:EquipmentConstraintsMode;
      public var esportDropTiming:Boolean;
      public var limits:BattleLimits;
      public var map:IGameObject;
      public var maxPeopleCount:int;
      public var name:String;
      public var parkourMode:Boolean;
      public var proBattle:Boolean;
      public var randomGold:Boolean;
      public var rankRange:Range;
      public var reArmorEnabled:Boolean;
      public var reducedResistance:Boolean;
      public var roundStarted:Boolean;
      public var spectator:Boolean;
      public var suspicionLevel:BattleSuspicionLevel;
      public var timeLeftInSec:int;
      public var userPaidNoSuppliesBattle:Boolean;
      public var withoutBonuses:Boolean;
      public var withoutCrystals:Boolean;
      public var withoutDrones:Boolean;
      public var withoutGoldBoxes:Boolean;
      public var withoutGoldSiren:Boolean;
      public var withoutGoldZone:Boolean;
      public var withoutMedkit:Boolean;
      public var withoutMines:Boolean;
      public var withoutSupplies:Boolean;
      public var withoutUpgrades:Boolean;

      public function BattleInfoCC()
      {
         super();
      }

      public function toString() : String
      {
         return "BattleInfoCC [battleId = " + this.battleId + " battleMode = " + this.battleMode + " name = " + this.name + "]";
      }
   }
}
