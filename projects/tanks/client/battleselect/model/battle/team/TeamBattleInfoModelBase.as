package projects.tanks.client.battleselect.model.battle.team
{
   import alternativa.types.Long;
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.model.impl.Model;

   public class TeamBattleInfoModelBase extends Model
   {

      protected var server:TeamBattleInfoModelServer;

      public static const modelId:Long = Long.getLong(-1459499568,-1422309214);

      public function TeamBattleInfoModelBase()
      {
         super();
         this.initCodecs();
      }

      protected function initCodecs() : void
      {
         this.server = new TeamBattleInfoModelServer(IModel(this));
      }

      protected function getInitParam() : TeamBattleInfoCC
      {
         return TeamBattleInfoCC(initParams[Model.object]);
      }

      override public function get id() : Long
      {
         return modelId;
      }
   }
}
