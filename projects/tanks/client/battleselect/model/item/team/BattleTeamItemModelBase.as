package projects.tanks.client.battleselect.model.item.team
{
   import alternativa.types.Long;
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.model.impl.Model;

   public class BattleTeamItemModelBase extends Model
   {
      protected var server:BattleTeamItemModelServer;
      public static const modelId:Long = Long.getLong(1769455679,-2015695144);

      public function BattleTeamItemModelBase()
      {
         super();
         this.server = new BattleTeamItemModelServer(IModel(this));
      }

      protected function getInitParam() : BattleTeamItemCC
      {
         return BattleTeamItemCC(initParams[object]);
      }

      override public function get id() : Long
      {
         return modelId;
      }
   }
}
