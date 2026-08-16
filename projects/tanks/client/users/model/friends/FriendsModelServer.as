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
         this.network.send(new AcceptFriendInviteOutPacket(param1));
      }

      public function add(param1:String) : void
      {
         this.network.send(new AddFriendOutPacket(param1));
      }

      public function addByUid(param1:String) : void
      {
         this.network.send(new CheckFriendOutPacket(param1));
      }

      public function breakItOff(param1:String) : void
      {
         this.network.send(new RemoveAcceptedFriendOutPacket(param1));
      }

      public function reject(param1:String) : void
      {
         this.network.send(new RemoveIncomingFriendOutPacket(param1));
      }

      public function rejectAll() : void
      {
      }
      
      public function revoke(param1:String) : void
      {
         this.network.send(new RevokeFriendOutPacket(param1));
      }
   }
}
