package projects.tanks.client.users.model.friends
{
   import alternativa.osgi.OSGi;
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.type.IGameObject;
   import scpacker.networking.Network;
   import scpacker.networking.protocol.packets.friends.AcceptFriendInviteOutPacket;
   import scpacker.networking.protocol.packets.friends.AddFriendOutPacket;
   import scpacker.networking.protocol.packets.friends.CheckFriendOutPacket;
   import scpacker.networking.protocol.packets.friends.RemoveAcceptedFriendOutPacket;
   import scpacker.networking.protocol.packets.friends.RemoveIncomingFriendOutPacket;
   import scpacker.networking.protocol.packets.friends.RevokeFriendOutPacket;
   import utils.TankTraceUtil;

   public class FriendsModelServer
   {

      private var network:Network = OSGi.getInstance().getService(Network) as Network;
      
      private var model:IModel;

      public function FriendsModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }

      public function accept(param1:String) : void
      {
         TankTraceUtil.logFriends("outbound packet=" + AcceptFriendInviteOutPacket.id + " action=accept userId=" + param1);
         this.network.send(new AcceptFriendInviteOutPacket(param1));
      }

      public function add(param1:String) : void
      {
         TankTraceUtil.logFriends("outbound packet=" + AddFriendOutPacket.id + " action=addFriend uid=" + param1);
         this.network.send(new AddFriendOutPacket(param1));
      }

      public function addByUid(param1:String) : void
      {
         TankTraceUtil.logFriends("outbound packet=" + CheckFriendOutPacket.id + " action=checkUid uid=" + param1);
         this.network.send(new CheckFriendOutPacket(param1));
      }

      public function breakItOff(param1:String) : void
      {
         TankTraceUtil.logFriends("outbound packet=" + RemoveAcceptedFriendOutPacket.id + " action=breakOff userId=" + param1);
         this.network.send(new RemoveAcceptedFriendOutPacket(param1));
      }

      public function reject(param1:String) : void
      {
         TankTraceUtil.logFriends("outbound packet=" + RemoveIncomingFriendOutPacket.id + " action=rejectIncoming userId=" + param1);
         this.network.send(new RemoveIncomingFriendOutPacket(param1));
      }

      public function rejectAll() : void
      {
      }
      
      public function revoke(param1:String) : void
      {
         TankTraceUtil.logFriends("outbound packet=" + RevokeFriendOutPacket.id + " action=revokeOutgoing userId=" + param1);
         this.network.send(new RevokeFriendOutPacket(param1));
      }
   }
}
