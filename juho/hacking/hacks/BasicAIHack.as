package juho.hacking.hacks
{
   import juho.hacking.Hack;
   import juho.hacking.event.HackEventDispatcher;
   import juho.hacking.event.LocalTankInitedEvent;
   import juho.hacking.event.LocalTankUnloadedEvent;
   import flash.utils.getDefinitionByName;
   
   public class BasicAIHack extends Hack
   {
      
      private static const NAME:String = "AI Control / Basic AI";
      
      private static const ID:String = "BASIC_AI";
      
      private var controller:Object;
      
      public function BasicAIHack()
      {
         super(NAME,ID);
         HackEventDispatcher.singleton.addEventListener(LocalTankInitedEvent.LOCAL_TANK_INITED,this.localTankInited);
         HackEventDispatcher.singleton.addEventListener(LocalTankUnloadedEvent.LOCAL_TANK_UNLOADED_EVENT,this.localTankUnloaded);
         if(this.isEnabled)
         {
            super.disable();
         }
      }
      
      override public function enable() : void
      {
         super.enable();
         try
         {
            this.ensureController();
            this.controller.setEnabled(true);
         }
         catch(error:Error)
         {
            if(this.controller != null)
            {
               this.controller.setEnabled(false);
            }
            super.disable();
         }
      }
      
      override public function disable() : void
      {
         super.disable();
         if(this.controller != null)
         {
            this.controller.setEnabled(false);
         }
      }
      
      private function localTankInited(event:LocalTankInitedEvent) : void
      {
         if(this.isEnabled)
         {
            this.ensureController();
            this.controller.setLocalTank(event.localTank);
         }
      }
      
      private function localTankUnloaded(event:LocalTankUnloadedEvent) : void
      {
         if(this.controller != null)
         {
            this.controller.clearLocalTank();
         }
      }
      
      private function ensureController() : void
      {
         var controllerClass:Class = null;
         if(this.controller == null)
         {
            controllerClass = Class(getDefinitionByName("juho.hacking.ai.BasicAIController"));
            this.controller = new controllerClass();
            this.controller.startTracking();
         }
      }
   }
}
