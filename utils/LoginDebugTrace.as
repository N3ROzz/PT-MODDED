package utils
{
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.utils.getTimer;

   public class LoginDebugTrace
   {
      public static const LOGIN_DEBUG_ENABLED:Boolean = false;

      private static var logFile:File = File.desktopDirectory.resolvePath("protanki-login-debug.log");
      private static var captureActive:Boolean = false;
      private static var fileInitialized:Boolean = false;
      private static var sessionStart:int = 0;

      public function LoginDebugTrace()
      {
         throw new Error("LoginDebugTrace is a static utility class and cannot be instantiated");
      }

      public static function beginConnection(param1:String, param2:int, param3:Boolean) : void
      {
         if(!LOGIN_DEBUG_ENABLED)
         {
            return;
         }
         captureActive = true;
         sessionStart = getTimer();
         writeLine("SESSION_BEGIN host=" + sanitize(param1) + " port=" + param2 + " extraHost=" + int(param3));
      }

      public static function beginLoginAttempt(param1:String, param2:String = "", param3:Boolean = false) : void
      {
         if(!LOGIN_DEBUG_ENABLED)
         {
            return;
         }
         ensureCapture();
         writeLine("LOGIN_REQUEST method=" + sanitize(param1) + " uid=" + sanitize(param2) + " remember=" + int(param3));
      }

      public static function recordPacket(param1:String, param2:int, param3:int, param4:int, param5:String) : void
      {
         if(!LOGIN_DEBUG_ENABLED || !captureActive)
         {
            return;
         }
         writeLine("PACKET direction=" + sanitize(param1) + " packetId=" + param2 + " handlerId=" + param3 + " frameLength=" + param4 + " class=" + sanitize(param5));
      }

      public static function recordEvent(param1:String, param2:String = "") : void
      {
         if(!LOGIN_DEBUG_ENABLED || !captureActive)
         {
            return;
         }
         writeLine("event=" + sanitize(param1) + (param2 == "" ? "" : " " + sanitize(param2)));
      }

      public static function recordAuthSuccess(param1:int) : void
      {
         recordEvent("LOGIN_AUTH_SUCCESS_PACKET","packetId=" + param1);
      }

      public static function recordAuthFailure(param1:String, param2:int) : void
      {
         if(!LOGIN_DEBUG_ENABLED)
         {
            return;
         }
         ensureCapture();
         writeLine("event=LOGIN_AUTH_FAILED_PACKET method=" + sanitize(param1) + " packetId=" + param2);
         endSession("auth_failed");
      }

      public static function recordUserProperties(param1:String, param2:String, param3:int) : void
      {
         if(!LOGIN_DEBUG_ENABLED)
         {
            return;
         }
         ensureCapture();
         writeLine("event=USER_PROPERTIES_LOADED userId=" + sanitize(param1) + " uid=" + sanitize(param2) + " rank=" + param3);
         endSession("user_properties_loaded");
      }

      public static function endSession(param1:String) : void
      {
         if(!LOGIN_DEBUG_ENABLED || !captureActive)
         {
            return;
         }
         writeLine("SESSION_END reason=" + sanitize(param1));
         captureActive = false;
      }

      private static function ensureCapture() : void
      {
         if(!captureActive)
         {
            captureActive = true;
            sessionStart = getTimer();
            writeLine("SESSION_RESUMED source=login_attempt");
         }
      }

      private static function sanitize(param1:String) : String
      {
         var _loc2_:String = param1 == null ? "null" : param1.replace(/[\r\n\t]+/g," ");
         if(_loc2_.length > 160)
         {
            _loc2_ = _loc2_.substr(0,160);
         }
         return _loc2_;
      }

      private static function writeLine(param1:String) : void
      {
         var _loc2_:FileStream = null;
         var _loc3_:String = null;
         var _loc4_:int = getTimer();
         var _loc5_:String = "t=" + _loc4_ + " dt=" + (_loc4_ - sessionStart) + " [LOGIN_DEBUG] " + param1;
         trace(_loc5_);
         try
         {
            _loc2_ = new FileStream();
            _loc3_ = fileInitialized ? FileMode.APPEND : FileMode.WRITE;
            _loc2_.open(logFile,_loc3_);
            _loc2_.writeUTFBytes(_loc5_ + "\n");
            _loc2_.close();
            fileInitialized = true;
         }
         catch(e:Error)
         {
            try
            {
               if(_loc2_ != null)
               {
                  _loc2_.close();
               }
            }
            catch(closeError:Error)
            {
            }
         }
      }
   }
}
