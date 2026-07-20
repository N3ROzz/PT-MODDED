package projects.tanks.client.users.model.friends.outgoing
{
   import alternativa.types.Long;
   import platform.client.fp10.core.model.IModel;
   import platform.client.fp10.core.model.impl.Model;
   import projects.tanks.client.users.model.friends.container.UserContainerCC;
   
   public class FriendsOutgoingModelBase extends Model
   {
      
      protected var server:FriendsOutgoingModelServer;
      
      public static const modelId:Long = Long.getLong(1522959740,-985374708);
      
      public function FriendsOutgoingModelBase()
      {
         super();
         this.initCodecs();
      }
      
      protected function initCodecs() : void
      {
         this.server = new FriendsOutgoingModelServer(IModel(this));
      }
      
      protected function getInitParam() : UserContainerCC
      {
         return UserContainerCC(initParams[Model.object]);
      }
      
      override public function get id() : Long
      {
         return modelId;
      }
   }
}
