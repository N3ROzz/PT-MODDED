package juho.hacking.hackmenu
{
   import controls.Label;
   import flash.display.Shape;
   import flash.display.Sprite;

   public class HackMenuList extends Sprite
   {
      private var background:Shape;
      private var viewport:HackMenuScrollViewport;
      private var buttons:Vector.<HackMenuSidebarButton>;
      private var selectCallback:Function;
      private var selectedViewId:String;
      private var listWidth:Number = HackMenuTheme.SIDEBAR_WIDTH;
      private var listHeight:Number = 0;

      public function HackMenuList(param1:Function)
      {
         super();
         this.background = new Shape();
         this.viewport = new HackMenuScrollViewport();
         this.buttons = new Vector.<HackMenuSidebarButton>();
         this.selectCallback = param1;
         addChild(this.background);
         addChild(this.viewport);
      }

      public function setDescriptors(param1:Vector.<HackMenuViewDescriptor>, param2:String) : String
      {
         var _loc3_:Array = [];
         var _loc4_:HackMenuViewDescriptor = null;
         this.clearItems();
         for each(_loc4_ in param1)
         {
            _loc3_.push(_loc4_);
         }
         _loc3_.sort(this.sortDescriptors);
         this.selectedViewId = this.containsId(_loc3_,param2) ? param2 : (_loc3_.length == 0 ? null : HackMenuViewDescriptor(_loc3_[0]).viewId);
         this.buildCategory(_loc3_,HackMenuCatalog.COMBAT);
         this.buildCategory(_loc3_,HackMenuCatalog.VISUALS);
         this.buildCategory(_loc3_,HackMenuCatalog.UTILITY);
         this.buildCategory(_loc3_,HackMenuCatalog.DEBUGS);
         this.layoutItems();
         return this.selectedViewId;
      }

      public function setSize(param1:Number, param2:Number) : void
      {
         this.listWidth = param1;
         this.listHeight = param2;
         this.background.graphics.clear();
         this.background.graphics.beginFill(HackMenuTheme.SIDEBAR_BG);
         this.background.graphics.drawRect(0,0,param1,param2);
         this.background.graphics.endFill();
         this.viewport.setSize(param1,param2);
         this.layoutItems();
      }

      public function selectById(param1:String, param2:Boolean = false) : void
      {
         var _loc3_:HackMenuSidebarButton = null;
         this.selectedViewId = param1;
         for each(_loc3_ in this.buttons)
         {
            _loc3_.selected = _loc3_.descriptor.viewId == param1;
         }
         if(param2 && this.selectCallback != null)
         {
            this.selectCallback(param1);
         }
      }

      public function dispose() : void
      {
         this.clearItems();
         this.viewport.dispose();
         this.selectCallback = null;
      }

      private function buildCategory(param1:Array, param2:String) : void
      {
         var _loc3_:Label = null;
         var _loc4_:HackMenuViewDescriptor = null;
         var _loc5_:HackMenuSidebarButton = null;
         var _loc6_:Boolean = false;
         for each(_loc4_ in param1)
         {
            if(_loc4_.category == param2)
            {
               _loc6_ = true;
               break;
            }
         }
         if(!_loc6_)
         {
            return;
         }
         _loc3_ = new Label();
         _loc3_.name = "category";
         _loc3_.text = param2;
         _loc3_.size = 11;
         _loc3_.bold = true;
         _loc3_.color = HackMenuTheme.MUTED;
         this.viewport.content.addChild(_loc3_);
         for each(_loc4_ in param1)
         {
            if(_loc4_.category == param2)
            {
               _loc5_ = new HackMenuSidebarButton(_loc4_,this.onButtonSelected);
               _loc5_.setSize(120,34);
               _loc5_.x = 10;
               _loc5_.y = 0;
               this.buttons.push(_loc5_);
               this.viewport.content.addChild(_loc5_);
               _loc5_.selected = _loc4_.viewId == this.selectedViewId;
            }
         }
      }

      private function layoutItems() : void
      {
         var _loc1_:int = 16;
         var _loc2_:int = 0;
         var _loc3_:Object = null;
         for(_loc2_ = 0; _loc2_ < this.viewport.content.numChildren; _loc2_++)
         {
            _loc3_ = this.viewport.content.getChildAt(_loc2_);
            if(_loc3_ is Label)
            {
               if(_loc1_ > 16)
               {
                  _loc1_ += 13;
               }
               _loc3_.x = 16;
               _loc3_.y = _loc1_;
               _loc1_ += 22;
            }
            else if(_loc3_ is HackMenuSidebarButton)
            {
               HackMenuSidebarButton(_loc3_).setSize(Math.max(120,this.listWidth - 24),34);
               _loc3_.x = 10;
               _loc3_.y = _loc1_;
               _loc1_ += 36;
            }
         }
         this.viewport.setContentHeight(_loc1_ + 10);
      }

      private function onButtonSelected(param1:String) : void
      {
         this.selectById(param1);
         if(this.selectCallback != null)
         {
            this.selectCallback(param1);
         }
      }

      private function clearItems() : void
      {
         var _loc1_:HackMenuSidebarButton = null;
         for each(_loc1_ in this.buttons)
         {
            _loc1_.dispose();
         }
         this.buttons.length = 0;
         while(this.viewport.content.numChildren > 0)
         {
            this.viewport.content.removeChildAt(0);
         }
         this.viewport.setContentHeight(0);
      }

      private function containsId(param1:Array, param2:String) : Boolean
      {
         var _loc3_:HackMenuViewDescriptor = null;
         for each(_loc3_ in param1)
         {
            if(_loc3_.viewId == param2)
            {
               return true;
            }
         }
         return false;
      }

      private function sortDescriptors(param1:HackMenuViewDescriptor, param2:HackMenuViewDescriptor) : Number
      {
         var _loc3_:int = this.categoryOrder(param1.category) - this.categoryOrder(param2.category);
         return _loc3_ == 0 ? param1.order - param2.order : _loc3_;
      }

      private function categoryOrder(param1:String) : int
      {
         if(param1 == HackMenuCatalog.COMBAT) return 0;
         if(param1 == HackMenuCatalog.VISUALS) return 1;
         if(param1 == HackMenuCatalog.UTILITY) return 2;
         return 3;
      }
   }
}
