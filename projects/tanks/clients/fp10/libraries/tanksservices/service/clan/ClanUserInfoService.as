package projects.tanks.clients.fp10.libraries.tanksservices.service.clan
{
   import flash.events.IEventDispatcher;
   
   public interface ClanUserInfoService extends IEventDispatcher
   {
      
      function userClanInfoByUserId(param1:String) : UserClanInfo;
      
      function updateUserClanInfo(param1:UserClanInfo) : void;
      
      function removeUserClanInfo(param1:String) : void;
   }
}

