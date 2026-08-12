package alternativa.tanks.model.battle
{
   import platform.client.fp10.core.model.impl.Model;
   import platform.client.fp10.core.type.IGameObject;

   public class BattleEntranceInfoAdapt implements BattleEntranceInfo
   {
      private var object:IGameObject;
      private var impl:BattleEntranceInfo;

      public function BattleEntranceInfoAdapt(param1:IGameObject, param2:BattleEntranceInfo)
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
            _loc1_ = this.impl.getProBattleEnterPrice();
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
            _loc1_ = this.impl.getProBattleTimeLeftInSec();
         }
         finally
         {
            Model.popObject();
         }
         return _loc1_;
      }
   }
}
