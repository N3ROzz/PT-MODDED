package projects.tanks.client.battleselect.model.item.team
{
   import projects.tanks.client.battleservice.model.battle.team.BattleTeam;

   public interface IBattleTeamItemModelBase
   {
      function addUser(param1:String, param2:BattleTeam) : void;
      function removeUser(param1:String) : void;
      function swapTeams() : void;
   }
}
