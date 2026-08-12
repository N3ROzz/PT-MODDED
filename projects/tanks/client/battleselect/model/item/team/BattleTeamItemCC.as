package projects.tanks.client.battleselect.model.item.team
{
   public class BattleTeamItemCC
   {
      public var usersBlue:Vector.<String>;
      public var usersRed:Vector.<String>;

      public function BattleTeamItemCC(param1:Vector.<String> = null, param2:Vector.<String> = null)
      {
         this.usersBlue = param1;
         this.usersRed = param2;
      }
   }
}
