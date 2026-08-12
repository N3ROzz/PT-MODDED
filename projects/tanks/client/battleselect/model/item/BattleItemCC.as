package projects.tanks.client.battleselect.model.item
{
   import platform.client.fp10.core.type.IGameObject;
   import projects.tanks.client.battleservice.BattleMode;
   import projects.tanks.client.battleservice.EquipmentConstraintsMode;
   import projects.tanks.client.battleservice.Range;

   public class BattleItemCC
   {
      public var battleId:String;
      public var battleMode:BattleMode;
      public var equipmentConstraintsMode:EquipmentConstraintsMode;
      public var map:IGameObject;
      public var maxPeople:int;
      public var name:String;
      public var withoutSupplies:Boolean;
      public var parkourMode:Boolean;
      public var privateBattle:Boolean;
      public var proBattle:Boolean;
      public var rankRange:Range;
      public var suspicionLevel:BattleSuspicionLevel;

      public function BattleItemCC()
      {
         super();
      }
   }
}
