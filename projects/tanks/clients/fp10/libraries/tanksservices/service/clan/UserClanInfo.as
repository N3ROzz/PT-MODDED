package projects.tanks.clients.fp10.libraries.tanksservices.service.clan
{
   public class UserClanInfo
   {
      
      public var userId:String;
      
      public var isInClan:Boolean;
      
      public var clanTag:String;
      
      public function UserClanInfo(param1:Boolean = false, param2:String = null, param3:String = null)
      {
         super();
         this.isInClan = param1;
         this.clanTag = param2;
         this.userId = param3;
      }
   }
}

