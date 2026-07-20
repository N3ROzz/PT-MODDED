package utils
{
   import alternativa.tanks.battle.objects.tank.Tank;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.utils.Dictionary;
   import flash.utils.getTimer;

   public class TankTraceUtil
   {
      public static const ENABLED:Boolean = false;
      public static const BATTLE_LIST_ENABLED:Boolean = false;
      public static const BATTLE_LIST_STALE_DEBUG_ENABLED:Boolean = false;
      public static const SET_TANK_HEALTH_SCOPE_ENABLED:Boolean = false;
      public static const HP_LIFECYCLE_ENABLED:Boolean = false;
      public static const SHAFT_SFX_ENABLED:Boolean = false;
      public static const CREATE_BATTLE_ENABLED:Boolean = false;
      public static const PREMIUM_DEBUG_ENABLED:Boolean = false;
      public static const RATINGS_DEBUG_ENABLED:Boolean = false;
      public static const TWINS_SFX_DEBUG_ENABLED:Boolean = false;
      public static const CLAN_USER_INFO_DEBUG_ENABLED:Boolean = false;
      public static const FRIENDS_DEBUG_ENABLED:Boolean = false;

      private static var nextTankId:int = 1;
      private static var tankIds:Dictionary = new Dictionary(true);
      private static var logFile:File = File.desktopDirectory.resolvePath("protanki-debug.log");
      private static var loggerAnnounced:Boolean = false;
      public static var lastBattleSelectId:String = "";
      public static var lastBattleJoinId:String = "";

      public function TankTraceUtil()
      {
         throw new Error("TankTraceUtil is a static utility class and cannot be instantiated");
      }

      public static function tankId(param1:Tank) : String
      {
         if(param1 == null)
         {
            return "null";
         }
         if(tankIds[param1] == null)
         {
            tankIds[param1] = nextTankId++;
         }
         return "T#" + tankIds[param1];
      }

      public static function tankInfo(param1:Tank) : String
      {
         if(param1 == null)
         {
            return "tank=null";
         }
         return "tank=" + tankId(param1) + " user=" + param1.userId + " health=" + param1.health + " max=" + param1.getMaxHealth() + " team=" + param1.teamType;
      }

      public static function log(param1:String) : void
      {
         writeLine(param1,ENABLED);
      }

      public static function logBattleList(param1:String) : void
      {
         writeLine("[BattleListDebug] " + param1,BATTLE_LIST_ENABLED);
      }

      public static function logBattleListStale(param1:String) : void
      {
         writeLine("[BattleListStaleDebug] " + param1,BATTLE_LIST_STALE_DEBUG_ENABLED);
      }

      public static function markBattleSelect(param1:String) : void
      {
         lastBattleSelectId = param1;
         logBattleListStale("markSelect battleId=" + param1);
      }

      public static function markBattleJoin(param1:String) : void
      {
         lastBattleJoinId = param1;
         logBattleListStale("markJoin battleId=" + param1 + " lastSelect=" + lastBattleSelectId);
      }

      public static function logSetTankHealthScope(param1:String) : void
      {
         writeLine(param1,ENABLED || SET_TANK_HEALTH_SCOPE_ENABLED);
      }

      public static function logHpLifecycle(param1:String) : void
      {
         writeLine(param1,ENABLED || HP_LIFECYCLE_ENABLED);
      }

      public static function logShaftSfx(param1:String) : void
      {
         writeLine("[SHAFT_SFX_DEBUG] " + param1,SHAFT_SFX_ENABLED);
      }
      
      public static function logCreateBattle(param1:String) : void
      {
         writeLine("[CreateBattleDebug] " + param1,CREATE_BATTLE_ENABLED);
      }

      public static function logPremium(param1:String) : void
      {
         writeLine("[PREMIUM_DEBUG] " + param1,PREMIUM_DEBUG_ENABLED);
      }
      
      public static function logRatings(param1:String) : void
      {
         writeLine("[RATINGS_DEBUG] " + param1,RATINGS_DEBUG_ENABLED);
      }

      public static function logTwinsSfx(param1:String) : void
      {
         writeLine("[TWINS_SFX_DEBUG] " + param1,TWINS_SFX_DEBUG_ENABLED);
      }

      public static function logClanUserInfo(param1:String) : void
      {
         writeLine("[CLAN_USER_INFO_DEBUG] " + param1,CLAN_USER_INFO_DEBUG_ENABLED);
      }

      public static function logFriends(param1:String) : void
      {
         writeLine("[FRIENDS_DEBUG] " + param1,FRIENDS_DEBUG_ENABLED);
      }

      private static function writeLine(param1:String, param2:Boolean) : void
      {
         var _loc2_:String = null;
         var _loc3_:FileStream = null;
         var _loc4_:String = null;
         if(!param2)
         {
            return;
         }
         if(!loggerAnnounced)
         {
            loggerAnnounced = true;
            writeLine("[TankTraceUtil] file logger active path=" + logFile.nativePath,true);
         }
         _loc2_ = "t=" + getTimer() + " " + param1;
         trace(_loc2_);
         try
         {
            _loc3_ = new FileStream();
            _loc4_ = logFile.exists ? FileMode.APPEND : FileMode.WRITE;
            _loc3_.open(logFile,_loc4_);
            _loc3_.writeUTFBytes(_loc2_ + "\n");
            _loc3_.close();
         }
         catch(e:Error)
         {
            try
            {
               if(_loc3_ != null)
               {
                  _loc3_.close();
               }
            }
            catch(closeError:Error)
            {
            }
         }
      }
   }
}
