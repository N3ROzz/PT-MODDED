package utils
{
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.utils.ByteArray;
   import flash.utils.Dictionary;
   import flash.utils.clearTimeout;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;
   import flash.utils.setTimeout;

   public class RuntimeLifecycleDiagnostics
   {
      public static const DEFAULT_ENABLED:Boolean = false;

      // Temporary opt-in for the runtime diagnostic SWF. Set false for normal builds.
      public static const DIAGNOSTIC_BUILD_ENABLED:Boolean = false;

      private static const MAX_FILE_BYTES:uint = 10 * 1024 * 1024;

      private static const MAX_TEXT_LENGTH:int = 512;

      private static const FILE_PREFIX:String = "protanki-map-death-diagnostics-";

      private static const PREINIT_TIMEOUT_MS:int = 30000;

      private static var stream:FileStream;

      private static var logFile:File;

      private static var bytesWritten:uint;

      private static var sequence:uint;

      private static var sessionId:String;

      private static var initialized:Boolean;

      private static var capped:Boolean;

      private static var flushCounter:int;

      private static var mapBattleId:String = "unknown";

      private static var mapId:String = "unknown";

      private static var deathContexts:Dictionary = new Dictionary();

      private static var suicideTankId:String = "";

      private static var suicideActive:Boolean;

      private static var preinitActive:Boolean;

      private static var preinitStartedAt:int;

      private static var preinitTimeoutId:uint;

      private static var preinitBattleId:String = "";

      private static var selectedBattleId:String = "";

      private static var preinitTeam:String = "";

      private static var lastInboundPacketId:int = -1;

      private static var lastInboundHandlerId:int = -1;

      private static var lastInboundFrameLength:int = -1;

      private static var lastInboundCompressed:Boolean;

      private static var socketConnected:Boolean;

      private static var transportFailed:Boolean;

      private static var layoutSwitchInProgress:Boolean;

      private static var layoutInBattle:Boolean;

      private static var currentLayoutState:String = "unknown";

      private static var lastSelectRequestedBattleId:String = "";

      private static var lastSelectAckBattleId:String = "";

      public static function get enabled() : Boolean
      {
         return DEFAULT_ENABLED || DIAGNOSTIC_BUILD_ENABLED;
      }

      public static function startSession() : void
      {
         if(!enabled || initialized)
         {
            return;
         }
         try
         {
            initialized = true;
            sessionId = new Date().time.toString() + "-" + getTimer();
            logFile = File.desktopDirectory.resolvePath(FILE_PREFIX + sessionId + ".log");
            stream = new FileStream();
            stream.open(logFile,FileMode.WRITE);
            record("PACKET","SESSION_BEGIN","maxBytes=" + MAX_FILE_BYTES,true);
         }
         catch(e:Error)
         {
            stream = null;
         }
      }

      public static function recordSelection(param1:String, param2:String = "") : void
      {
         selectedBattleId = cleanValue(param1);
         record("PACKET","BATTLE_INFO_SELECTED_ID","selectedBattleId=" + selectedBattleId + appendDetails(param2),false);
      }

      public static function recordSelectRequest(param1:String, param2:Boolean, param3:Boolean) : void
      {
         if(!enabled)
         {
            return;
         }
         lastSelectRequestedBattleId = normalizeBattleId(param1);
         socketConnected = param2;
         transportFailed = param3;
         record("PACKET","SELECT_REQUEST","battleId=" + lastSelectRequestedBattleId + " socketConnected=" + (param2 ? 1 : 0) + " transportFailed=" + (param3 ? 1 : 0),true);
      }

      public static function recordSelectSend(param1:String, param2:int, param3:int, param4:String, param5:Boolean, param6:Boolean, param7:int, param8:String = "") : void
      {
         if(!enabled)
         {
            return;
         }
         socketConnected = param5;
         transportFailed = param6;
         record("PACKET",param1,"packetId=" + param2 + " handlerId=" + param3 + " battleId=" + normalizeBattleId(param4) + " socketConnected=" + (param5 ? 1 : 0) + " transportFailed=" + (param6 ? 1 : 0) + " sendBufferLength=" + param7 + appendDetails(param8),param1 == "SELECT_SEND_FAILURE");
      }

      public static function recordSelectAckFrame(param1:int, param2:int, param3:int, param4:Boolean) : void
      {
         if(enabled && param1 == 2092412133)
         {
            record("PACKET","SELECT_ACK_FRAME","packetId=" + param1 + " handlerId=" + param2 + " frameLength=" + param3 + " compressed=" + (param4 ? 1 : 0),false);
         }
      }

      public static function recordSelectAckHandler(param1:String, param2:String, param3:Boolean) : void
      {
         if(!enabled)
         {
            return;
         }
         var _loc4_:String = normalizeBattleId(param2);
         if(param1 == "SELECT_ACK")
         {
            lastSelectAckBattleId = _loc4_;
         }
         record("PACKET",param1,"requestedBattleId=" + lastSelectRequestedBattleId + " ackBattleId=" + _loc4_ + " battleObjectExists=" + (param3 ? 1 : 0),param1 == "SELECT_ACK_MISMATCH");
         if(param1 == "SELECT_ACK" && lastSelectRequestedBattleId != _loc4_)
         {
            record("PACKET","SELECT_ACK_MISMATCH","requestedBattleId=" + lastSelectRequestedBattleId + " ackBattleId=" + _loc4_ + " battleObjectExists=" + (param3 ? 1 : 0),true);
         }
      }

      public static function beginPreInit(param1:String, param2:String, param3:String, param4:Boolean, param5:Boolean, param6:Boolean, param7:Boolean) : void
      {
         if(!enabled)
         {
            return;
         }
         try
         {
            if(preinitActive)
            {
               finishPreInit("SUPERSEDED_BY_NEW_JOIN","PREINIT_STOPPED");
            }
            preinitActive = true;
            preinitStartedAt = getTimer();
            preinitBattleId = cleanValue(param1);
            selectedBattleId = cleanValue(param2);
            preinitTeam = cleanValue(param3);
            socketConnected = param4;
            transportFailed = param5;
            layoutSwitchInProgress = param6;
            layoutInBattle = param7;
            lastInboundPacketId = -1;
            lastInboundHandlerId = -1;
            lastInboundFrameLength = -1;
            lastInboundCompressed = false;
            preinitTimeoutId = setTimeout(onPreInitTimeout,PREINIT_TIMEOUT_MS);
            var _loc8_:Boolean = lastSelectRequestedBattleId == lastSelectAckBattleId && lastSelectAckBattleId == normalizeBattleId(selectedBattleId) && lastSelectAckBattleId.length > 0;
            var _loc9_:String = "battleId=" + preinitBattleId + " lastSelectRequestedBattleId=" + lastSelectRequestedBattleId + " lastSelectAckBattleId=" + lastSelectAckBattleId + " selectedBattleId=" + selectedBattleId + " team=" + preinitTeam + " socketConnected=" + (socketConnected ? 1 : 0) + " transportFailed=" + (transportFailed ? 1 : 0) + " layoutSwitchInProgress=" + (layoutSwitchInProgress ? 1 : 0) + " currentLayoutState=" + currentLayoutState + " inBattle=" + (layoutInBattle ? 1 : 0);
            record("PACKET","JOIN_REQUEST",_loc9_,true);
            record("PACKET",_loc8_ ? "JOIN_WITH_CONFIRMED_SELECTION" : "JOIN_WITH_UNCONFIRMED_SELECTION",_loc9_,!_loc8_);
         }
         catch(e:Error)
         {
         }
      }

      public static function recordJoinSend(param1:String, param2:int, param3:int, param4:Boolean, param5:Boolean, param6:int, param7:String = "") : void
      {
         if(!preinitActive)
         {
            return;
         }
         socketConnected = param4;
         transportFailed = param5;
         record("PACKET",param1,"packetId=" + param2 + " handlerId=" + param3 + " socketConnected=" + (param4 ? 1 : 0) + " transportFailed=" + (param5 ? 1 : 0) + " sendBufferLength=" + param6 + appendDetails(param7),param1 == "JOIN_SEND_FAILURE");
      }

      public static function recordPreInitNetworkStage(param1:String, param2:int, param3:int, param4:int, param5:Boolean, param6:int = -1) : void
      {
         if(!preinitActive)
         {
            return;
         }
         if(param3 < 0)
         {
            param3 = preInitHandlerForPacket(param2);
         }
         lastInboundPacketId = param2;
         lastInboundHandlerId = param3;
         lastInboundFrameLength = param4;
         lastInboundCompressed = param5;
         var _loc7_:String = "packetId=" + param2 + " handlerId=" + param3 + " frameLength=" + param4 + " compressed=" + (param5 ? 1 : 0);
         if(param6 >= 0)
         {
            _loc7_ += " frameReadyAt=" + param6;
         }
         record("PACKET",param1,_loc7_,false);
         if(param1 == "PREINIT_ANY_PACKET_RESOLVED")
         {
            var _loc8_:String = semanticEventForPacket(param2);
            if(_loc8_.length > 0)
            {
               record("PACKET",_loc8_,_loc7_,false);
            }
            if(param2 == 1118835050)
            {
               record("PACKET","LAYOUT_BEGIN_FRAME",_loc7_,false);
            }
            else if(param2 == -593368100)
            {
               record("PACKET","LAYOUT_END_FRAME",_loc7_,false);
            }
         }
      }

      public static function recordBattleSelectSpaceUnloaded() : void
      {
         if(preinitActive)
         {
            record("PACKET","BATTLE_SELECT_SPACE_UNLOADED","elapsedSinceJoinMs=" + (getTimer() - preinitStartedAt) + " layoutSwitchInProgress=" + (layoutSwitchInProgress ? 1 : 0) + " currentLayoutState=" + currentLayoutState + " inBattle=" + (layoutInBattle ? 1 : 0),true);
         }
      }

      public static function completePreInitAfterHandler(param1:int) : void
      {
         if(preinitActive && (param1 == -831998018 || param1 == 1229594925 || param1 == -10847382))
         {
            finishPreInit("JOIN_REJECTED_PACKET_" + param1,"PREINIT_STOPPED");
         }
      }

      public static function recordPreInitAnyHandler(param1:String, param2:int, param3:int) : void
      {
         if(preinitActive)
         {
            record("PACKET",param1,"packetId=" + param2 + " handlerId=" + param3 + " frameLength=" + lastInboundFrameLength + " compressed=" + (lastInboundCompressed ? 1 : 0),false);
         }
      }

      public static function recordPreInitHandler(param1:String, param2:int, param3:int, param4:String = "") : void
      {
         if(!preinitActive)
         {
            return;
         }
         record("PACKET",param1,"packetId=" + param2 + " handlerId=" + param3 + " frameLength=" + lastInboundFrameLength + " compressed=" + (lastInboundCompressed ? 1 : 0) + appendDetails(param4),false);
      }

      public static function recordPreInitFailure(param1:String, param2:int, param3:int, param4:int, param5:Boolean, param6:Error) : void
      {
         if(param3 < 0)
         {
            param3 = preInitHandlerForPacket(param2);
         }
         if(!preinitActive)
         {
            return;
         }
         record("PACKET","PREINIT_ANY_PACKET_FAILURE","packetId=" + param2 + " handlerId=" + param3 + " frameLength=" + param4 + " compressed=" + (param5 ? 1 : 0) + " stage=" + cleanValue(param1) + " errorName=" + errorName(param6) + " errorMessage=" + errorMessage(param6),true);
      }

      public static function recordBattleInfo(param1:String, param2:String = "", param3:Boolean = false) : void
      {
         record("PACKET",param1,"selectedBattleId=" + selectedBattleId + appendDetails(param2),param3);
      }

      public static function recordLayout(param1:String, param2:String = "", param3:Boolean = false) : void
      {
         if(!preinitActive)
         {
            return;
         }
         record("PACKET",param1,"layoutSwitchInProgress=" + (layoutSwitchInProgress ? 1 : 0) + " currentLayoutState=" + currentLayoutState + " inBattle=" + (layoutInBattle ? 1 : 0) + appendDetails(param2),param3);
      }

      public static function updateTransportState(param1:Boolean, param2:Boolean) : void
      {
         socketConnected = param1;
         transportFailed = param2;
      }

      public static function updateLayoutState(param1:Boolean, param2:Boolean, param3:String = null) : void
      {
         layoutSwitchInProgress = param1;
         layoutInBattle = param2;
         if(param3 != null)
         {
            currentLayoutState = cleanValue(param3);
         }
      }

      public static function recordSocketData(param1:int, param2:int, param3:int, param4:int) : void
      {
         if(preinitActive)
         {
            record("PACKET","SOCKET_DATA","bytesAvailable=" + param1 + " readCount=" + param2 + " inputBufferLength=" + param3 + " readPosition=" + param4,false);
         }
      }

      public static function recordSocketTermination(param1:String, param2:String = "") : void
      {
         if(!preinitActive)
         {
            return;
         }
         socketConnected = false;
         record("PACKET",param1,"socketConnected=0 transportFailed=" + (transportFailed ? 1 : 0) + appendDetails(param2),true);
         finishPreInit(param1,"PREINIT_STOPPED");
      }

      public static function recordTransportFailed(param1:String) : void
      {
         transportFailed = true;
         socketConnected = false;
         if(preinitActive)
         {
            record("PACKET","TRANSPORT_FAILED","reason=" + cleanValue(param1),true);
            finishPreInit("TRANSPORT_FAILED","PREINIT_STOPPED");
         }
      }

      public static function completePreInit(param1:String) : void
      {
         if(preinitActive)
         {
            finishPreInit(param1,"PREINIT_COMPLETE");
         }
      }

      public static function stopPreInit(param1:String) : void
      {
         if(preinitActive)
         {
            finishPreInit(param1,"PREINIT_STOPPED");
         }
      }

      public static function beginMap(param1:String, param2:String) : void
      {
         mapBattleId = cleanValue(param1);
         mapId = cleanValue(param2);
      }

      public static function recordMap(param1:String, param2:String = "", param3:Boolean = false) : void
      {
         record("MAP",param1,"battleId=" + mapBattleId + " mapId=" + mapId + appendDetails(param2),param3);
      }

      public static function beginDeath(param1:String, param2:String, param3:int, param4:Boolean) : void
      {
         if(!enabled)
         {
            return;
         }
         try
         {
            deathContexts[cleanValue(param1)] = {
               tankId: cleanValue(param1),
               killerId: cleanValue(param2),
               delay: param3,
               isLocal: param4
            };
         }
         catch(e:Error)
         {
         }
      }

      public static function recordDeath(param1:String, param2:String, param3:String = "", param4:Boolean = false) : void
      {
         var _loc5_:String = cleanValue(param2);
         var _loc6_:Object = null;
         try
         {
            _loc6_ = deathContexts[_loc5_];
         }
         catch(e:Error)
         {
         }
         var _loc7_:String = "tankId=" + _loc5_;
         if(_loc6_ != null)
         {
            _loc7_ += " killerId=" + _loc6_.killerId + " delay=" + _loc6_.delay + " isLocal=" + (_loc6_.isLocal ? 1 : 0);
         }
         record("DEATH",param1,_loc7_ + appendDetails(param3),param4);
      }

      public static function beginSuicide(param1:String, param2:int, param3:int) : void
      {
         suicideTankId = cleanValue(param1);
         suicideActive = true;
         record("SUICIDE","SUICIDE_KEY_REQUEST","tankId=" + suicideTankId + " suicideDelayMS=" + param2 + " SUICIDE_PING_DELAY=" + param3,true);
      }

      public static function beginSuicideResponse(param1:String, param2:int) : void
      {
         suicideTankId = cleanValue(param1);
         suicideActive = true;
         recordSuicide("SUICIDE_HANDLER_ENTER","delay=" + param2,true);
      }

      public static function recordSuicide(param1:String, param2:String = "", param3:Boolean = false) : void
      {
         record("SUICIDE",param1,"tankId=" + cleanValue(suicideTankId) + appendDetails(param2),param3);
      }

      public static function recordTankLifecycle(param1:String, param2:String, param3:String = "", param4:Boolean = false) : void
      {
         var _loc5_:String = cleanValue(param2);
         if(suicideActive && _loc5_ == suicideTankId)
         {
            recordSuicide(param1,param3,param4);
            if(param1 == "EXPLOSION_CREATED")
            {
               suicideActive = false;
            }
         }
         else
         {
            recordDeath(param1,_loc5_,param3,param4);
         }
      }

      public static function recordPacketStage(param1:String, param2:int, param3:int, param4:int, param5:Boolean, param6:String = "") : void
      {
         if(!isTargetPacket(param2))
         {
            return;
         }
         if(param3 < 0)
         {
            param3 = handlerForPacket(param2);
         }
         var _loc7_:String = categoryForPacket(param2);
         record(_loc7_,param1,"packetId=" + param2 + " handlerId=" + param3 + " frameLength=" + param4 + " compressed=" + (param5 ? 1 : 0) + appendDetails(param6),false);
         if(param1 == "FRAME_READY" && param2 == -152638117)
         {
            recordPreInitNetworkStage("PREINIT_ANY_FRAME",param2,param3,param4,param5,getTimer());
            record("MAP","INIT_BATTLE_FRAME_READY","packetId=" + param2 + " handlerId=" + param3 + " frameLength=" + param4 + " compressed=" + (param5 ? 1 : 0),true);
            completePreInit("INIT_BATTLE_RECEIVED");
         }
         else if(param1 == "FRAME_READY" && param2 == 162656882)
         {
            record("SUICIDE","SUICIDE_IN_FRAME_READY","packetId=" + param2 + " handlerId=" + param3 + " frameLength=" + param4 + " compressed=" + (param5 ? 1 : 0),true);
         }
      }

      public static function recordPacketFailure(param1:String, param2:int, param3:int, param4:Boolean, param5:Error) : void
      {
         if(!isTargetPacket(param2))
         {
            return;
         }
         record(categoryForPacket(param2),"PACKET_FAILURE","packetId=" + param2 + " frameLength=" + param3 + " compressed=" + (param4 ? 1 : 0) + " stage=" + cleanValue(param1) + " errorName=" + errorName(param5) + " errorMessage=" + errorMessage(param5),true);
      }

      public static function recordListenerFailure(param1:Object, param2:Object, param3:Error) : void
      {
         try
         {
            var _loc4_:String = className(param1);
            if(_loc4_.indexOf("TankKilledEvent") < 0 && _loc4_.indexOf("TankSuicideEvent") < 0)
            {
               return;
            }
            record("DEATH","BATTLE_EVENT_LISTENER_FAILURE","eventClass=" + _loc4_ + " listenerClass=" + className(param2) + " errorName=" + errorName(param3) + " errorMessage=" + errorMessage(param3),true);
         }
         catch(e:Error)
         {
         }
      }

      public static function record(param1:String, param2:String, param3:String = "", param4:Boolean = false) : void
      {
         if(!enabled || capped)
         {
            return;
         }
         try
         {
            startSession();
            if(stream == null)
            {
               return;
            }
            var _loc5_:String = "t=" + getTimer() + " session=" + sessionId + " seq=" + sequence++ + " category=" + cleanValue(param1) + " event=" + cleanValue(param2) + appendDetails(param3) + "\r\n";
            var _loc6_:ByteArray = new ByteArray();
            _loc6_.writeUTFBytes(_loc5_);
            if(bytesWritten + _loc6_.length > MAX_FILE_BYTES)
            {
               capped = true;
               closeStream();
               return;
            }
            stream.writeBytes(_loc6_,0,_loc6_.length);
            bytesWritten += _loc6_.length;
            ++flushCounter;
            if(param4 && shouldForceClose(param2) || flushCounter >= 16)
            {
               reopenStreamForAppend();
               flushCounter = 0;
            }
         }
         catch(e:Error)
         {
         }
      }

      private static function isTargetPacket(param1:int) : Boolean
      {
         return param1 == -152638117 || param1 == -42520728 || param1 == 162656882;
      }

      private static function onPreInitTimeout() : void
      {
         if(!preinitActive)
         {
            return;
         }
         var _loc1_:int = getTimer() - preinitStartedAt;
         record("PACKET","PREINIT_TIMEOUT","battleId=" + preinitBattleId + " selectedBattleId=" + selectedBattleId + " team=" + preinitTeam + " elapsedSinceJoinMs=" + _loc1_ + " lastInboundPacketId=" + lastInboundPacketId + " lastInboundHandlerId=" + lastInboundHandlerId + " layoutSwitchInProgress=" + (layoutSwitchInProgress ? 1 : 0) + " currentLayoutState=" + currentLayoutState + " inBattle=" + (layoutInBattle ? 1 : 0) + " socketConnected=" + (socketConnected ? 1 : 0) + " transportFailed=" + (transportFailed ? 1 : 0),true);
         preinitActive = false;
         preinitTimeoutId = 0;
      }

      private static function finishPreInit(param1:String, param2:String) : void
      {
         var _loc3_:int = getTimer() - preinitStartedAt;
         if(preinitTimeoutId != 0)
         {
            clearTimeout(preinitTimeoutId);
            preinitTimeoutId = 0;
         }
         record("PACKET",param2,"reason=" + cleanValue(param1) + " elapsedSinceJoinMs=" + _loc3_ + " lastInboundPacketId=" + lastInboundPacketId + " lastInboundHandlerId=" + lastInboundHandlerId + " layoutSwitchInProgress=" + (layoutSwitchInProgress ? 1 : 0) + " currentLayoutState=" + currentLayoutState + " inBattle=" + (layoutInBattle ? 1 : 0) + " socketConnected=" + (socketConnected ? 1 : 0) + " transportFailed=" + (transportFailed ? 1 : 0),true);
         preinitActive = false;
      }

      private static function semanticEventForPacket(param1:int) : String
      {
         switch(param1)
         {
            case 546722394:
               return "LOAD_BATTLE_INFO";
            case -911626491:
               return "JOINED_DM_BATTLE";
            case 118447426:
               return "JOINED_TEAM_BATTLE";
            case 1118835050:
               return "BEGIN_LAYOUT_SWITCH";
            case -593368100:
               return "END_LAYOUT_SWITCH";
            case -602527073:
               return "UNLOAD_BATTLE_INFO";
            case -879771375:
               return "BATTLE_STOPPED";
            case -324155151:
               return "UNLOAD_BATTLE_SELECT_SPACE";
            case -831998018:
            case 1229594925:
            case -10847382:
               return "JOIN_REJECTED";
         }
         return "";
      }

      private static function preInitHandlerForPacket(param1:int) : int
      {
         switch(param1)
         {
            case 1118835050:
            case -593368100:
               return 12;
            case -911626491:
            case 118447426:
            case 546722394:
            case -602527073:
            case 1924874982:
            case -879771375:
            case -831998018:
            case 1229594925:
            case -10847382:
            case 1534651002:
            case -344514517:
            case -1702097572:
            case 1561014187:
            case -1263036614:
            case -698399183:
            case -375282889:
            case 1428217189:
               return 33;
            case -324155151:
               return 31;
         }
         return -1;
      }

      private static function shouldForceClose(param1:String) : Boolean
      {
         return param1 == "PACKET_FAILURE" || param1 == "PREINIT_ANY_PACKET_FAILURE" || param1 == "PREINIT_TIMEOUT" || param1 == "PREINIT_COMPLETE" || param1 == "PREINIT_STOPPED" || param1 == "JOIN_SEND_FAILURE" || param1 == "SELECT_SEND_FAILURE" || param1 == "RESOURCE_FATAL" || param1 == "ZERO_TEXTURE_COLLECTIONS" || param1 == "MAP_TEXTURE_FAILURE" || param1 == "BATTLE_EVENT_LISTENER_FAILURE" || param1 == "REMOTE_TIMEOUT_FIRED" || param1 == "EXPLOSION_CREATED" || param1 == "SUICIDE_INDICATOR_ZERO" || param1 == "UNLOCK_MAP";
      }

      private static function reopenStreamForAppend() : void
      {
         try
         {
            closeStream();
            stream = new FileStream();
            stream.open(logFile,FileMode.APPEND);
         }
         catch(e:Error)
         {
            stream = null;
         }
      }

      private static function closeStream() : void
      {
         if(stream == null)
         {
            return;
         }
         try
         {
            stream.close();
         }
         catch(e:Error)
         {
         }
         stream = null;
      }

      private static function categoryForPacket(param1:int) : String
      {
         if(param1 == -152638117)
         {
            return "MAP";
         }
         if(param1 == 162656882)
         {
            return "SUICIDE";
         }
         return "DEATH";
      }

      private static function handlerForPacket(param1:int) : int
      {
         if(param1 == -152638117)
         {
            return 36;
         }
         if(param1 == -42520728)
         {
            return 39;
         }
         if(param1 == 162656882)
         {
            return 40;
         }
         return -1;
      }

      private static function appendDetails(param1:String) : String
      {
         var _loc2_:String = cleanValue(param1);
         return _loc2_.length == 0 ? "" : " " + _loc2_;
      }

      private static function normalizeBattleId(param1:String) : String
      {
         return param1 == null ? "" : cleanValue(param1.replace(/^\s+|\s+$/g,""));
      }

      private static function cleanValue(param1:*) : String
      {
         if(param1 == null)
         {
            return "";
         }
         var _loc2_:String = String(param1).replace(/[\r\n\t]+/g," ");
         return _loc2_.length > MAX_TEXT_LENGTH ? _loc2_.substr(0,MAX_TEXT_LENGTH) : _loc2_;
      }

      private static function errorName(param1:Error) : String
      {
         return param1 == null ? "" : cleanValue(param1.name);
      }

      private static function errorMessage(param1:Error) : String
      {
         return param1 == null ? "" : cleanValue(param1.message);
      }

      private static function className(param1:Object) : String
      {
         if(param1 == null)
         {
            return "null";
         }
         var _loc2_:String = getQualifiedClassName(param1);
         return cleanValue(_loc2_);
      }
   }
}
