package utils
{
   import flash.events.TimerEvent;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import projects.tanks.client.battlefield.models.tankparts.weapons.common.TargetPosition;
   import projects.tanks.client.battlefield.models.tankparts.weapons.common.discrete.TargetHit;
   import projects.tanks.client.battlefield.types.Vector3d;
   
   public final class HammerDiagnostics
   {
      
      public static const ENABLED:Boolean = false;
      
      private static const FILE_NAME:String = "protanki-hammer-diagnostics.log";
      
      private static const MAX_BUFFERED_LINES:int = 2048;
      
      private static var lines:Vector.<String> = new Vector.<String>();
      
      private static var flushTimer:Timer;
      
      public static function log(param1:String, param2:String = "") : void
      {
         if(!ENABLED)
         {
            return;
         }
         if(lines.length >= MAX_BUFFERED_LINES)
         {
            lines.shift();
         }
         var _loc3_:String = "t=" + getTimer() + " [HAMMER_DIAG] event=" + sanitize(param1);
         if(param2.length > 0)
         {
            _loc3_ += " " + sanitize(param2);
         }
         lines.push(_loc3_);
         startFlushTimer();
      }
      
      public static function logTargets(param1:String, param2:Vector.<TargetPosition>) : void
      {
         if(!ENABLED)
         {
            return;
         }
         var _loc3_:int = param2 == null ? -1 : param2.length;
         log(param1,"targetCount=" + _loc3_);
         if(param2 == null)
         {
            return;
         }
         var _loc4_:int = 0;
         while(_loc4_ < param2.length)
         {
            var _loc5_:TargetPosition = param2[_loc4_];
            if(_loc5_ == null)
            {
               log(param1 + "_TARGET","index=" + _loc4_ + " targetRecord=null");
            }
            else
            {
               log(param1 + "_TARGET","index=" + _loc4_ + " user=" + (_loc5_.target == null ? "null" : _loc5_.target.name) + " localHitPoint=" + vectorToString(_loc5_.localHitPoint) + " position=" + vectorToString(_loc5_.position) + " orientation=" + vectorToString(_loc5_.orientation) + " turretAngle=" + _loc5_.turretAngle);
            }
            _loc4_++;
         }
      }
      
      public static function logError(param1:String, param2:Error) : void
      {
         if(!ENABLED)
         {
            return;
         }
         log(param1,"type=" + (param2 == null ? "null" : param2.name) + " message=" + (param2 == null ? "null" : param2.message) + " stack=" + (param2 == null ? "null" : param2.getStackTrace()));
      }
      
      public static function logTargetHits(param1:String, param2:Vector.<TargetHit>) : void
      {
         if(!ENABLED)
         {
            return;
         }
         var _loc3_:int = param2 == null ? -1 : param2.length;
         log(param1,"targetCount=" + _loc3_);
         if(param2 == null)
         {
            return;
         }
         var _loc4_:int = 0;
         while(_loc4_ < param2.length)
         {
            var _loc5_:TargetHit = param2[_loc4_];
            if(_loc5_ == null)
            {
               log(param1 + "_TARGET","index=" + _loc4_ + " targetHit=null");
            }
            else
            {
               log(param1 + "_TARGET","index=" + _loc4_ + " user=" + (_loc5_.target == null ? "null" : _loc5_.target.name) + " direction=" + vectorToString(_loc5_.direction) + " localHitPoint=" + vectorToString(_loc5_.localHitPoint) + " numberHits=" + _loc5_.numberHits);
            }
            _loc4_++;
         }
      }
      
      private static function vectorToString(param1:Vector3d) : String
      {
         if(param1 == null)
         {
            return "null";
         }
         return "(" + param1.x + "," + param1.y + "," + param1.z + ") finite=" + int(isFinite(param1.x) && isFinite(param1.y) && isFinite(param1.z));
      }
      
      private static function startFlushTimer() : void
      {
         if(flushTimer == null)
         {
            flushTimer = new Timer(1000);
            flushTimer.addEventListener(TimerEvent.TIMER,onFlushTimer);
         }
         if(!flushTimer.running)
         {
            flushTimer.start();
         }
      }
      
      private static function onFlushTimer(param1:TimerEvent) : void
      {
         flush();
         if(flushTimer != null)
         {
            flushTimer.stop();
         }
      }
      
      private static function flush() : void
      {
         if(lines.length == 0)
         {
            return;
         }
         var _loc1_:FileStream = new FileStream();
         try
         {
            _loc1_.open(File.desktopDirectory.resolvePath(FILE_NAME),FileMode.APPEND);
            _loc1_.writeUTFBytes(lines.join("\r\n") + "\r\n");
            lines.length = 0;
         }
         catch(error:Error)
         {
         }
         finally
         {
            try
            {
               _loc1_.close();
            }
            catch(closeError:Error)
            {
            }
         }
      }
      
      private static function sanitize(param1:String) : String
      {
         if(param1 == null)
         {
            return "null";
         }
         return param1.replace(/[\r\n]+/g," ");
      }
   }
}
