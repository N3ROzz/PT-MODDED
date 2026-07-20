package scpacker.networking.protocol.packets.bonusregion
{
   import scpacker.networking.protocol.AbstractPacketHandler;
   import alternativa.types.Long;
   import alternativa.tanks.models.bonus.region.BonusRegionsModel;
   import scpacker.networking.protocol.AbstractPacket;
   import projects.tanks.client.battlefield.models.bonus.battle.bonusregions.BonusRegionsModelBase;
   import alternativa.tanks.services.bonusregion.IBonusRegionService;
   import flash.display.Stage;
   import flash.events.KeyboardEvent;
   import flash.ui.Keyboard;
   import projects.tanks.client.battlefield.models.bonus.battle.bonusregions.BonusRegionData;
   import projects.tanks.client.battlefield.types.Vector3d;
   import projects.tanks.client.battlefield.models.bonus.bonus.BonusesType;
   import alternativa.osgi.service.display.IDisplay;
   import platform.client.fp10.core.model.impl.Model;
   import scpacker.networking.protocol.packets.battle.BattlePacketHandler;
   import alternativa.tanks.models.bonus.goldbonus.GoldBonusesModel;
   import projects.tanks.client.battlefield.models.bonus.battle.goldbonus.GoldBonusesModelBase;
   import projects.tanks.client.battlefield.models.bonus.battle.goldbonus.GoldBonusCC;
   import utils.TankNameGameObjectMapper;
   import platform.client.fp10.core.type.IGameObject;
   import alternativa.tanks.models.tank.ITankModel;
   import alternativa.tanks.battle.objects.tank.Tank;
   import alternativa.math.Vector3;
   import alternativa.tanks.battle.BattleUtils;
   import utils.goldbox.GoldBoxDiagnostics;
   
   public class BonusRegionPacketHandler extends AbstractPacketHandler
   {
      [Inject] // added
      public static var bonusRegionService:IBonusRegionService;
      
      private var bonusRegionsModel:BonusRegionsModel;
      private var goldBonusesModel:GoldBonusesModel;
      private var lastzone:BonusRegionData = null;

      public function BonusRegionPacketHandler()
      {
         super();
         this.id = 78;
         this.bonusRegionsModel = BonusRegionsModel(modelRegistry.getModel(BonusRegionsModelBase.modelId));
         this.goldBonusesModel = GoldBonusesModel(modelRegistry.getModel(GoldBonusesModelBase.modelId));
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case LoadBonusRegionsModelInPacket.id:
               this.load(param1 as LoadBonusRegionsModelInPacket);
               break;
            case ShowDropZoneInPacket.id:
               this.showDropZone(param1 as ShowDropZoneInPacket);
               break;
            case HideDropZoneInPacket.id:
               this.hideDropZone(param1 as HideDropZoneInPacket);
         }
      }
      
      private function load(param1:LoadBonusRegionsModelInPacket) : void
      {
         Model.object = BattlePacketHandler.battlefieldGameObject;
         this.goldBonusesModel.putInitParams(new GoldBonusCC(new Vector.<BonusRegionData>()));
         this.bonusRegionsModel.putInitParams(param1.cc);
         this.bonusRegionsModel.objectLoaded();
         this.bonusRegionsModel.objectLoadedPost();
         Model.popObject();
      }
      
      private function showDropZone(param1:ShowDropZoneInPacket) : void
      {
         var _loc2_:Vector3 = null;
         if(param1 != null && param1.bonusRegion != null && param1.bonusRegion.position != null && param1.bonusRegion.regionType == BonusesType.GOLD)
         {
            _loc2_ = BattleUtils.getVector3(param1.bonusRegion.position);
            GoldBoxDiagnostics.noteDropZoneSource(_loc2_.toString(),"packet_show",param1.bonusRegion.regionType.name,_loc2_.x,_loc2_.y,_loc2_.z,"DROP_ZONE_PACKET_RECEIVED");
         }
         bonusRegionService.addAndShowRegion(param1.bonusRegion);
      }
      
      private function hideDropZone(param1:HideDropZoneInPacket) : void
      {
         bonusRegionService.hideAndRemoveRegion(param1.bonusRegion);
      }
   }
}
