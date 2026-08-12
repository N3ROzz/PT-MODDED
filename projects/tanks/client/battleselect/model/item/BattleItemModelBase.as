package projects.tanks.client.battleselect.model.item
{
   import alternativa.types.Long;
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.model.impl.Model;

   public class BattleItemModelBase extends Model
   {
      protected var server:BattleItemModelServer;
      public static const modelId:Long = Long.getLong(1070957760,-175658205);

      public function BattleItemModelBase()
      {
         super();
         this.server = new BattleItemModelServer(IModel(this));
      }

      protected function getInitParam() : BattleItemCC
      {
         return BattleItemCC(initParams[object]);
      }

      override public function get id() : Long
      {
         return modelId;
      }
   }
}
