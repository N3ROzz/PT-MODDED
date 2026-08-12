package alternativa.tanks.model.item
{
   import alternativa.tanks.model.info.BattleParamsUtils;
   import alternativa.tanks.model.info.param.BattleParams;
   import alternativa.tanks.service.battle.IBattleUserInfoService;
   import alternativa.tanks.service.battlelist.IBattleListFormService;
   import alternativa.tanks.view.battleinfo.BattleInfoBaseParams;
   import flash.utils.Dictionary;
   import platform.client.fp10.core.model.ObjectLoadListener;
   import platform.client.fp10.core.model.ObjectLoadPostListener;
   import platform.client.fp10.core.model.ObjectUnloadListener;
   import platform.client.fp10.core.model.ObjectUnloadPostListener;
   import platform.client.fp10.core.type.IGameObject;
   import projects.tanks.client.battleselect.model.item.BattleItemCC;
   import projects.tanks.client.battleselect.model.item.BattleItemModelBase;
   import projects.tanks.client.battleselect.model.item.IBattleItemModelBase;
   import projects.tanks.client.battleselect.model.item.BattleSuspicionLevel;
   import scpacker.utils.EnumUtils;

   [ModelInfo]
   public class BattleItemModel extends BattleItemModelBase implements IBattleItemModelBase, BattleParams, ObjectLoadListener, ObjectLoadPostListener, ObjectUnloadListener, ObjectUnloadPostListener
   {
      [Inject]
      public static var battleListFormService:IBattleListFormService;

      [Inject]
      public static var battleUserInfoService:IBattleUserInfoService;

      private static const paramsByObject:Dictionary = new Dictionary();

      public static function setItemParams(param1:IGameObject, param2:BattleInfoBaseParams) : void
      {
         paramsByObject[param1] = param2;
      }

      public static function getItemParams(param1:IGameObject) : BattleInfoBaseParams
      {
         return BattleInfoBaseParams(paramsByObject[param1]);
      }

      public function getConstructor() : BattleItemCC
      {
         return getInitParam();
      }

      public function objectLoaded() : void
      {
      }

      public function objectLoadedPost() : void
      {
         var _loc1_:BattleInfoBaseParams = getItemParams(object);
         BattleParamsUtils.setBattleItemParams(object,getInitParam(),_loc1_);
         battleListFormService.battleItemRecord(_loc1_);
      }

      public function objectUnloaded() : void
      {
      }

      public function objectUnloadedPost() : void
      {
         var _loc1_:BattleInfoBaseParams = getItemParams(object);
         var _loc2_:String = null;
         if(_loc1_ != null)
         {
            for each(_loc2_ in _loc1_.userToInfo.getUserIds())
            {
               BattleParamsUtils.unregisterUser(_loc2_,_loc1_);
            }
         }
         battleUserInfoService.deleteBattleItem(object);
         battleListFormService.removeBattleItem(object.name);
         delete paramsByObject[object];
      }

      public function madePrivate() : void
      {
         getInitParam().privateBattle = true;
         var _loc1_:BattleInfoBaseParams = getItemParams(object);
         if(_loc1_ != null)
         {
            _loc1_.createParams.privateBattle = true;
            battleListFormService.updateBattleName(object.name);
         }
      }

      public function setBattleName(param1:String) : void
      {
         getInitParam().name = param1;
         var _loc1_:BattleInfoBaseParams = getItemParams(object);
         if(_loc1_ != null)
         {
            _loc1_.customName = param1;
            _loc1_.createParams.name = param1;
            battleListFormService.updateBattleName(object.name);
         }
      }

      public function updateSuspicion(param1:BattleSuspicionLevel) : void
      {
         getInitParam().suspicionLevel = param1;
         var _loc1_:BattleInfoBaseParams = getItemParams(object);
         if(_loc1_ != null)
         {
            _loc1_.suspicionLevel = EnumUtils.stringToBattleSuspicionLevel(param1.name);
            battleListFormService.updateSuspicious(object.name,_loc1_.suspicionLevel);
         }
      }
   }
}
