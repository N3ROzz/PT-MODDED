package alternativa.tanks.model.item.kit
{
   import alternativa.tanks.model.item.discount.DiscountInfo;
   import alternativa.tanks.model.item.discount.ICollectDiscount;
   import alternativa.tanks.model.item.discount.IDiscount;
   import alternativa.tanks.model.item.discount.IDiscountCollector;
   import alternativa.tanks.service.item.ItemService;
   import projects.tanks.client.commons.types.ItemCategoryEnum;
   import projects.tanks.client.garage.models.item.kit.GarageKitModelBase;
   import projects.tanks.client.garage.models.item.kit.IGarageKitModelBase;
   import projects.tanks.client.garage.models.item.kit.KitItem;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.userproperties.IUserPropertiesService;
   import platform.client.fp10.core.resource.types.ImageResource;
   import projects.tanks.client.garage.models.item.kit.GarageKitCC;
   import flash.utils.Dictionary;
   import utils.TankTraceUtil;
   
   [ModelInfo]
   public class GarageKitModel extends GarageKitModelBase implements IGarageKitModelBase, GarageKit, ICollectDiscount
   {

      private var diagnosticLogged:Dictionary = new Dictionary(true);
      
      [Inject] // added
      public static var itemService:ItemService;
      
      [Inject] // added
      public static var userPropertyService:IUserPropertiesService;
      
      public function GarageKitModel()
      {
         super();
      }
      
      public function getImage() : ImageResource
      {
         return getInitParam().image;
      }
      
      public function getPrice() : int
      {
         var _loc1_:int = this.getPriceWithoutDiscount();
         var _loc2_:IDiscount = IDiscount(object.adapt(IDiscount));
         return _loc2_.applyDiscount(_loc1_);
      }
      
      public function getPriceWithoutDiscount() : int
      {
         var _loc2_:KitItem = null;
         var _loc1_:int = 0;
         for each(_loc2_ in this.getItems())
         {
            _loc1_ += itemService.getPriceWithoutDiscount(_loc2_.item) * _loc2_.count;
         }
         return _loc1_;
      }
      
      public function getPriceAlreadyBought() : int
      {
         var _loc2_:KitItem = null;
         var _loc1_:int = 0;
         for each(_loc2_ in this.getItems())
         {
            if(Boolean(itemService.hasItem(_loc2_.item)) && !itemService.isCountable(_loc2_.item) && itemService.getCategory(_loc2_.item) != ItemCategoryEnum.PLUGIN)
            {
               _loc1_ += itemService.getPrice(_loc2_.item) * _loc2_.count;
            }
         }
         return _loc1_;
      }
      
      public function getPriceYouSave() : int
      {
         return this.getPriceWithoutDiscount() - this.getPrice() - this.getPriceAlreadyBought();
      }
      
      public function canBuy() : Boolean
      {
         var _loc1_:KitItem = null;
         for each(_loc1_ in this.getItems())
         {
            if(!itemService.hasItem(_loc1_.item) && itemService.getMinRankIndex(_loc1_.item) > userPropertyService.rank)
            {
               this.logCanBuy("component_rank",true,_loc1_.item,0);
               return true;
            }
         }
         var _loc2_:int = this.getPriceYouSave();
         var _loc3_:Boolean = _loc2_ > 0;
         this.logCanBuy("savings",_loc3_,null,_loc2_);
         return _loc3_;
      }

      private function logCanBuy(param1:String, param2:Boolean, param3:Object, param4:int) : void
      {
         if(this.diagnosticLogged[object])
         {
            return;
         }
         this.diagnosticLogged[object] = true;
         TankTraceUtil.logGarageQa("KIT_CAN_BUY_DECISION","objectName=" + object.name + " reason=" + param1 + " result=" + (param2 ? 1 : 0) + " component=" + (param3 == null ? "null" : param3.name) + " savings=" + param4 + " components=" + (this.getItems() == null ? 0 : this.getItems().length));
      }
      
      public function getItems() : Vector.<KitItem>
      {
         return getInitParam().kitItems;
      }
      
      public function collectDiscountsInfo(param1:IDiscountCollector) : void
      {
         var initParams:GarageKitCC = getInitParam();
         if(initParams == null)
         {
            return;
         }
         param1.addDiscount(new DiscountInfo(initParams.discountInPercent,0));
      }
   }
}
