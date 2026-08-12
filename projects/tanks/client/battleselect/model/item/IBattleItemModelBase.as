package projects.tanks.client.battleselect.model.item
{
   public interface IBattleItemModelBase
   {
      function madePrivate() : void;
      function setBattleName(param1:String) : void;
      function updateSuspicion(param1:BattleSuspicionLevel) : void;
   }
}
