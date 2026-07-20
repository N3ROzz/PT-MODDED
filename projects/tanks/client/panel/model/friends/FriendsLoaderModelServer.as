package projects.tanks.client.panel.model.friends
{
   import alternativa.osgi.OSGi;
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.type.IGameObject;
   import scpacker.networking.Network;
   import scpacker.networking.protocol.packets.friends.FriendsLoadOutPacket;

   public class FriendsLoaderModelServer
   {

      private var network:Network = OSGi.getInstance().getService(Network) as Network;
      
      private var model:IModel;

      public function FriendsLoaderModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }

      public function show() : void
      {
         this.network.send(new FriendsLoadOutPacket());
      }
   }
}
