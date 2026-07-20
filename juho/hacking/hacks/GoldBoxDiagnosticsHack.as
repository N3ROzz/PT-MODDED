package juho.hacking.hacks
{
   import juho.hacking.Hack;
   import utils.goldbox.GoldBoxDiagnostics;

   public class GoldBoxDiagnosticsHack extends Hack
   {
      private static const FILE_LOG:String = "Full file log";
      private static const OVERLAY:String = "In-game overlay";
      private static const TRACE_GOLD:String = "Trace Gold variants";
      private static const TRACE_NORMAL_CRYSTAL:String = "Trace normal crystal";
      private static const TRACE_CRYSTAL_100:String = "Trace crystal_100 variant";
      private static const SHADOW_RADIUS_PROBE:String = "Shadow radius probe";
      private static const AIRBORNE_SHADOW_COLLECT:String = "Airborne shadow collect";
      private static const PROXIMITY_COLLECT:String = "Proximity collect - normal crystal";
      private static const PROXIMITY_DISTANCE:String = "Proximity collect distance";
      private static const PROXIMITY_MAX_HORIZONTAL:String = "Proximity collect max horizontal";
      private static const PROXIMITY_RETRY_INTERVAL:String = "Proximity collect retry interval";
      private static const PROXIMITY_MAX_ATTEMPTS:String = "Proximity collect max attempts per bonus";
      private static const SETTINGS_VERSION_KEY:String = "goldDiagnosticsSettingsVersion";

      public function GoldBoxDiagnosticsHack()
      {
         super("Gold Box Diagnostics","GOLD_BOX_DIAGNOSTICS");
         this.addProperty(FILE_LOG,false,"Boolean",this.outputChanged);
         this.addProperty(OVERLAY,false,"Boolean",this.outputChanged);
         this.addProperty(TRACE_GOLD,true,"Boolean",this.targetsChanged);
         this.addProperty(TRACE_NORMAL_CRYSTAL,false,"Boolean",this.targetsChanged);
         this.addProperty(TRACE_CRYSTAL_100,false,"Boolean",this.targetsChanged);
         this.addProperty(SHADOW_RADIUS_PROBE,false,"Boolean",this.shadowProbeChanged);
         this.addProperty(AIRBORNE_SHADOW_COLLECT,false,"Boolean",this.airborneProbeChanged);
         this.addProperty(PROXIMITY_COLLECT,false,"Boolean",this.proximityChanged);
         this.addChoiceProperty(PROXIMITY_DISTANCE,400,this.proximityDistanceChoices,this.proximityChanged);
         this.addChoiceProperty(PROXIMITY_MAX_HORIZONTAL,400,this.proximityDistanceChoices,this.proximityChanged);
         this.addSliderProperty(PROXIMITY_RETRY_INTERVAL,100,50,1000,50,this.proximityChanged);
         this.addSliderProperty(PROXIMITY_MAX_ATTEMPTS,30,1,100,1,this.proximityChanged);
         this.migratePropertyValueOnce(SETTINGS_VERSION_KEY,1,FILE_LOG,false);
         this.applyState();
      }

      override public function enable() : void
      {
         super.enable();
         this.applyState();
      }

      override public function disable() : void
      {
         super.disable();
         this.applyState();
      }

      private function outputChanged(param1:*) : void
      {
         this.applyState();
      }

      private function targetsChanged(param1:*) : void
      {
         this.applyTargets();
      }

      private function shadowProbeChanged(param1:*) : void
      {
         GoldBoxDiagnostics.setShadowRadiusProbe(Boolean(param1));
      }

      private function airborneProbeChanged(param1:*) : void
      {
         GoldBoxDiagnostics.setAirborneShadowCollect(Boolean(param1));
      }

      private function proximityChanged(param1:*) : void
      {
         this.applyProximity();
      }

      private function proximityDistanceChoices() : Array
      {
         return [{id:200,gameName:"200"},{id:250,gameName:"250"},{id:300,gameName:"300"},{id:350,gameName:"350"},{id:400,gameName:"400"},{id:450,gameName:"450"},{id:500,gameName:"500"}];
      }

      private function applyState() : void
      {
         this.applyTargets();
         GoldBoxDiagnostics.setShadowRadiusProbe(Boolean(this.getProperty(SHADOW_RADIUS_PROBE).value));
         GoldBoxDiagnostics.setAirborneShadowCollect(Boolean(this.getProperty(AIRBORNE_SHADOW_COLLECT).value));
         this.applyProximity();
         GoldBoxDiagnostics.setEnabled(this.isEnabled,Boolean(this.getProperty(FILE_LOG).value),Boolean(this.getProperty(OVERLAY).value));
         GoldBoxDiagnostics.setOutputModes(Boolean(this.getProperty(FILE_LOG).value),Boolean(this.getProperty(OVERLAY).value));
      }

      private function applyTargets() : void
      {
         GoldBoxDiagnostics.setTargets(Boolean(this.getProperty(TRACE_GOLD).value),Boolean(this.getProperty(TRACE_NORMAL_CRYSTAL).value),Boolean(this.getProperty(TRACE_CRYSTAL_100).value));
      }

      private function applyProximity() : void
      {
         GoldBoxDiagnostics.setProximityCollect(Boolean(this.getProperty(PROXIMITY_COLLECT).value),Number(this.getProperty(PROXIMITY_DISTANCE).value),Number(this.getProperty(PROXIMITY_MAX_HORIZONTAL).value),int(this.getProperty(PROXIMITY_RETRY_INTERVAL).value),int(this.getProperty(PROXIMITY_MAX_ATTEMPTS).value));
      }
   }
}
