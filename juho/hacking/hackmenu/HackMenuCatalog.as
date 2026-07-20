package juho.hacking.hackmenu
{
   import juho.hacking.Hack;

   public class HackMenuCatalog
   {
      public static const COMBAT:String = "COMBAT";
      public static const VISUALS:String = "VISUALS";
      public static const UTILITY:String = "UTILITY";
      public static const DEBUGS:String = "DEBUGS";

      public static function descriptors(param1:Vector.<Hack>) : Vector.<HackMenuViewDescriptor>
      {
         var _loc2_:Vector.<HackMenuViewDescriptor> = new Vector.<HackMenuViewDescriptor>();
         var _loc3_:Hack = null;
         for each(_loc3_ in param1)
         {
            appendHackViews(_loc2_,_loc3_);
         }
         return _loc2_;
      }

      public static function propertyLabel(param1:HackMenuViewDescriptor, param2:String) : String
      {
         if(param1.viewId == "AIM" || param1.viewId == "AIM:TARGETING_DEBUG")
         {
            switch(param2)
            {
               case "Sideways aim enabled": return "Sideways aim";
               case "   Max left angleÂ°": return "Max left angle (deg)";
               case "   Max right angleÂ°": return "Max right angle (deg)";
               case "Max up angleÂ°": return "Max up angle (deg)";
               case "Max down angleÂ°": return "Max down angle (deg)";
               case "Debug enabled": return "Targeting debug";
            }
         }
         if(param1.hack.id == "SPEED_HACK")
         {
            switch(param2)
            {
               case "Speed (be careful to not get banned)": return "Top speed";
               case "Accelaration": return "Acceleration";
               case "Turn accelaration": return "Turn acceleration";
               case "Turret accelaration": return "Turret acceleration";
            }
         }
         return param2;
      }

      private static function appendHackViews(param1:Vector.<HackMenuViewDescriptor>, param2:Hack) : void
      {
         switch(param2.id)
         {
            case "AIM":
               param1.push(view("AIM",param2,"Aim Assist",COMBAT,"Expanded targeting angles for supported weapons.",10,null,HackMenuViewDescriptor.STANDARD_HACK,"Enabled",HackMenuViewDescriptor.STANDARD_PRESENTATION,["Debug enabled"]));
               param1.push(view("AIM:TARGETING_DEBUG",param2,"Targeting Debug",DEBUGS,"Targeting visualization diagnostics.",10,["Debug enabled"],HackMenuViewDescriptor.NONE,"",HackMenuViewDescriptor.STANDARD_PRESENTATION));
               return;
            case "SPEED_HACK":
               param1.push(view(param2.id,param2,"Movement",COMBAT,"Tank movement and turret response settings.",20));
               return;
            case "TANK_IGNORE":
               param1.push(view(param2.id,param2,"Tank Ignore",COMBAT,"Local tank collision filtering.",30));
               return;
            case "BASIC_AI":
               param1.push(view(param2.id,param2,"AI Control",COMBAT,"Basic automatic tank controller.",40));
               return;
            case "WALL_HACK":
               param1.push(view(param2.id,param2,"Player Markers",VISUALS,"Player marker visibility through map geometry.",10));
               return;
            case "SHAFT_FOV":
               param1.push(view(param2.id,param2,"Shaft Visuals",VISUALS,"Shaft aiming field of view and visual options.",20));
               return;
            case "GOLD_BOX_DIAGNOSTICS":
               param1.push(view("GOLD_BOX_DIAGNOSTICS:COLLECTOR",param2,"Crystal Collector",UTILITY,"Controlled normal-crystal proximity collection.",10,[],HackMenuViewDescriptor.CRYSTAL_COLLECTOR,"Master Enable",HackMenuViewDescriptor.CRYSTAL_COLLECTOR_PRESENTATION));
               param1.push(view("GOLD_BOX_DIAGNOSTICS:GOLD_DEBUG",param2,"Gold Lifecycle Debug",DEBUGS,"Gold and crystal lifecycle output and target selection.",20,["Full file log","In-game overlay","Trace Gold variants","Trace normal crystal","Trace crystal_100 variant"],HackMenuViewDescriptor.DIAGNOSTICS_ENGINE,"Diagnostics engine"));
               param1.push(view("GOLD_BOX_DIAGNOSTICS:PROXIMITY_DEBUG",param2,"Proximity Debug",DEBUGS,"Collection probes, distance thresholds and retry controls.",30,["Shadow radius probe","Airborne shadow collect","Proximity collect - normal crystal","Proximity collect distance","Proximity collect max horizontal","Proximity collect retry interval","Proximity collect max attempts per bonus"],HackMenuViewDescriptor.DIAGNOSTICS_ENGINE,"Diagnostics engine"));
               return;
            default:
               param1.push(view(param2.id,param2,param2.name,UTILITY,"",1000));
         }
      }

      private static function view(param1:String, param2:Hack, param3:String, param4:String, param5:String, param6:int, param7:Array = null, param8:String = "standardHack", param9:String = "Enabled", param10:String = "standard", param11:Array = null) : HackMenuViewDescriptor
      {
         return new HackMenuViewDescriptor(param1,param2,param3,param4,param5,param6,param7,param8,param9,param10,param11);
      }
   }
}
