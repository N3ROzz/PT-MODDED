package alternativa.tanks.models.battle.gui.inventory
{
   import alternativa.math.Vector3;
   import alternativa.tanks.battle.events.BattleEventDispatcher;
   import alternativa.tanks.battle.events.ControlMiniHelpCloseEvent;
   import alternativa.tanks.battle.events.InventoryItemActivationEvent;
   import alternativa.tanks.battle.events.StateCorrectionEvent;
   import flash.utils.Dictionary;
   import platform.client.fp10.core.model.ObjectLoadPostListener;
   import platform.client.fp10.core.model.ObjectUnloadListener;
   import platform.client.fp10.core.model.impl.Model;
   import projects.tanks.client.battlefield.models.inventory.item.IInventoryItemModelBase;
   import projects.tanks.client.battlefield.models.inventory.item.InventoryItemCC;
   import projects.tanks.client.battlefield.models.inventory.item.InventoryItemModelBase;
   
   [ModelInfo]
   public class InventoryItemModel extends InventoryItemModelBase implements IInventoryItemModelBase, ObjectUnloadListener, IInventoryItemActivator, ObjectLoadPostListener, IInventoryItem
   {
      
      [Inject] // added
      public static var inventoryPanel:IInventoryPanel;
      
      [Inject] // added
      public static var battleEventDispatcher:BattleEventDispatcher;
      
      private var itemByObject:Dictionary = new Dictionary(true);
      
      public function InventoryItemModel()
      {
         super();
      }
      
      public function updateCount(param1:int) : void
      {
         var _loc2_:InventoryItem = this.itemByObject[object];
         if(_loc2_ != null)
         {
            if(_loc2_.count <= 0 && param1 > 0)
            {
               inventoryPanel.showInventory();
               battleEventDispatcher.dispatchEvent(new ControlMiniHelpCloseEvent());
            }
            _loc2_.count = param1;
            inventoryPanel.itemUpdateCount(_loc2_);
         }
      }
      
      public function activated(param1:int, param2:Boolean) : void
      {
         var _loc3_:InventoryItem = this.itemByObject[object];
         if(_loc3_ == null || inventoryPanel == null)
         {
            return;
         }
         if(param2)
         {
            this.updateCount(Math.max(0,_loc3_.count - 1));
         }
         if(param1 > 0)
         {
            inventoryPanel.activateCooldown(_loc3_.getId(),param1);
         }
      }
      
      public function requestActivation(param1:InventoryItem) : void
      {
         battleEventDispatcher.dispatchEvent(new InventoryItemActivationEvent(param1));
      }
      
      public function doActivate(param1:InventoryItem, param2:Vector3) : void
      {
         Model.object = param1.getGameObject();
         try
         {
            battleEventDispatcher.dispatchEvent(StateCorrectionEvent.MANDATORY_UPDATE);
            server.activate(object.name);
         }
         finally
         {
            Model.popObject();
         }
      }
      
      public function objectLoadedPost() : void
      {
         var _loc1_:InventoryItemCC = getInitParam();
         var _loc2_:IInventoryPanel = inventoryPanel;
         var _loc3_:InventoryItem = new InventoryItem(object,_loc1_.itemIndex,_loc1_.count,this);
         this.itemByObject[object] = _loc3_;
         _loc2_.assignItemToSlot(_loc3_,this.getSlotIndex());
      }
      
      public function getSlotIndex() : int
      {
         return getInitParam().itemIndex;
      }
      
      public function objectUnloaded() : void
      {
         delete this.itemByObject[object];
      }
   }
}
