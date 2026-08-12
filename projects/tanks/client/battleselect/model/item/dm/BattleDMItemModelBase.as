package projects.tanks.client.battleselect.model.item.dm
{
   import alternativa.types.Long;
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.model.impl.Model;

   public class BattleDMItemModelBase extends Model
   {
      protected var server:BattleDMItemModelServer;
      public static const modelId:Long = Long.getLong(-1403835428,-1468635420);

      public function BattleDMItemModelBase()
      {
         super();
         this.server = new BattleDMItemModelServer(IModel(this));
      }

      protected function getInitParam() : BattleDMItemCC
      {
         return BattleDMItemCC(initParams[object]);
      }

      override public function get id() : Long
      {
         return modelId;
      }
   }
}
