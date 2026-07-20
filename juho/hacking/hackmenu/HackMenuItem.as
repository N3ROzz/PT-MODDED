package juho.hacking.hackmenu
{
   import controls.Label;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.geom.Vector3D;
   import juho.hacking.Hack;
   import juho.hacking.HackProperty;

   public class HackMenuItem extends Sprite
   {
      private static const GOLD_ID:String = "GOLD_BOX_DIAGNOSTICS";
      private static const PROXIMITY_ENABLED:String = "Proximity collect - normal crystal";
      private static const PROXIMITY_DISTANCE:String = "Proximity collect distance";
      private static const PROXIMITY_HORIZONTAL:String = "Proximity collect max horizontal";
      private static const PROXIMITY_RETRY:String = "Proximity collect retry interval";
      private static const PROXIMITY_ATTEMPTS:String = "Proximity collect max attempts per bonus";

      private var hack:Hack;
      private var descriptor:HackMenuViewDescriptor;
      private var background:Shape;
      private var divider:Shape;
      private var title:Label;
      private var description:Label;
      private var masterText:Label;
      private var masterToggle:HackMenuToggle;
      private var viewport:HackMenuScrollViewport;
      private var popupHost:Sprite;
      private var disposableControls:Array = [];
      private var panelWidth:Number = 0;
      private var panelHeight:Number = 0;
      private var rowY:Number = 0;

      public function HackMenuItem(param1:HackMenuViewDescriptor, param2:Sprite)
      {
         super();
         this.descriptor = param1;
         this.hack = param1.hack;
         this.popupHost = param2;
         this.background = new Shape();
         this.divider = new Shape();
         this.title = new Label();
         this.description = new Label();
         this.masterText = new Label();
         this.viewport = new HackMenuScrollViewport();
         addChild(this.background);
         addChild(this.title);
         addChild(this.description);
         addChild(this.masterText);
         addChild(this.divider);
         addChild(this.viewport);

         this.title.text = this.descriptor.title;
         this.title.size = 22;
         this.title.bold = true;
         this.title.color = HackMenuTheme.TEXT;
         this.description.text = this.descriptor.description;
         this.description.size = 12;
         this.description.color = HackMenuTheme.MUTED;
         this.masterText.text = this.descriptor.masterLabel;
         this.masterText.size = 12;
         this.masterText.color = HackMenuTheme.MUTED;
         if(this.descriptor.masterMode != HackMenuViewDescriptor.NONE)
         {
            this.masterToggle = new HackMenuToggle(this.masterEnabled(),this.onMasterChanged);
            addChild(this.masterToggle);
            this.disposableControls.push(this.masterToggle);
         }
         this.buildProperties();
      }

      public function setSize(param1:Number, param2:Number) : void
      {
         this.panelWidth = param1;
         this.panelHeight = param2;
         this.background.graphics.clear();
         this.background.graphics.beginFill(HackMenuTheme.CONTENT_BG);
         this.background.graphics.drawRect(0,0,param1,param2);
         this.background.graphics.endFill();
         this.title.x = 24;
         this.title.y = 20;
         this.description.x = 24;
         this.description.y = 52;
         this.description.width = Math.max(100,param1 - 190);
         if(this.masterToggle != null)
         {
            this.masterToggle.x = param1 - 66;
            this.masterToggle.y = 27;
            this.masterText.x = this.masterToggle.x - this.masterText.width - 10;
            this.masterText.y = 31;
            this.masterText.visible = true;
         }
         else
         {
            this.masterText.visible = false;
         }
         this.divider.graphics.clear();
         this.divider.graphics.beginFill(HackMenuTheme.DIVIDER);
         this.divider.graphics.drawRect(24,82,param1 - 48,1);
         this.divider.graphics.endFill();
         this.viewport.x = 24;
         this.viewport.y = 96;
         this.viewport.setSize(param1 - 48,Math.max(40,param2 - 112));
         this.layoutPropertyControls();
      }

      public function dispose() : void
      {
         var _loc1_:Object = null;
         for each(_loc1_ in this.disposableControls)
         {
            _loc1_.dispose();
         }
         this.disposableControls.length = 0;
         this.viewport.dispose();
         this.popupHost = null;
      }

      private function buildProperties() : void
      {
         var _loc1_:HackProperty = null;
         this.rowY = 0;
         if(this.isNormalCrystalCollector())
         {
            this.addSliderRow("Collection radius",Number(this.hack.getProperty(PROXIMITY_DISTANCE).value),200,500,50,this.onCrystalRadiusChanged,"units");
         }
         else
         {
            for each(_loc1_ in this.hack.allHackProperties)
            {
               if(this.descriptor.includesProperty(_loc1_.name))
               {
                  this.addPropertyRow(_loc1_);
               }
            }
         }
         if(this.rowY == 0)
         {
            this.addEmptyState();
         }
         this.viewport.setContentHeight(this.rowY);
      }

      private function addPropertyRow(param1:HackProperty) : void
      {
         var _loc2_:String = param1.name;
         var _loc3_:String = HackMenuCatalog.propertyLabel(this.descriptor,_loc2_);
         switch(param1.type)
         {
            case "Boolean":
               this.addBooleanRow(_loc3_,Boolean(param1.value),function(param2:Boolean):void
               {
                  hack.setPropertyValue(_loc2_,param2);
               });
               break;
            case "Number":
               this.addNumberRow(_loc3_,Number(param1.value),function(param2:Number):void
               {
                  hack.setPropertyValue(_loc2_,param2);
               });
               break;
            case "Slider":
               this.addSliderRow(_loc3_,Number(param1.value),param1.minValue,param1.maxValue,param1.step,function(param2:Number):void
               {
                  hack.setPropertyValue(_loc2_,param2);
               },"");
               break;
            case "Choice":
               this.addChoiceRow(_loc3_,param1.value,param1.choicesProvider == null ? [] : param1.choicesProvider(),function(param2:*):void
               {
                  hack.setPropertyValue(_loc2_,param2);
               });
               break;
            case "Vector3D":
               this.addVectorRow(_loc3_,Vector3D(param1.value),function(param2:Vector3D):void
               {
                  hack.setPropertyValue(_loc2_,param2);
               });
         }
      }

      private function addBooleanRow(param1:String, param2:Boolean, param3:Function) : void
      {
         var _loc4_:Sprite = this.createRow(param1,46);
         var _loc5_:HackMenuToggle = new HackMenuToggle(param2,param3);
         _loc5_.name = "rightControl";
         _loc4_.addChild(_loc5_);
         this.disposableControls.push(_loc5_);
      }

      private function addNumberRow(param1:String, param2:Number, param3:Function) : void
      {
         var _loc4_:Sprite = this.createRow(param1,48);
         var _loc5_:HackMenuNumberField = new HackMenuNumberField(param2,param3);
         _loc5_.name = "rightControl";
         _loc4_.addChild(_loc5_);
         this.disposableControls.push(_loc5_);
      }

      private function addSliderRow(param1:String, param2:Number, param3:Number, param4:Number, param5:Number, param6:Function, param7:String) : void
      {
         var _loc8_:Sprite = this.createRow(param1,54);
         var _loc9_:HackMenuSliderControl = new HackMenuSliderControl(param2,param3,param4,param5,param6,param7);
         _loc9_.name = "wideControl";
         _loc8_.addChild(_loc9_);
         this.disposableControls.push(_loc9_);
      }

      private function addChoiceRow(param1:String, param2:*, param3:Array, param4:Function) : void
      {
         var _loc5_:Sprite = this.createRow(param1,48);
         var _loc6_:HackMenuChoiceControl = new HackMenuChoiceControl(param2,param3,param4,this.popupHost);
         _loc6_.name = "rightControl";
         _loc5_.addChild(_loc6_);
         this.disposableControls.push(_loc6_);
      }

      private function addVectorRow(param1:String, param2:Vector3D, param3:Function) : void
      {
         var _loc4_:Sprite = this.createRow(param1,54);
         var _loc5_:HackMenuVectorControl = new HackMenuVectorControl(param2,param3);
         _loc5_.name = "wideControl";
         _loc4_.addChild(_loc5_);
         this.disposableControls.push(_loc5_);
      }

      private function createRow(param1:String, param2:Number) : Sprite
      {
         var _loc3_:Sprite = new Sprite();
         var _loc4_:Shape = new Shape();
         var _loc5_:Label = new Label();
         _loc3_.name = "propertyRow";
         _loc3_.y = this.rowY;
         _loc3_.graphics.beginFill(0,0);
         _loc3_.graphics.drawRect(0,0,1,param2);
         _loc3_.graphics.endFill();
         _loc4_.name = "rowDivider";
         _loc3_.addChild(_loc4_);
         _loc5_.text = param1;
         _loc5_.size = 13;
         _loc5_.color = HackMenuTheme.TEXT;
         _loc5_.x = 4;
         _loc5_.y = Math.round((param2 - _loc5_.height) / 2);
         _loc3_.addChild(_loc5_);
         this.viewport.content.addChild(_loc3_);
         this.rowY += param2;
         return _loc3_;
      }

      private function addEmptyState() : void
      {
         var _loc1_:Label = new Label();
         _loc1_.text = "No additional settings for this module.";
         _loc1_.size = 13;
         _loc1_.color = HackMenuTheme.MUTED;
         _loc1_.x = 4;
         _loc1_.y = 12;
         this.viewport.content.addChild(_loc1_);
         this.rowY = 42;
      }

      private function layoutPropertyControls() : void
      {
         var _loc1_:int;
         var _loc2_:Sprite;
         var _loc3_:int;
         var _loc4_:Object;
         var _loc5_:Shape;
         var _loc6_:Number = this.viewport.viewWidth;
         for(_loc1_ = 0; _loc1_ < this.viewport.content.numChildren; _loc1_++)
         {
            _loc2_ = this.viewport.content.getChildAt(_loc1_) as Sprite;
            if(_loc2_ == null || _loc2_.name != "propertyRow") continue;
            for(_loc3_ = 0; _loc3_ < _loc2_.numChildren; _loc3_++)
            {
               _loc4_ = _loc2_.getChildAt(_loc3_);
               if(_loc4_.name == "rightControl")
               {
                  _loc4_.x = _loc6_ - _loc4_.width - 10;
                  _loc4_.y = Math.round((_loc2_.height - _loc4_.height) / 2);
               }
               else if(_loc4_.name == "wideControl")
               {
                  _loc4_.x = Math.max(180,_loc6_ - _loc4_.width - 10);
                  _loc4_.y = Math.round((_loc2_.height - _loc4_.height) / 2);
               }
               else if(_loc4_.name == "rowDivider")
               {
                  _loc5_ = _loc4_ as Shape;
                  _loc5_.graphics.clear();
                  _loc5_.graphics.beginFill(HackMenuTheme.DIVIDER);
                  _loc5_.graphics.drawRect(0,_loc2_.height - 1,_loc6_,1);
                  _loc5_.graphics.endFill();
               }
            }
         }
      }

      private function masterEnabled() : Boolean
      {
         return this.descriptor.masterMode == HackMenuViewDescriptor.CRYSTAL_COLLECTOR ? this.hack.isEnabled && Boolean(this.hack.getProperty(PROXIMITY_ENABLED).value) : this.hack.isEnabled;
      }

      private function onMasterChanged(param1:Boolean) : void
      {
         if(this.descriptor.masterMode == HackMenuViewDescriptor.CRYSTAL_COLLECTOR)
         {
            this.applyCrystalMaster(param1);
         }
         else if(param1)
         {
            this.hack.enable();
         }
         else
         {
            this.hack.disable();
         }
      }

      private function applyCrystalMaster(param1:Boolean) : void
      {
         var _loc2_:Number = Number(this.hack.getProperty(PROXIMITY_DISTANCE).value);
         if(param1)
         {
            this.hack.setPropertyValue(PROXIMITY_DISTANCE,_loc2_);
            this.hack.setPropertyValue(PROXIMITY_HORIZONTAL,_loc2_);
            this.hack.setPropertyValue(PROXIMITY_RETRY,100);
            this.hack.setPropertyValue(PROXIMITY_ATTEMPTS,30);
            this.hack.setPropertyValue(PROXIMITY_ENABLED,true);
            this.hack.enable();
         }
         else
         {
            this.hack.setPropertyValue(PROXIMITY_ENABLED,false);
            this.hack.disable();
         }
      }

      private function onCrystalRadiusChanged(param1:Number) : void
      {
         this.hack.setPropertyValue(PROXIMITY_DISTANCE,param1);
         this.hack.setPropertyValue(PROXIMITY_HORIZONTAL,param1);
      }

      private function isNormalCrystalCollector() : Boolean
      {
         return this.descriptor.presentationType == HackMenuViewDescriptor.CRYSTAL_COLLECTOR_PRESENTATION;
      }
   }
}
