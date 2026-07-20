package projects.tanks.clients.fp10.libraries.tanksservices.service.clan
{
   import flash.events.EventDispatcher;
   import flash.utils.Dictionary;
   
   public class ClanUserInfoServiceImpl extends EventDispatcher implements ClanUserInfoService
   {
      
      private var infos:Dictionary = new Dictionary();
      
      public function ClanUserInfoServiceImpl()
      {
         super();
      }
      
      public function userClanInfoByUserId(param1:String) : UserClanInfo
      {
         if(param1 == null || param1 == "")
         {
            return null;
         }
         return this.infos[param1] as UserClanInfo;
      }
      
      public function updateUserClanInfo(param1:UserClanInfo) : void
      {
         var _loc2_:UserClanInfo = null;
         if(param1 == null || param1.userId == null || param1.userId == "")
         {
            return;
         }
         _loc2_ = this.userClanInfoByUserId(param1.userId);
         this.infos[param1.userId] = param1;
         if((_loc2_ == null || !_loc2_.isInClan) && param1.isInClan)
         {
            dispatchEvent(new ClanUserInfoEvent(ClanUserInfoEvent.ON_JOIN_CLAN));
         }
         else if(_loc2_ != null && _loc2_.isInClan && !param1.isInClan)
         {
            dispatchEvent(new ClanUserInfoEvent(ClanUserInfoEvent.ON_LEAVE_CLAN));
         }
      }
      
      public function removeUserClanInfo(param1:String) : void
      {
         var _loc2_:UserClanInfo = null;
         if(param1 == null || param1 == "")
         {
            return;
         }
         _loc2_ = this.userClanInfoByUserId(param1);
         delete this.infos[param1];
         if(_loc2_ != null && _loc2_.isInClan)
         {
            dispatchEvent(new ClanUserInfoEvent(ClanUserInfoEvent.ON_LEAVE_CLAN));
         }
      }
   }
}

