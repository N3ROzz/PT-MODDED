package alternativa.tanks.model.battle
{
   import alternativa.osgi.service.locale.ILocaleService;
   import alternativa.tanks.loader.ILoaderWindowService;
   import alternativa.tanks.loader.IModalLoaderService;
   import alternativa.tanks.service.battleinfo.IBattleInfoFormService;
   import alternativa.tanks.tracker.ITrackerService;
   import platform.client.fp10.core.model.ObjectLoadListener;
   import platform.client.fp10.core.model.ObjectLoadPostListener;
   import platform.client.fp10.core.model.ObjectUnloadListener;
   import platform.client.fp10.core.model.ObjectUnloadPostListener;
   import projects.tanks.client.battleselect.model.battle.entrance.BattleEntranceModelBase;
   import projects.tanks.client.battleselect.model.battle.entrance.IBattleEntranceModelBase;
   import projects.tanks.clients.fp10.libraries.TanksLocale;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.alertservices.IAlertService;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.logging.battlelist.UserBattleSelectActionsService;
   import services.alertservice.AlertAnswer;

   [ModelInfo]
   public class BattleEntranceModel extends BattleEntranceModelBase implements IBattleEntranceModelBase, BattleEntranceInfo, ObjectLoadListener, ObjectLoadPostListener, ObjectUnloadListener, ObjectUnloadPostListener
   {
      [Inject]
      public static var alertService:IAlertService;

      [Inject]
      public static var localeService:ILocaleService;

      [Inject]
      public static var battleAlertService:IAlertService;

      [Inject]
      public static var loaderWindowService:ILoaderWindowService;

      [Inject]
      public static var battleInfoFormService:IBattleInfoFormService;

      [Inject]
      public static var trackerService:ITrackerService;

      [Inject]
      public static var userBattleSelectActionsService:UserBattleSelectActionsService;

      [Inject]
      public static var modalLoaderService:IModalLoaderService;

      public function BattleEntranceModel()
      {
         super();
      }

      public function equipmentNotMatchConstraints() : void
      {
         modalLoaderService.hideForcibly();
         loaderWindowService.hideForcibly();
         alertService.showAlert(localeService.getText(TanksLocale.TEXT_BATTLE_ENTER_ERROR_EQUIPMENT_NOT_MATCH_CONSTRAINTS),Vector.<String>([localeService.getText(TanksLocale.TEXT_CLOSE_LABEL)]));
      }

      public function enterToBattleFailed() : void
      {
         modalLoaderService.hideForcibly();
         loaderWindowService.hideForcibly();
      }

      public function fightFailedServerIsHalting() : void
      {
         modalLoaderService.hideForcibly();
         loaderWindowService.hideForcibly();
         battleAlertService.showAlert(localeService.getText(TanksLocale.TEXT_SERVER_IS_RESTARTING_CREATE_BATTLE_TEXT),Vector.<String>([localeService.getText(AlertAnswer.OK)]));
      }

      public function getProBattleEnterPrice() : int
      {
         return getInitParam().proBattleEnterPrice;
      }

      public function getProBattleTimeLeftInSec() : int
      {
         return getInitParam().proBattleTimeLeftInSec;
      }

      public function objectLoaded() : void
      {
      }

      public function objectLoadedPost() : void
      {
      }

      public function objectUnloaded() : void
      {
      }

      public function objectUnloadedPost() : void
      {
      }
   }
}
