package alternativa.tanks.model.item.team
{
   import alternativa.tanks.controllers.BattleSelectVectorUtil;
   import alternativa.tanks.model.info.BattleParamsUtils;
   import alternativa.tanks.model.info.team.BattleTeamInfo;
   import alternativa.tanks.model.item.BattleFriendsListener;
   import alternativa.tanks.model.item.BattleItemModel;
   import alternativa.tanks.service.battlelist.IBattleListFormService;
   import alternativa.tanks.view.battleinfo.team.BattleInfoTeamParams;
   import platform.client.fp10.core.model.ObjectLoadListener;
   import projects.tanks.client.battleselect.model.battle.entrance.user.BattleInfoUser;
   import projects.tanks.client.battleselect.model.item.team.BattleTeamItemModelBase;
   import projects.tanks.client.battleselect.model.item.team.IBattleTeamItemModelBase;
   import projects.tanks.client.battleservice.model.battle.team.BattleTeam;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.friends.FriendState;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.IFriendInfoService;

   [ModelInfo]
   public class BattleTeamItemModel extends BattleTeamItemModelBase implements IBattleTeamItemModelBase, BattleTeamInfo, BattleFriendsListener, ObjectLoadListener
   {
      [Inject]
      public static var battleListFormService:IBattleListFormService;

      [Inject]
      public static var friendsInfoService:IFriendInfoService;

      public function objectLoaded() : void
      {
         try
         {
         var _loc1_:BattleInfoTeamParams = new BattleInfoTeamParams();
         _loc1_.usersBlue = this.convertUsers(getInitParam().usersBlue);
         _loc1_.usersRed = this.convertUsers(getInitParam().usersRed);
         BattleItemModel.setItemParams(object,_loc1_);
         BattleParamsUtils.registerUsers(object,_loc1_.usersBlue,_loc1_);
         BattleParamsUtils.registerUsers(object,_loc1_.usersRed,_loc1_);
         }
         catch(e:Error)
         {
            throw e;
         }
      }

      private function convertUsers(param1:Vector.<String>) : Vector.<BattleInfoUser>
      {
         var _loc2_:Vector.<BattleInfoUser> = new Vector.<BattleInfoUser>();
         var _loc3_:String = null;
         var _loc4_:BattleInfoUser = null;
         if(param1 != null)
         {
            for each(_loc3_ in param1)
            {
               _loc4_ = new BattleInfoUser();
               _loc4_.user = _loc3_;
               _loc2_.push(_loc4_);
            }
         }
         return _loc2_;
      }

      private function data() : BattleInfoTeamParams
      {
         return BattleInfoTeamParams(BattleItemModel.getItemParams(object));
      }

      public function addUser(param1:String, param2:BattleTeam) : void
      {
         if(this.data().userToInfo.get(param1) != null)
         {
            return;
         }
         var _loc1_:BattleInfoUser = new BattleInfoUser();
         _loc1_.user = param1;
         (param2 == BattleTeam.RED ? this.data().usersRed : this.data().usersBlue).push(_loc1_);
         BattleParamsUtils.registerUser(_loc1_,this.data(),object);
         battleListFormService.updateUsersCount(object.name);
      }

      public function removeUser(param1:String) : void
      {
         if(this.data().userToInfo.get(param1) == null)
         {
            return;
         }
         BattleSelectVectorUtil.deleteElementInUsersVector(this.data().usersBlue,param1);
         BattleSelectVectorUtil.deleteElementInUsersVector(this.data().usersRed,param1);
         BattleParamsUtils.unregisterUser(param1,this.data());
         battleListFormService.updateUsersCount(object.name);
      }

      public function swapTeams() : void
      {
         var _loc1_:Vector.<BattleInfoUser> = this.data().usersBlue;
         this.data().usersBlue = this.data().usersRed;
         this.data().usersRed = _loc1_;
         battleListFormService.swapTeams(object.name);
      }

      public function getUsersCountBlue() : int
      {
         return this.data().usersBlue.length;
      }

      public function getUsersCountRed() : int
      {
         return this.data().usersRed.length;
      }

      public function getFriendsCountBlue() : int
      {
         return this.countFriends(this.data().usersBlue);
      }

      public function getFriendsCountRed() : int
      {
         return this.countFriends(this.data().usersRed);
      }

      private function countFriends(param1:Vector.<BattleInfoUser>) : int
      {
         var _loc2_:int = 0;
         var _loc3_:BattleInfoUser = null;
         for each(_loc3_ in param1)
         {
            if(friendsInfoService.isFriendsInState(_loc3_.user,FriendState.ACCEPTED))
            {
               ++_loc2_;
            }
         }
         return _loc2_;
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
