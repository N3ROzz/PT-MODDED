package projects.tanks.clients.fp10.libraries.tanksservices.model.friends.outgoing
{
   import platform.client.fp10.core.model.ObjectLoadListener;
   import projects.tanks.client.users.model.friends.container.UserContainerCC;
   import projects.tanks.client.users.model.friends.outgoing.FriendsOutgoingModelBase;
   import projects.tanks.client.users.model.friends.outgoing.IFriendsOutgoingModelBase;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.IFriends;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.friends.FriendState;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.IFriendInfoService;
   
   [ModelInfo]
   public class FriendsOutgoingModel extends FriendsOutgoingModelBase implements IFriendsOutgoingModelBase, ObjectLoadListener
   {
      
      [Inject] // added
      public static var friendsInfoService:IFriendInfoService;
      
      public function FriendsOutgoingModel()
      {
         super();
      }
      
      public function objectLoaded() : void
      {
         var _loc1_:UserContainerCC = null;
         var _loc2_:String = null;
         if(IFriends(object.adapt(IFriends)).isLocal())
         {
            _loc1_ = getInitParam();
            for each(_loc2_ in _loc1_.users)
            {
               friendsInfoService.setFriendState(_loc2_,FriendState.OUTGOING);
            }
         }
      }
      
      public function onAdding(param1:String) : void
      {
         if(IFriends(object.adapt(IFriends)).isLocal())
         {
            friendsInfoService.setFriendState(param1,FriendState.OUTGOING);
         }
      }
      
      public function onRemoved(param1:String) : void
      {
         if(IFriends(object.adapt(IFriends)).isLocal())
         {
            friendsInfoService.deleteFriend(param1,FriendState.OUTGOING);
         }
      }
   }
}
