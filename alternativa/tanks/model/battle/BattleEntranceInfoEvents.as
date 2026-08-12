package alternativa.tanks.model.battle
{
   import platform.client.fp10.core.model.impl.Model;
   import platform.client.fp10.core.type.IGameObject;

   public class BattleEntranceInfoEvents implements BattleEntranceInfo
   {
      private var object:IGameObject;
      private var impl:Vector.<Object>;

      public function BattleEntranceInfoEvents(param1:IGameObject, param2:Vector.<Object>)
      {
         this.object = param1;
         this.impl = param2;
      }

      public function getProBattleEnterPrice() : int
      {
         var _loc1_:int;
         Model.object = this.object;
         try
         {
            for each(var _loc2_:BattleEntranceInfo in this.impl)
            {
               _loc1_ = _loc2_.getProBattleEnterPrice();
            }
         }
         finally
         {
            Model.popObject();
         }
         return _loc1_;
      }

      public function getProBattleTimeLeftInSec() : int
      {
         var _loc1_:int;
         Model.object = this.object;
         try
         {
            for each(var _loc2_:BattleEntranceInfo in this.impl)
            {
               _loc1_ = _loc2_.getProBattleTimeLeftInSec();
            }
         }
         finally
         {
            Model.popObject();
         }
         return _loc1_;
      }
   }
}
