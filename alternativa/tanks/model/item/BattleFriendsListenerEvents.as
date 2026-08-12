package alternativa.tanks.model.item
{
   import platform.client.fp10.core.model.impl.Model;
   import platform.client.fp10.core.type.IGameObject;
   
   public class BattleFriendsListenerEvents implements BattleFriendsListener
   {
      
      private var object:IGameObject;
      
      private var impl:Vector.<Object>;
      
      public function BattleFriendsListenerEvents(param1:IGameObject, param2:Vector.<Object>)
      {
         super();
         this.object = param1;
         this.impl = param2;
      }
      
      public function onAddFriend(param1:String) : void
      {
         var i:int = 0;
         var m:BattleFriendsListener = null;
         var userId:String = param1;
         try
         {
            Model.object = this.object;
            i = 0;
            while(i < this.impl.length)
            {
               m = BattleFriendsListener(this.impl[i]);
               m.onAddFriend(userId);
               i++;
            }
         }
         finally
         {
            Model.popObject();
         }
      }
      
      public function onDeleteFriend(param1:String) : void
      {
         var i:int = 0;
         var m:BattleFriendsListener = null;
         var userId:String = param1;
         try
         {
            Model.object = this.object;
            i = 0;
            while(i < this.impl.length)
            {
               m = BattleFriendsListener(this.impl[i]);
               m.onDeleteFriend(userId);
               i++;
            }
         }
         finally
         {
            Model.popObject();
         }
      }
   }
}
