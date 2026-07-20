package projects.tanks.client.users.model.friends.acceptednotificator
{
   import alternativa.osgi.OSGi;
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.type.IGameObject;
   import scpacker.networking.Network;
   import scpacker.networking.protocol.packets.friends.FriendsAcceptedNotificatorOnRemoveInPacket;

   public class FriendsAcceptedNotificatorModelServer
   {

      private var network:Network = OSGi.getInstance().getService(Network) as Network;
      
      private var model:IModel;

      public function FriendsAcceptedNotificatorModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }

      public function remove(param1:String) : void
      {
         this.network.send(new FriendsAcceptedNotificatorOnRemoveInPacket(param1));
      }
   }
}
