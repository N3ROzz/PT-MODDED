package alternativa.tanks.model.item.dm
{
   import alternativa.tanks.controllers.BattleSelectVectorUtil;
   import alternativa.tanks.model.info.BattleParamsUtils;
   import alternativa.tanks.model.item.BattleFriendsListener;
   import alternativa.tanks.model.item.BattleItemModel;
   import alternativa.tanks.service.battlelist.IBattleListFormService;
   import alternativa.tanks.view.battleinfo.dm.BattleInfoDmParams;
   import platform.client.fp10.core.model.ObjectLoadListener;
   import projects.tanks.client.battleselect.model.battle.entrance.user.BattleInfoUser;
   import projects.tanks.client.battleselect.model.item.dm.BattleDMItemModelBase;
   import projects.tanks.client.battleselect.model.item.dm.IBattleDMItemModelBase;
   import utils.TankTraceUtil;

   [ModelInfo]
   public class BattleDMItemModel extends BattleDMItemModelBase implements IBattleDMItemModelBase, IBattleDMItem, BattleFriendsListener, ObjectLoadListener
   {
      [Inject]
      public static var battleListFormService:IBattleListFormService;

      public function objectLoaded() : void
      {
         TankTraceUtil.logBattleListQa("01_DM_OBJECT_LOADED_BEGIN battleId=" + object.name);
         try
         {
         var _loc1_:BattleInfoDmParams = new BattleInfoDmParams();
         var _loc2_:String = null;
         var _loc3_:BattleInfoUser = null;
         _loc1_.users = new Vector.<BattleInfoUser>();
         if(getInitParam().users != null)
         {
            for each(_loc2_ in getInitParam().users)
            {
               _loc3_ = new BattleInfoUser();
               _loc3_.user = _loc2_;
               _loc1_.users.push(_loc3_);
            }
         }
         BattleItemModel.setItemParams(object,_loc1_);
         BattleParamsUtils.registerUsers(object,_loc1_.users,_loc1_);
         }
         catch(e:Error)
         {
            TankTraceUtil.logBattleListQa("01_DM_OBJECT_LOADED_FAILED battleId=" + object.name + " error=" + e.name + " message=" + e.message + " stack=" + e.getStackTrace());
            throw e;
         }
         TankTraceUtil.logBattleListQa("01_DM_OBJECT_LOADED_COMPLETE battleId=" + object.name);
      }

      private function data() : BattleInfoDmParams
      {
         return BattleInfoDmParams(BattleItemModel.getItemParams(object));
      }

      public function addUser(param1:String) : void
      {
         if(this.data().userToInfo.get(param1) != null)
         {
            return;
         }
         var _loc1_:BattleInfoUser = new BattleInfoUser();
         _loc1_.user = param1;
         this.data().users.push(_loc1_);
         BattleParamsUtils.registerUser(_loc1_,this.data(),object);
         battleListFormService.updateUsersCount(object.name);
      }

      public function removeUser(param1:String) : void
      {
         if(this.data().userToInfo.get(param1) == null)
         {
            return;
         }
         BattleSelectVectorUtil.deleteElementInUsersVector(this.data().users,param1);
         BattleParamsUtils.unregisterUser(param1,this.data());
         battleListFormService.updateUsersCount(object.name);
      }

      public function getUsersCount() : int
      {
         return this.data().users.length;
      }

      public function getFriendsCount() : int
      {
         return this.data().friends;
      }

      public function onAddFriend(param1:String) : void
      {
         ++this.data().friends;
         battleListFormService.updateUsersCount(object.name);
      }

      public function onDeleteFriend(param1:String) : void
      {
         --this.data().friends;
         battleListFormService.updateUsersCount(object.name);
      }
   }
}
