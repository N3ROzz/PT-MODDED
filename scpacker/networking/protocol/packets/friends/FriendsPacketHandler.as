package scpacker.networking.protocol.packets.friends
{
   import scpacker.networking.protocol.AbstractPacketHandler;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.friends.incomingnotificator.FriendsIncomingNotificatorModel;
   import alternativa.types.Long;
   import alternativa.tanks.model.friends.loader.FriendsLoaderModel;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.friends.acceptednotificator.FriendsAcceptedNotificatorModel;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.friends.incoming.FriendsIncomingModel;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.friends.outgoing.FriendsOutgoingModel;
   import scpacker.networking.protocol.AbstractPacket;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.FriendsModel;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.friends.accepted.FriendsAcceptedModel;
   import projects.tanks.client.users.model.friends.accepted.FriendsAcceptedModelBase;
   import projects.tanks.client.users.model.friends.acceptednotificator.FriendsAcceptedNotificatorModelBase;
   import projects.tanks.client.users.model.friends.incoming.FriendsIncomingModelBase;
   import projects.tanks.client.users.model.friends.incomingnotificator.FriendsIncomingNotificatorModelBase;
   import projects.tanks.client.users.model.friends.outgoing.FriendsOutgoingModelBase;
   import projects.tanks.client.users.model.friends.FriendsModelBase;
   import projects.tanks.client.panel.model.friends.FriendsLoaderModelBase;
   import platform.client.fp10.core.type.IGameClass;
   import platform.client.fp10.core.type.IGameObject;
   import platform.client.fp10.core.type.impl.Space;
   import platform.client.fp10.core.model.impl.Model;
   import projects.tanks.client.users.model.friends.FriendsCC;
   import projects.tanks.client.users.model.friends.container.UserContainerCC;
   import utils.TankTraceUtil;
   
   public class FriendsPacketHandler extends AbstractPacketHandler
   {
      private var friendsAcceptedModel:FriendsAcceptedModel;
      private var friendsAcceptedNotificatorModel:FriendsAcceptedNotificatorModel;
      private var friendsIncomingModel:FriendsIncomingModel;
      private var friendsIncomingNotificatorModel:FriendsIncomingNotificatorModel;
      private var friendsOutgoingModel:FriendsOutgoingModel;
      private var friendsModel:FriendsModel;
      private var friendsLoaderModel:FriendsLoaderModel;
      private var space:Space;
      
      public function FriendsPacketHandler()
      {
         super();
         this.id = 13;

         this.friendsAcceptedModel = FriendsAcceptedModel(modelRegistry.getModel(FriendsAcceptedModelBase.modelId));
         this.friendsAcceptedNotificatorModel = FriendsAcceptedNotificatorModel(modelRegistry.getModel(FriendsAcceptedNotificatorModelBase.modelId));
         this.friendsIncomingModel = FriendsIncomingModel(modelRegistry.getModel(FriendsIncomingModelBase.modelId));
         this.friendsIncomingNotificatorModel = FriendsIncomingNotificatorModel(modelRegistry.getModel(FriendsIncomingNotificatorModelBase.modelId));
         this.friendsOutgoingModel = FriendsOutgoingModel(modelRegistry.getModel(FriendsOutgoingModelBase.modelId));
         this.friendsModel = FriendsModel(modelRegistry.getModel(FriendsModelBase.modelId));
         this.friendsLoaderModel = FriendsLoaderModel(modelRegistry.getModel(FriendsLoaderModelBase.modelId));

         this.space = new Space(Long.getLong(10566810,44467896),null,null,false);
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case LoadFriendsListInPacket.id:
               this.handleLoadFriendsList(param1 as LoadFriendsListInPacket);
               break;
            case OutgoingOnAddingInPacket.id:
               this.handleOutgoingOnAdding(param1 as OutgoingOnAddingInPacket);
               break;
            case AcceptIncomingFriendInPacket.id:
               this.handleAcceptIncomingFriend(param1 as AcceptIncomingFriendInPacket);
               break;
            case IncomingOnAddingInPacket.id:
               this.handleIncomingOnAdding(param1 as IncomingOnAddingInPacket);
               break;
            case AlreadyInAcceptedFriendsInPacket.id:
               this.handleAlreadyInAcceptedFriends(param1 as AlreadyInAcceptedFriendsInPacket);
               break;
            case AlreadyInIncomingFriendsInPacket.id:
               this.handleAlreadyInIncomingFriends(param1 as AlreadyInIncomingFriendsInPacket);
               break;
            case AlreadyInOutgoingFriendsInPacket.id:
               this.handleAlreadyInOutgoingFriends(param1 as AlreadyInOutgoingFriendsInPacket);
               break;
            case FriendsAcceptedOnRemoveInPacket.id:
               this.handleAcceptedOnRemove(param1 as FriendsAcceptedOnRemoveInPacket);
               break;
            case FriendsIncomingOnRemoveInPacket.id:
               this.handleIncomingOnRemove(param1 as FriendsIncomingOnRemoveInPacket);
               break;
            case FriendsOutgoingOnRemoveInPacket.id:
               this.handleOutgoingOnRemove(param1 as FriendsOutgoingOnRemoveInPacket);
               break;
            case FriendsAcceptedNotificatorOnRemoveInPacket.id:
               this.handleAcceptedNotificatorOnRemove(param1 as FriendsAcceptedNotificatorOnRemoveInPacket);
               break;
            case FriendsIncomingNotificatorOnRemoveInPacket.id:
               this.handleIncomingNotificatorOnRemove(param1 as FriendsIncomingNotificatorOnRemoveInPacket);
               break;
            case FriendsOnUsersLoadedInPacket.id:
               this.handleUsersLoaded();
               break;
            case FriendsUidExistInPacket.id:
               this.handleUidExist();
               break;
            case FriendsUidNotExistInPacket.id:
               this.handleUidNotExist();
         }
      }
      
      private function handleLoadFriendsList(param1:LoadFriendsListInPacket) : void
      {

         var modelVector:Vector.<Long> = new Vector.<Long>();
         modelVector.push(this.friendsAcceptedModel.id);
         modelVector.push(this.friendsAcceptedNotificatorModel.id);
         modelVector.push(this.friendsIncomingModel.id);
         modelVector.push(this.friendsIncomingNotificatorModel.id);
         modelVector.push(this.friendsOutgoingModel.id);
         modelVector.push(this.friendsLoaderModel.id);
         modelVector.push(this.friendsModel.id);
         var friendsGameClass:IGameClass = this.gameTypeRegistry.createClass(Long.getLong(5555,87654321), modelVector);
         var friendsObject:IGameObject = this.space.createObject(Long.getLong(5555,87654321), friendsGameClass, "Friends game object");

         Model.object = friendsObject;

         TankTraceUtil.logFriends("LoadFriendsList accepted=" + this.countUsers(param1.friendsAcceptedCC) + " acceptedNew=" + this.countUsers(param1.friendsAcceptedNotificatorCC) + " incoming=" + this.countUsers(param1.friendsIncomingCC) + " incomingNew=" + this.countUsers(param1.friendsIncomingNotificatorCC) + " outgoing=" + this.countUsers(param1.friendsOutgoingCC));

         this.friendsModel.putInitParams(new FriendsCC(99999, 99999, true));
         this.friendsModel.objectLoaded();

         this.friendsAcceptedModel.putInitParams(param1.friendsAcceptedCC);
         this.friendsAcceptedModel.objectLoaded();

         this.friendsAcceptedNotificatorModel.putInitParams(param1.friendsAcceptedNotificatorCC);
         this.friendsAcceptedNotificatorModel.objectLoaded();

         this.friendsIncomingModel.putInitParams(param1.friendsIncomingCC);
         this.friendsIncomingModel.objectLoaded();

         this.friendsIncomingNotificatorModel.putInitParams(param1.friendsIncomingNotificatorCC);
         this.friendsIncomingNotificatorModel.objectLoaded();

         this.friendsOutgoingModel.putInitParams(param1.friendsOutgoingCC);
         this.friendsOutgoingModel.objectLoaded();

         this.friendsLoaderModel.objectLoadedPost();
         this.friendsLoaderModel.onUsersLoaded();
         Model.popObject();
      }
      
      private function handleUsersLoaded() : void
      {
         this.friendsLoaderModel.onUsersLoaded();
      }
      
      private function handleOutgoingOnAdding(param1:OutgoingOnAddingInPacket) : void
      {
         TankTraceUtil.logFriends("packet=" + OutgoingOnAddingInPacket.id + " action=outgoingAdd userId=" + param1.userId);
         this.friendsOutgoingModel.onAdding(param1.userId);
      }
      
      private function handleAcceptIncomingFriend(param1:AcceptIncomingFriendInPacket) : void
      {
         TankTraceUtil.logFriends("packet=" + AcceptIncomingFriendInPacket.id + " action=acceptedAdd userId=" + param1.userId);
         this.friendsAcceptedModel.onAdding(param1.userId);
         this.friendsAcceptedNotificatorModel.onAdding(param1.userId);
         this.friendsIncomingNotificatorModel.onRemoved(param1.userId);
      }
      
      private function handleIncomingOnAdding(param1:IncomingOnAddingInPacket) : void
      {
         TankTraceUtil.logFriends("packet=" + IncomingOnAddingInPacket.id + " action=incomingAdd userId=" + param1.userId);
         this.friendsIncomingModel.onAdding(param1.userId);
         this.friendsIncomingNotificatorModel.onAdding(param1.userId);
      }
      
      private function handleAlreadyInAcceptedFriends(param1:AlreadyInAcceptedFriendsInPacket) : void
      {
         TankTraceUtil.logFriends("packet=" + AlreadyInAcceptedFriendsInPacket.id + " action=alreadyAccepted userId=" + param1.userId);
         this.friendsOutgoingModel.onRemoved(param1.userId);
         this.friendsModel.alreadyInAcceptedFriends(param1.userId);
      }
      
      private function handleAlreadyInIncomingFriends(param1:AlreadyInIncomingFriendsInPacket) : void
      {
         TankTraceUtil.logFriends("packet=" + AlreadyInIncomingFriendsInPacket.id + " action=alreadyIncoming userId=" + param1.userId);
         this.friendsOutgoingModel.onRemoved(param1.userId);
         this.friendsModel.alreadyInIncomingFriends(param1.userId,param1.userId);
      }
      
      private function handleAlreadyInOutgoingFriends(param1:AlreadyInOutgoingFriendsInPacket) : void
      {
         TankTraceUtil.logFriends("packet=" + AlreadyInOutgoingFriendsInPacket.id + " action=alreadyOutgoing userId=" + param1.userId);
         this.friendsOutgoingModel.onAdding(param1.userId);
         this.friendsModel.alreadyInOutgoingFriends(param1.userId);
      }
      
      private function handleAcceptedOnRemove(param1:FriendsAcceptedOnRemoveInPacket) : void
      {
         TankTraceUtil.logFriends("packet=" + FriendsAcceptedOnRemoveInPacket.id + " action=acceptedRemove userId=" + param1.userId);
         this.friendsAcceptedModel.onRemoved(param1.userId);
         this.friendsAcceptedNotificatorModel.onRemoved(param1.userId);
      }
      
      private function handleOutgoingOnRemove(param1:FriendsOutgoingOnRemoveInPacket) : void
      {
         TankTraceUtil.logFriends("packet=" + FriendsOutgoingOnRemoveInPacket.id + " action=outgoingRemove userId=" + param1.userId);
         this.friendsOutgoingModel.onRemoved(param1.userId);
      }
      
      private function handleIncomingOnRemove(param1:FriendsIncomingOnRemoveInPacket) : void
      {
         TankTraceUtil.logFriends("packet=" + FriendsIncomingOnRemoveInPacket.id + " action=incomingRemove userId=" + param1.userId);
         this.friendsIncomingModel.onRemoved(param1.userId);
         this.friendsIncomingNotificatorModel.onRemoved(param1.userId);
      }
      
      private function handleAcceptedNotificatorOnRemove(param1:FriendsAcceptedNotificatorOnRemoveInPacket) : void
      {
         TankTraceUtil.logFriends("packet=" + FriendsAcceptedNotificatorOnRemoveInPacket.id + " action=acceptedNotificatorAdd userId=" + param1.userId);
         this.friendsAcceptedNotificatorModel.onAdding(param1.userId);
      }
      
      private function handleIncomingNotificatorOnRemove(param1:FriendsIncomingNotificatorOnRemoveInPacket) : void
      {
         TankTraceUtil.logFriends("packet=" + FriendsIncomingNotificatorOnRemoveInPacket.id + " action=incomingNotificatorAdd userId=" + param1.userId);
         this.friendsIncomingNotificatorModel.onAdding(param1.userId);
      }
      
      private function handleUidExist() : void
      {
         TankTraceUtil.logFriends("packet=" + FriendsUidExistInPacket.id + " action=uidExist");
         this.friendsModel.uidExist();
      }
      
      private function handleUidNotExist() : void
      {
         TankTraceUtil.logFriends("packet=" + FriendsUidNotExistInPacket.id + " action=uidNotExist");
         this.friendsModel.uidNotExist();
      }

      private function countUsers(param1:UserContainerCC) : int
      {
         if(param1 == null || param1.users == null)
         {
            return 0;
         }
         return param1.users.length;
      }
   }
}
