package juho.hacking
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.utils.Dictionary;
   import platform.client.fp10.core.type.IGameObject;
   
   public class PaintRegistry
   {
      public static const SELECTED_PAINT_CHANGED:String = "selectedPaintChanged";
      
      private static var paints:Array = [];
      
      private static var paintsByColoringId:Dictionary = new Dictionary();
      
      private static var coloringIdByName:Dictionary = new Dictionary();
      
      private static var visualOnlyItems:Dictionary = new Dictionary();
      
      private static var dispatcher:EventDispatcher = new EventDispatcher();
      
      private static var selectedPaintName:String = "";
      
      private static var selectedColoringId:int = 0;
      
      private static var initialized:Boolean = false;
      
      private static const DEFAULT_PAINT_NAMES:Array = [
         "Green","Holiday","Red","Blue","Black","White","Orange","Flora","Marine","Swamp",
         "Forester","Magma","Safari","Invader","Metallic","Lava","Dragon","Lead","Mary",
         "Storm","Carbon","Roger","Fracture","Vortex","Chainmail","Corrosion","Tundra",
         "Alien","Swash","Pixel","Guerrilla","Cedar","In love","Desert","Dirty","Jaguar",
         "Savanna","Loam","Sakura","Urban","Atom","Digital","Hohloma","Rhino","Electra",
         "Cherry","Blacksmith","Rustle","Python","Sandstone","Spark","Winter","Needle",
         "Zeus","Hive","Rock","Mars","Prodigi","Graffiti","Irbis","Mirage","Emerald",
         "Inferno","Nano","Clay","Taiga","Tiger","Jade","Picasso","Lumberjack","Africa",
         "Helper","Best Helper","Best Helper 2024","Best Helper 2025","Master of Parkour 2022",
         "Master of Parkour 2023","Master of Parkour 2024","Master of Parkour 2025","Mine",
         "Glide","Impulse","Acid","Star","Gladiator","Veteran","Champion","Silver",
         "Bronze","GAME 2024","GAME 2025","GAME 2026","Alligator","Aramid","Wiki Editor",
         "Helios","Cobalt","Engineer","Microchip","Neon","Spectator","Flame","YouTuber",
         "Premium Paint","Moonwalker","Eternity","Frost","Soul Flight","Year of the Dragon",
         "Arachnid","Smiley","Tank-Noir","Aurora","Nexus"
      ];
      
      private static const SPECIAL_PAINT_NAMES:Array = [
         "Helper","Best Helper","Best Helper 2024","Best Helper 2025",
         "Master of Parkour 2022","Master of Parkour 2023","Master of Parkour 2024","Master of Parkour 2025",
         "Glide","Impulse","Acid","Star","Gladiator","Veteran","Champion","Silver","Bronze","Storm",
         "GAME 2024","GAME 2025","GAME 2026",
         "Alligator","Aramid","Wiki Editor","Helios","Cobalt","Engineer","Microchip","Neon","Spectator","Flame","YouTuber",
         "Premium Paint","Moonwalker","Eternity","Frost","Soul Flight","Year of the Dragon",
         "Arachnid","Smiley","Tank-Noir","Aurora","Nexus"
      ];
      
      private static function initDefaults() : void
      {
         var _loc1_:String = null;
         if(initialized)
         {
            return;
         }
         initialized = true;
         for each(_loc1_ in DEFAULT_PAINT_NAMES)
         {
            addPaint(_loc1_,0);
         }
      }
      
      public static function addPaint(param1:String, param2:int) : void
      {
         var _loc3_:Object = null;
         if(param1 == null || param1 == "")
         {
            return;
         }
         if(param2 > 0 && paintsByColoringId[param2])
         {
            return;
         }
         _loc3_ = getPaintByName(param1);
         if(_loc3_ != null)
         {
            if(param2 > 0)
            {
               _loc3_.coloringId = param2;
               coloringIdByName[param1.toLowerCase()] = param2;
               paintsByColoringId[param2] = _loc3_;
               updateSelectedColoringIfNeeded(param1,param2);
            }
            return;
         }
         _loc3_ = {
            "gameName":param1,
            "id":param1,
            "coloringId":param2
         };
         if(param2 > 0)
         {
            paintsByColoringId[param2] = _loc3_;
            coloringIdByName[param1.toLowerCase()] = param2;
            updateSelectedColoringIfNeeded(param1,param2);
         }
         paints.push(_loc3_);
         paints.sortOn("gameName",Array.CASEINSENSITIVE);
      }
      
      public static function getPaintChoices() : Array
      {
         var _loc2_:Object = null;
         var _loc1_:Array = [];
         initDefaults();
         for each(_loc2_ in paints)
         {
            _loc1_.push(_loc2_);
         }
         return _loc1_;
      }
      
      public static function getSpecialPaintChoices() : Array
      {
         var _loc2_:String = null;
         var _loc1_:Array = [];
         initDefaults();
         for each(_loc2_ in SPECIAL_PAINT_NAMES)
         {
            _loc1_.push({
               "gameName":_loc2_,
               "id":_loc2_,
               "rang":0
            });
         }
         return _loc1_;
      }
      
      public static function getColoringIdByName(param1:String) : int
      {
         initDefaults();
         if(param1 == null)
         {
            return 0;
         }
         return int(coloringIdByName[param1.toLowerCase()]);
      }
      
      public static function isSpecialPaintName(param1:String) : Boolean
      {
         var _loc2_:String = null;
         if(param1 == null)
         {
            return false;
         }
         for each(_loc2_ in SPECIAL_PAINT_NAMES)
         {
            if(_loc2_.toLowerCase() == param1.toLowerCase())
            {
               return true;
            }
         }
         return false;
      }
      
      public static function markVisualOnlyItem(param1:IGameObject) : void
      {
         if(param1 != null)
         {
            visualOnlyItems[param1] = true;
         }
      }
      
      public static function isVisualOnlyItem(param1:IGameObject) : Boolean
      {
         return param1 != null && visualOnlyItems[param1] == true;
      }
      
      public static function setSelectedPaint(param1:String) : void
      {
         var _loc2_:int = getColoringIdByName(param1);
         if(selectedPaintName == param1 && selectedColoringId == _loc2_)
         {
            return;
         }
         selectedPaintName = param1;
         selectedColoringId = _loc2_;
         
         // For special paints without coloringId, generate one from paint name hash
         if(selectedColoringId <= 0 && isSpecialPaintName(param1))
         {
            selectedColoringId = generateIdFromPaintName(param1);
         }
         
         dispatcher.dispatchEvent(new Event(SELECTED_PAINT_CHANGED));
      }
      
      private static function generateIdFromPaintName(param1:String) : int
      {
         // Generate unique ID from paint name (never 0 or negative)
         var hash:int = 0;
         for(var i:int = 0; i < param1.length; i++)
         {
            hash = ((hash << 5) - hash) + param1.charCodeAt(i);
            hash = hash & hash; // Convert to 32bit integer
         }
         // Ensure positive and non-zero
         var result:int = Math.abs(hash) % 0x7FFFFFFF;
         return result > 0 ? result : 1;
      }
      
      public static function getSelectedColoringId() : int
      {
         return selectedColoringId;
      }
      
      public static function getSelectedPaintName() : String
      {
         return selectedPaintName;
      }
      
      public static function addEventListener(param1:String, param2:Function) : void
      {
         dispatcher.addEventListener(param1,param2);
      }
      
      public static function removeEventListener(param1:String, param2:Function) : void
      {
         dispatcher.removeEventListener(param1,param2);
      }
      
      private static function getPaintByName(param1:String) : Object
      {
         var _loc2_:Object = null;
         for each(_loc2_ in paints)
         {
            if(String(_loc2_.gameName).toLowerCase() == param1.toLowerCase())
            {
               return _loc2_;
            }
         }
         return null;
      }
      
      private static function updateSelectedColoringIfNeeded(param1:String, param2:int) : void
      {
         if(param2 > 0 && selectedPaintName != null && selectedPaintName.toLowerCase() == param1.toLowerCase() && selectedColoringId != param2)
         {
            selectedColoringId = param2;
            dispatcher.dispatchEvent(new Event(SELECTED_PAINT_CHANGED));
         }
      }
   }
}
