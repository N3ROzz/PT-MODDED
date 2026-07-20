package projects.tanks.client.tanksservices.model.notifier.clan
{
   public class UserClanInfoCC
   {
      
      public var isInClan:Boolean;
      
      public var clanTag:String;
      
      public var userId:String;
      
      public function UserClanInfoCC(param1:Boolean = false, param2:String = null, param3:String = null)
      {
         super();
         this.isInClan = param1;
         this.clanTag = param2;
         this.userId = param3;
      }
   }
}
