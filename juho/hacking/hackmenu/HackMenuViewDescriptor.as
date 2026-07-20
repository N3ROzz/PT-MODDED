package juho.hacking.hackmenu
{
   import juho.hacking.Hack;

   public class HackMenuViewDescriptor
   {
      public static const STANDARD_HACK:String = "standardHack";
      public static const CRYSTAL_COLLECTOR:String = "crystalCollector";
      public static const DIAGNOSTICS_ENGINE:String = "diagnosticsEngine";
      public static const NONE:String = "none";

      public static const STANDARD_PRESENTATION:String = "standard";
      public static const CRYSTAL_COLLECTOR_PRESENTATION:String = "crystalCollector";

      public var viewId:String;
      public var hack:Hack;
      public var title:String;
      public var category:String;
      public var description:String;
      public var order:int;
      public var propertyNames:Array;
      public var excludedPropertyNames:Array;
      public var masterMode:String;
      public var masterLabel:String;
      public var presentationType:String;

      public function HackMenuViewDescriptor(param1:String, param2:Hack, param3:String, param4:String, param5:String, param6:int, param7:Array = null, param8:String = "standardHack", param9:String = "Enabled", param10:String = "standard", param11:Array = null)
      {
         this.viewId = param1;
         this.hack = param2;
         this.title = param3;
         this.category = param4;
         this.description = param5;
         this.order = param6;
         this.propertyNames = param7;
         this.masterMode = param8;
         this.masterLabel = param9;
         this.presentationType = param10;
         this.excludedPropertyNames = param11;
      }

      public function includesProperty(param1:String) : Boolean
      {
         if(this.propertyNames != null && this.propertyNames.indexOf(param1) < 0)
         {
            return false;
         }
         return this.excludedPropertyNames == null || this.excludedPropertyNames.indexOf(param1) < 0;
      }
   }
}
