package juho.hacking.hacks
{
   import alternativa.osgi.OSGi;
   import alternativa.tanks.battle.objects.tank.Tank;
   import alternativa.types.Long;
   import flash.events.Event;
   import juho.hacking.Hack;
   import juho.hacking.PaintRegistry;
   import juho.hacking.event.HackEventDispatcher;
   import juho.hacking.event.LocalTankInitedEvent;
   import juho.hacking.event.LocalTankUnloadedEvent;
   import juho.hacking.event.TankNormalStateSettedEvent;
   import platform.client.fp10.core.registry.ResourceRegistry;
   import platform.client.fp10.core.resource.types.ImageResource;
   import platform.client.fp10.core.resource.types.MultiframeImageResource;
   
   public class PaintVisualHack extends Hack
   {
      private static const NAME:String = "Paint Visual";
      
      private static const ID:String = "PAINT_VISUAL";
      
      private static const PROP_PAINT:String = "Special paint";
      
      private var localTank:Tank;
      
      public function PaintVisualHack()
      {
         super(NAME,ID);
         this.addChoiceProperty(PROP_PAINT,"Acid",PaintRegistry.getSpecialPaintChoices,this.paintChoiceChanged);
         PaintRegistry.setSelectedPaint(String(this.getProperty(PROP_PAINT).value));
         PaintRegistry.addEventListener(PaintRegistry.SELECTED_PAINT_CHANGED,this.paintChanged);
         HackEventDispatcher.singleton.addEventListener(LocalTankInitedEvent.LOCAL_TANK_INITED,this.localTankInited);
         HackEventDispatcher.singleton.addEventListener(LocalTankUnloadedEvent.LOCAL_TANK_UNLOADED_EVENT,this.localTankDestroyed);
         HackEventDispatcher.singleton.addEventListener(TankNormalStateSettedEvent.TANK_NORMAL_STATE_SETTED_EVENT,this.tankNormalStateSetted);
      }
      
      override public function enable() : void
      {
         super.enable();
         this.applyPaint();
      }
      
      override public function disable() : void
      {
         super.disable();
         if(this.localTank != null)
         {
            this.localTank.getSkin().setVisualColoring(null);
         }
      }
      
      private function paintChanged(param1:Event) : void
      {
         this.applyPaint();
      }
      
      private function paintChoiceChanged(param1:*) : void
      {
         PaintRegistry.setSelectedPaint(String(param1));
         this.applyPaint();
      }
      
      private function localTankInited(param1:LocalTankInitedEvent) : void
      {
         this.localTank = param1.localTank;
         this.applyPaint();
      }
      
      private function localTankDestroyed(param1:LocalTankUnloadedEvent) : void
      {
         this.localTank = null;
      }
      
      private function tankNormalStateSetted(param1:TankNormalStateSettedEvent) : void
      {
         if(param1.tank == this.localTank)
         {
            this.applyPaint();
         }
      }
      
      private function applyPaint() : void
      {
         var _loc1_:int = 0;
         var _loc2_:ResourceRegistry = null;
         var _loc3_:Object = null;
         var _loc4_:String = null;
         
         if(this.localTank == null || !this.isEnabled)
         {
            return;
         }
         
         _loc1_ = PaintRegistry.getSelectedColoringId();
         _loc4_ = PaintRegistry.getSelectedPaintName();
         
         // Try to get resource from registry first
         if(_loc1_ > 0)
         {
            _loc2_ = ResourceRegistry(OSGi.getInstance().getService(ResourceRegistry));
            if(_loc2_ != null)
            {
               _loc3_ = _loc2_.getResource(Long.getLong(0,_loc1_));
               if(_loc3_ is ImageResource || _loc3_ is MultiframeImageResource)
               {
                  this.localTank.getSkin().setVisualColoring(_loc3_);
                  return;
               }
            }
         }
         
         // For special paints without resource, use paint name as identifier
         // This creates a custom coloring that can be detected by PaintColoring wrapper
         if(_loc4_ != null && _loc4_ != "")
         {
            var paintObj:Object = {
               "paintName": _loc4_,
               "isSpecialPaint": PaintRegistry.isSpecialPaintName(_loc4_)
            };
            this.localTank.getSkin().setVisualColoring(paintObj);
         }
      }
   }
}
