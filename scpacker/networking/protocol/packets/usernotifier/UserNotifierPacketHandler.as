package scpacker.networking.protocol.packets.usernotifier
{
   import scpacker.networking.protocol.AbstractPacketHandler;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.notifier.rank.RankNotifierModel;
   import projects.tanks.client.tanksservices.model.notifier.rank.RankNotifierData;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.notifier.online.OnlineNotifierModel;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.notifier.premium.PremiumNotifierModel;
   import alternativa.types.Long;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.listener.UserNotifierModel;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.notifier.battle.BattleNotifierModel;
   import projects.tanks.client.tanksservices.model.notifier.battle.BattleNotifierData;
   import projects.tanks.client.tanksservices.model.notifier.premium.PremiumNotifierCC;
   import scpacker.networking.protocol.AbstractPacket;
   import projects.tanks.client.tanksservices.model.notifier.online.OnlineNotifierData;
   import scpacker.networking.protocol.packets.usernotifier.InBattleStatusInPacket;
   import scpacker.networking.protocol.packets.usernotifier.ClanUserInfoInPacket;
   import scpacker.networking.protocol.packets.usernotifier.NotInBattleStatusInPacket;
   import scpacker.networking.protocol.packets.usernotifier.OnlineStatusInPacket;
   import scpacker.networking.protocol.packets.usernotifier.PremiumStatusInPacket;
   import scpacker.networking.protocol.packets.usernotifier.RankStatusInPacket;
   import scpacker.networking.protocol.packets.usernotifier.UserStringStatusInPacket;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.notifier.uid.UidNotifierModel;
   import projects.tanks.client.tanksservices.model.listener.UserNotifierModelBase;
   import controls.Rank;
   import projects.tanks.client.tanksservices.model.notifier.rank.RankNotifierModelBase;
   import projects.tanks.client.tanksservices.model.notifier.uid.UidNotifierModelBase;
   import projects.tanks.client.tanksservices.model.notifier.online.OnlineNotifierModelBase;
   import projects.tanks.client.tanksservices.model.notifier.premium.PremiumNotifierModelBase;
   import projects.tanks.client.tanksservices.model.notifier.battle.BattleNotifierModelBase;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.premium.BattleUserPremiumService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.premium.PremiumService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.clan.ClanUserInfoService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.clan.UserClanInfo;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.user.IUserInfoLabelUpdater;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.user.IUserInfoService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.userproperties.IUserPropertiesService;
   import alternativa.osgi.OSGi;
   import projects.tanks.client.tanksservices.model.notifier.premium.PremiumNotifierData;
   import utils.TankTraceUtil;
   
   public class UserNotifierPacketHandler extends AbstractPacketHandler
   {
      private var userNotifierModel:UserNotifierModel;
      private var rankNotifierModel:RankNotifierModel;
      private var uidNotifierModel:UidNotifierModel;
      private var onlineNotifierModel:OnlineNotifierModel;
      private var battleNotifierModel:BattleNotifierModel;

      private var battleUserPremiumService:BattleUserPremiumService;
      private var premiumService:PremiumService;
      private var clanUserInfoService:ClanUserInfoService;
      private var userInfoService:IUserInfoService;
      private var userPropertiesService:IUserPropertiesService;
      
      public function UserNotifierPacketHandler()
      {
         super();
         this.id = 18;
         this.userNotifierModel = UserNotifierModel(modelRegistry.getModel(UserNotifierModelBase.modelId));
         this.userNotifierModel.objectLoaded();
         this.rankNotifierModel = RankNotifierModel(modelRegistry.getModel(RankNotifierModelBase.modelId));
         this.uidNotifierModel = UidNotifierModel(modelRegistry.getModel(UidNotifierModelBase.modelId));
         this.onlineNotifierModel = OnlineNotifierModel(modelRegistry.getModel(OnlineNotifierModelBase.modelId));
         this.battleNotifierModel = BattleNotifierModel(modelRegistry.getModel(BattleNotifierModelBase.modelId));
         this.battleNotifierModel.objectLoaded();

         this.battleUserPremiumService = OSGi.getInstance().getService(BattleUserPremiumService) as BattleUserPremiumService;
         this.premiumService = OSGi.getInstance().getService(PremiumService) as PremiumService;
         this.clanUserInfoService = OSGi.getInstance().getService(ClanUserInfoService) as ClanUserInfoService;
         this.userInfoService = OSGi.getInstance().getService(IUserInfoService) as IUserInfoService;
         this.userPropertiesService = OSGi.getInstance().getService(IUserPropertiesService) as IUserPropertiesService;
         TankTraceUtil.logPremium("UserNotifierPacketHandler ctor premiumServiceNull=" + (this.premiumService == null) + " userPropertiesServiceNull=" + (this.userPropertiesService == null) + " localUserId=" + (this.userPropertiesService == null ? "null" : this.userPropertiesService.userId));
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case RankStatusInPacket.id:
               this.setRank(param1 as RankStatusInPacket);
               break;
            case OnlineStatusInPacket.id:
               this.setOnline(param1 as OnlineStatusInPacket);
               break;
            case UserStringStatusInPacket.id:
               this.newname_8545__END(param1 as UserStringStatusInPacket);
               break;
            case PremiumStatusInPacket.id:
               this.setPremiumTimeLeft(param1 as PremiumStatusInPacket);
               break;
            case ClanUserInfoInPacket.id:
               TankTraceUtil.logClanUserInfo("packet received handler=18 packet=" + ClanUserInfoInPacket.id);
               this.setClanUserInfo(param1 as ClanUserInfoInPacket);
               break;
            case InBattleStatusInPacket.id:
               this.setBattle(param1 as InBattleStatusInPacket);
               break;
            case NotInBattleStatusInPacket.id:
               this.leaveBattle(param1 as NotInBattleStatusInPacket);
         }
      }
      
      private function setRank(param1:RankStatusInPacket) : void
      {
         this.rankNotifierModel.setRank(new <RankNotifierData>[param1.userInfo]);
      }
      
      private function setOnline(param1:OnlineStatusInPacket) : void
      {
         this.onlineNotifierModel.setOnline(new <OnlineNotifierData>[param1.userInfo]);
      }
      
      private function newname_8545__END(param1:UserStringStatusInPacket) : void
      {
         throw new ArgumentError();
      }
      
      private function setPremiumTimeLeft(param1:PremiumStatusInPacket) : void
      {
         if(param1 == null || param1.premiumData == null)
         {
            TankTraceUtil.logPremium("setPremiumTimeLeft skipped nullPacketOrData packetNull=" + (param1 == null));
            return;
         }
         TankTraceUtil.logPremium("setPremiumTimeLeft packet userId=" + param1.premiumData.userId + " localUserId=" + (this.userPropertiesService == null ? "null" : this.userPropertiesService.userId) + " timeLeft=" + param1.premiumData.premiumTimeLeftInSeconds + " isLocal=" + this.isLocalPremiumData(param1.premiumData));
         if(this.battleUserPremiumService != null)
         {
            this.battleUserPremiumService.setUsersPremiumProtanki(new <PremiumNotifierData>[param1.premiumData]);
         }
         if(this.premiumService != null && this.isLocalPremiumData(param1.premiumData))
         {
            this.premiumService.updateTimeLeft(param1.premiumData.premiumTimeLeftInSeconds);
            TankTraceUtil.logPremium("updated global PremiumService timeLeft=" + param1.premiumData.premiumTimeLeftInSeconds + " hasPremium=" + this.premiumService.hasPremium());
         }
         else
         {
            TankTraceUtil.logPremium("did not update global PremiumService premiumServiceNull=" + (this.premiumService == null) + " isLocal=" + this.isLocalPremiumData(param1.premiumData));
         }
      }

      private function isLocalPremiumData(param1:PremiumNotifierData) : Boolean
      {
         if(param1.userId == null || param1.userId == "")
         {
            return true;
         }
         return this.userPropertiesService != null && param1.userId == this.userPropertiesService.userId;
      }
      
      private function setClanUserInfo(param1:ClanUserInfoInPacket) : void
      {
         var _loc2_:UserClanInfo = null;
         if(param1 == null || param1.userClanInfo == null)
         {
            TankTraceUtil.logClanUserInfo("ClanUserInfo skipped nullPacketOrData packetNull=" + (param1 == null));
            return;
         }
         if(this.clanUserInfoService == null)
         {
            TankTraceUtil.logClanUserInfo("ClanUserInfo skipped serviceNull=true userId=" + param1.userClanInfo.userId);
            return;
         }
         this.clanUserInfoService.updateUserClanInfo(new UserClanInfo(param1.userClanInfo.isInClan,param1.userClanInfo.clanTag,param1.userClanInfo.userId));
         this.notifyClanTagUpdated(param1.userClanInfo.userId,param1.userClanInfo.clanTag);
         _loc2_ = this.clanUserInfoService.userClanInfoByUserId(param1.userClanInfo.userId);
         TankTraceUtil.logClanUserInfo("ClanUserInfo received: userId=" + param1.userClanInfo.userId + ", isInClan=" + param1.userClanInfo.isInClan + ", clanTag=" + param1.userClanInfo.clanTag);
         TankTraceUtil.logClanUserInfo("ClanUserInfo cacheCheck userId=" + param1.userClanInfo.userId + ", infoExists=" + (_loc2_ != null) + ", isInClan=" + (_loc2_ == null ? "null" : _loc2_.isInClan) + ", clanTag=" + (_loc2_ == null ? "null" : _loc2_.clanTag));
      }
      
      private function notifyClanTagUpdated(param1:String, param2:String) : void
      {
         var _loc3_:IUserInfoLabelUpdater = null;
         if(param1 == null || param1 == "" || this.userInfoService == null || !this.userInfoService.hasConsumer(param1))
         {
            return;
         }
         _loc3_ = this.userInfoService.getConsumer(param1) as IUserInfoLabelUpdater;
         if(_loc3_ != null)
         {
            _loc3_.updateClanTag(param2,param1);
         }
      }
      
      private function setBattle(param1:InBattleStatusInPacket) : void
      {
         this.battleNotifierModel.setBattle(new <BattleNotifierData>[param1.userInfo]);
      }
      
      private function leaveBattle(param1:NotInBattleStatusInPacket) : void
      {
         this.battleNotifierModel.leaveBattle(param1.userId);
      }
   }
}
