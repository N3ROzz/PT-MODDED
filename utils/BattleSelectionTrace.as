package utils
{
   import com.hurlant.crypto.hash.SHA256;
   import flash.desktop.NativeApplication;
   import flash.events.Event;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.utils.ByteArray;
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;
   import platform.client.fp10.core.type.IGameObject;

   public class BattleSelectionTrace
   {
      public static const ENABLED:Boolean = false;
      public static const BATTLE_SELECT_SEND_TRAILING_SPACE:Boolean = false;
      public static const BUILD_VARIANT:String = "BATTLE_SELECT_PAYLOAD_EXACT";

      private static const SELECT_INBOUND_WINDOW_MS:int = 3000;

      private static var sequence:int = 0;
      private static var initialized:Boolean = false;
      private static var sessionEnded:Boolean = false;
      private static var sessionId:String = "";
      private static var swfHash:String = "";
      private static var controllerSelectedId:String = "";
      private static var pendingId:String = "";
      private static var pendingPayload:String = "";
      private static var lastAckId:String = "";
      private static var inputSource:String = "";
      private static var loadInfoItemId:String = "";
      private static var selectInboundWindowUntil:int = 0;
      private static var nextObjectIdentity:int = 1;
      private static var objectIdentities:Dictionary = new Dictionary(true);
      private static var snapshotGeneration:int = 0;
      private static var latestFullSnapshotReceivedAt:int = -1;
      private static var latestFullSnapshotIds:Object = {};
      private static var currentServerBattleIds:Object = {};
      private static var lastAddedAt:Object = {};
      private static var lastRemovedAt:Object = {};
      private static var objectCreationGeneration:Object = {};
      private static var snapshotSetDumped:Boolean = false;
      private static var logFile:File = File.desktopDirectory.resolvePath("protanki-battle-selection-trace.log");

      public function BattleSelectionTrace()
      {
         throw new Error("BattleSelectionTrace is static");
      }

      public static function startSession() : void
      {
         var now:Date = null;
         var archive:File = null;
         var archiveStatus:String = "none";
         var archiveErrorMessage:String = "";
         if(!ENABLED || initialized)
         {
            return;
         }
         now = new Date();
         if(logFile.exists)
         {
            archive = File.desktopDirectory.resolvePath("protanki-battle-selection-trace_" + fileTimestamp(now) + ".log");
            try
            {
               logFile.moveTo(archive,false);
               archiveStatus = "archived:" + archive.name;
            }
            catch(archiveError:Error)
            {
               archiveStatus = "archive_failed_log_reset";
               archiveErrorMessage = clean(archiveError.message);
               resetLogFile();
            }
         }
         sessionId = now.time.toString(16) + "-" + getTimer().toString(16) + "-" + int(Math.random() * int.MAX_VALUE).toString(16);
         swfHash = calculateActiveSwfHash();
         initialized = true;
         NativeApplication.nativeApplication.addEventListener(Event.EXITING,onApplicationExiting,false,0,true);
         writeLineDirect("t=" + getTimer() + " seq=0 event=SESSION_START sessionId=" + sessionId + " swfSHA256=" + swfHash + " buildVariant=" + BUILD_VARIANT + " wallClock=" + isoTimestamp(now) + " getTimer=" + getTimer() + " previousLog=" + archiveStatus + " archiveError=" + archiveErrorMessage);
      }

      public static function buildSelectPayload(param1:String) : String
      {
         var id:String = normalize(param1);
         return BATTLE_SELECT_SEND_TRAILING_SPACE ? id + " " : id;
      }

      public static function setControllerSelection(param1:String) : void
      {
         if(ENABLED)
         {
            controllerSelectedId = normalize(param1);
         }
      }

      public static function setInputSource(param1:String) : void
      {
         if(ENABLED)
         {
            inputSource = param1;
         }
      }

      public static function beginLoadInfo(param1:String, param2:IGameObject = null, param3:String = "") : void
      {
         if(!ENABLED)
         {
            return;
         }
         loadInfoItemId = normalize(param1);
         record("INBOUND_LOAD_INFO","BattleInfoPacketHandler.loadBattleInfo",param1,param2,param3);
      }

      public static function beginRequest(param1:String, param2:String, param3:IGameObject = null) : void
      {
         var now:int = 0;
         var id:String = null;
         var detail:String = null;
         if(!ENABLED)
         {
            return;
         }
         startSession();
         sequence++;
         now = getTimer();
         id = normalize(param1);
         pendingId = id;
         pendingPayload = param2 == null ? "" : param2;
         selectInboundWindowUntil = now + SELECT_INBOUND_WINDOW_MS;
         detail = "packetId=2092412133" +
            " payloadVariant=" + BUILD_VARIANT +
            " payload=" + clean(pendingPayload) +
            " presentInLatestFullSnapshot=" + boolString(latestFullSnapshotIds[id] != null) +
            " presentInCurrentServerSet=" + boolString(currentServerBattleIds[id] != null) +
            " snapshotGeneration=" + snapshotGeneration +
            " snapshotAgeMs=" + age(now,latestFullSnapshotReceivedAt) +
            " latestFullSnapshotCount=" + objectCount(latestFullSnapshotIds) +
            " currentServerSetCount=" + objectCount(currentServerBattleIds) +
            " selectedObjectExists=" + boolString(param3 != null) +
            " objectCreationGeneration=" + valueOrUnknown(objectCreationGeneration[id]) +
            " lastAddedAgeMs=" + ageFromMap(now,lastAddedAt,id) +
            " lastRemovedAgeMs=" + ageFromMap(now,lastRemovedAt,id);
         record("OUTBOUND_SELECT","BattleSelectModelServer",param1,param3,detail);
         if(currentServerBattleIds[id] == null)
         {
            recordSetDump("SELECTED_ID_ABSENT",currentServerBattleIds);
         }
      }

      public static function acknowledge(param1:String, param2:IGameObject = null) : void
      {
         if(!ENABLED)
         {
            return;
         }
         lastAckId = normalize(param1);
         record("INBOUND_SELECT_ACK","BattleListPacketHandler",param1,param2,"");
      }

      public static function recordFullSnapshot(param1:Array) : void
      {
         var now:int = 0;
         var previous:Object = null;
         var next:Object = null;
         var raw:Object = null;
         var id:String = null;
         var key:String = null;
         if(!ENABLED)
         {
            return;
         }
         startSession();
         now = getTimer();
         previous = currentServerBattleIds;
         next = {};
         if(param1 != null)
         {
            for each(raw in param1)
            {
               id = normalize(raw == null ? "" : String(raw));
               if(id != "")
               {
                  next[id] = String(raw);
                  if(previous[id] == null)
                  {
                     lastAddedAt[id] = now;
                  }
               }
            }
         }
         for(key in previous)
         {
            if(next[key] == null)
            {
               lastRemovedAt[key] = now;
            }
         }
         snapshotGeneration++;
         latestFullSnapshotReceivedAt = now;
         latestFullSnapshotIds = copySet(next);
         currentServerBattleIds = copySet(next);
         writeSetEvent("FULL_SNAPSHOT_RECEIVED",next,"source=LoadAllBattles");
         if(!snapshotSetDumped)
         {
            snapshotSetDumped = true;
            recordSetDump("FIRST_FULL_SNAPSHOT",next);
         }
      }

      public static function recordBattleCreated(param1:String) : void
      {
         var id:String = normalize(param1);
         if(!ENABLED || id == "")
         {
            return;
         }
         startSession();
         currentServerBattleIds[id] = param1;
         lastAddedAt[id] = getTimer();
         writeSetEvent("BATTLE_SERVER_ADD",currentServerBattleIds,"rawId=" + clean(param1));
      }

      public static function recordBattleRemoved(param1:String) : void
      {
         var id:String = normalize(param1);
         if(!ENABLED || id == "")
         {
            return;
         }
         startSession();
         delete currentServerBattleIds[id];
         lastRemovedAt[id] = getTimer();
         writeSetEvent("BATTLE_SERVER_REMOVE",currentServerBattleIds,"rawId=" + clean(param1));
      }

      public static function recordBattleObjectCreated(param1:String) : void
      {
         var id:String = normalize(param1);
         if(ENABLED && id != "")
         {
            objectCreationGeneration[id] = snapshotGeneration;
         }
      }

      public static function clearBattleSet(param1:String) : void
      {
         if(!ENABLED)
         {
            return;
         }
         startSession();
         latestFullSnapshotIds = {};
         currentServerBattleIds = {};
         latestFullSnapshotReceivedAt = -1;
         record("BATTLE_SERVER_SET_CLEARED",param1,"",null,"snapshotGeneration=" + snapshotGeneration);
      }

      public static function recordPreEncryptionFrame(param1:int, param2:ByteArray) : void
      {
         var payload:ByteArray = null;
         var frame:ByteArray = null;
         var marker:int = -1;
         var stringLength:int = -1;
         var utf8:ByteArray = null;
         if(!ENABLED || param1 != 2092412133 || param2 == null)
         {
            return;
         }
         payload = cloneBytes(param2);
         frame = new ByteArray();
         frame.writeInt(8 + payload.length);
         frame.writeInt(param1);
         frame.writeBytes(payload,0,payload.length);
         if(payload.length > 0)
         {
            marker = int(payload[0]);
         }
         if(marker == 0 && payload.length >= 5)
         {
            payload.position = 1;
            stringLength = payload.readInt();
            if(stringLength >= 0 && payload.bytesAvailable >= stringLength)
            {
               utf8 = new ByteArray();
               payload.readBytes(utf8,0,stringLength);
            }
         }
         record("SELECT_FRAME_PRE_ENCRYPTION","AbstractPacket.wrap",pendingId,null,
            "frameLength=" + frame.length +
            " packetId=" + param1 +
            " optionalMarker=" + marker +
            " stringLengthField=" + stringLength +
            " payloadUtf8Bytes=" + bytesToHex(utf8) +
            " payloadStringLength=" + pendingPayload.length +
            " finalCharacterCodes=" + finalCharacterCodes(pendingPayload) +
            " frameHex=" + bytesToHex(frame));
      }

      public static function recordEncryptedPayloadLength(param1:int, param2:int) : void
      {
         if(ENABLED && param1 == 2092412133)
         {
            record("SELECT_PAYLOAD_ENCRYPTED","AbstractPacket.wrap",pendingId,null,"encryptedPayloadLength=" + param2);
         }
      }

      public static function recordInboundPacket(param1:int, param2:int, param3:int) : void
      {
         var now:int = getTimer();
         if(ENABLED && pendingId != "" && now <= selectInboundWindowUntil)
         {
            record("INBOUND_AFTER_SELECT","Network.processIncoming",pendingId,null,"packetId=" + param1 + " handlerId=" + param2 + " frameLength=" + param3 + " elapsedSinceSelectMs=" + (now - (selectInboundWindowUntil - SELECT_INBOUND_WINDOW_MS)));
         }
      }

      public static function record(param1:String, param2:String, param3:String = "", param4:IGameObject = null, param5:String = "") : void
      {
         var line:String = null;
         if(!ENABLED)
         {
            return;
         }
         startSession();
         line = "t=" + getTimer() +
            " seq=" + sequence +
            " event=" + clean(param1) +
            " sessionId=" + sessionId +
            " source=" + clean(param2) +
            " rawId=" + clean(param3) +
            " normalizedId=" + clean(normalize(param3)) +
            " controllerSelectedId=" + clean(controllerSelectedId) +
            " pendingId=" + clean(pendingId) +
            " lastAckId=" + clean(lastAckId) +
            " itemId=" + clean(loadInfoItemId) +
            " inputSource=" + clean(inputSource) +
            " objectName=" + clean(param4 == null ? "" : param4.name) +
            " objectId=" + clean(param4 == null || param4.id == null ? "" : param4.id.toString()) +
            " objectNull=" + (param4 == null ? "1" : "0") +
            " matchesCurrent=" + matchesCurrent(param3) +
            " detail=" + clean(param5);
         writeLineDirect(line);
      }

      public static function error(param1:String, param2:String, param3:String, param4:IGameObject, param5:Error) : void
      {
         record("ERROR",param2,param3,param4,"stage=" + param1 + " type=" + (param5 == null ? "null" : param5.name) + " message=" + (param5 == null ? "" : param5.message) + " stack=" + (param5 == null ? "" : param5.getStackTrace()));
      }

      public static function normalize(param1:String) : String
      {
         return param1 == null ? "" : param1.replace(/^\s+|\s+$/g,"");
      }

      public static function identity(param1:Object) : String
      {
         if(param1 == null)
         {
            return "null";
         }
         if(objectIdentities[param1] == null)
         {
            objectIdentities[param1] = nextObjectIdentity++;
         }
         return getQualifiedClassName(param1) + "#" + objectIdentities[param1];
      }

      private static function writeSetEvent(param1:String, param2:Object, param3:String) : void
      {
         var ids:Array = sortedRawIds(param2);
         record(param1,"BattleSelectionTrace","",null,param3 + " snapshotGeneration=" + snapshotGeneration + " count=" + ids.length + " setHash=" + sha256String(ids.join("\n")));
      }

      private static function recordSetDump(param1:String, param2:Object) : void
      {
         var ids:Array = sortedRawIds(param2);
         record("BATTLE_SERVER_SET_DUMP","BattleSelectionTrace","",null,"reason=" + param1 + " count=" + ids.length + " setHash=" + sha256String(ids.join("\n")) + " ids=" + ids.join(","));
      }

      private static function sortedRawIds(param1:Object) : Array
      {
         var result:Array = [];
         var key:String = null;
         for(key in param1)
         {
            result.push(String(param1[key]));
         }
         result.sort(Array.CASEINSENSITIVE);
         return result;
      }

      private static function copySet(param1:Object) : Object
      {
         var result:Object = {};
         var key:String = null;
         for(key in param1)
         {
            result[key] = param1[key];
         }
         return result;
      }

      private static function objectCount(param1:Object) : int
      {
         var count:int = 0;
         var key:String = null;
         for(key in param1)
         {
            count++;
         }
         return count;
      }

      private static function age(param1:int, param2:int) : String
      {
         return param2 < 0 ? "unknown" : String(param1 - param2);
      }

      private static function ageFromMap(param1:int, param2:Object, param3:String) : String
      {
         return param2[param3] === undefined ? "unknown" : String(param1 - int(param2[param3]));
      }

      private static function valueOrUnknown(param1:Object) : String
      {
         return param1 === undefined || param1 == null ? "unknown" : String(param1);
      }

      private static function boolString(param1:Boolean) : String
      {
         return param1 ? "1" : "0";
      }

      private static function matchesCurrent(param1:String) : String
      {
         var id:String = normalize(param1);
         return id != "" && id == controllerSelectedId ? "1" : "0";
      }

      private static function clean(param1:String) : String
      {
         return param1 == null ? "" : param1.replace(/[\r\n]+/g," ").replace(/\s+/g," ");
      }

      private static function cloneBytes(param1:ByteArray) : ByteArray
      {
         var result:ByteArray = new ByteArray();
         var position:uint = param1.position;
         param1.position = 0;
         param1.readBytes(result,0,param1.length);
         param1.position = position;
         result.position = 0;
         return result;
      }

      private static function bytesToHex(param1:ByteArray) : String
      {
         var result:String = "";
         var i:int = 0;
         var value:int = 0;
         if(param1 == null)
         {
            return "";
         }
         while(i < param1.length)
         {
            value = int(param1[i]);
            if(value < 16)
            {
               result += "0";
            }
            result += value.toString(16).toUpperCase();
            i++;
         }
         return result;
      }

      private static function finalCharacterCodes(param1:String) : String
      {
         var result:Array = [];
         var start:int = 0;
         var i:int = 0;
         if(param1 == null || param1.length == 0)
         {
            return "";
         }
         start = Math.max(0,param1.length - 4);
         i = start;
         while(i < param1.length)
         {
            result.push(param1.charCodeAt(i));
            i++;
         }
         return result.join(",");
      }

      private static function sha256String(param1:String) : String
      {
         var bytes:ByteArray = new ByteArray();
         bytes.writeUTFBytes(param1 == null ? "" : param1);
         bytes.position = 0;
         return bytesToHex(new SHA256().hash(bytes));
      }

      private static function calculateActiveSwfHash() : String
      {
         var stream:FileStream = null;
         var bytes:ByteArray = null;
         var result:String = "unavailable";
         try
         {
            stream = new FileStream();
            stream.open(File.applicationDirectory.resolvePath("library.swf"),FileMode.READ);
            bytes = new ByteArray();
            stream.readBytes(bytes,0,stream.bytesAvailable);
            stream.close();
            bytes.position = 0;
            result = bytesToHex(new SHA256().hash(bytes));
         }
         catch(e:Error)
         {
            try
            {
               if(stream != null)
               {
                  stream.close();
               }
            }
            catch(closeError:Error)
            {
            }
            result = "unavailable:" + clean(e.message);
         }
         return result;
      }

      private static function onApplicationExiting(param1:Event) : void
      {
         if(initialized && !sessionEnded)
         {
            sessionEnded = true;
            writeLineDirect("t=" + getTimer() + " seq=" + sequence + " event=SESSION_END sessionId=" + sessionId + " swfSHA256=" + swfHash + " buildVariant=" + BUILD_VARIANT + " wallClock=" + isoTimestamp(new Date()) + " getTimer=" + getTimer());
         }
      }

      private static function writeLineDirect(param1:String) : void
      {
         var stream:FileStream = null;
         try
         {
            stream = new FileStream();
            stream.open(logFile,logFile.exists ? FileMode.APPEND : FileMode.WRITE);
            stream.writeUTFBytes(param1 + "\n");
            stream.close();
            trace(param1);
         }
         catch(e:Error)
         {
            try
            {
               if(stream != null)
               {
                  stream.close();
               }
            }
            catch(closeError:Error)
            {
            }
         }
      }

      private static function resetLogFile() : void
      {
         var stream:FileStream = null;
         try
         {
            stream = new FileStream();
            stream.open(logFile,FileMode.WRITE);
            stream.close();
         }
         catch(e:Error)
         {
            try
            {
               if(stream != null)
               {
                  stream.close();
               }
            }
            catch(closeError:Error)
            {
            }
         }
      }

      private static function isoTimestamp(param1:Date) : String
      {
         return param1.fullYear + "-" + pad(param1.month + 1,2) + "-" + pad(param1.date,2) + "T" + pad(param1.hours,2) + ":" + pad(param1.minutes,2) + ":" + pad(param1.seconds,2) + "." + pad(param1.milliseconds,3);
      }

      private static function fileTimestamp(param1:Date) : String
      {
         return param1.fullYear + pad(param1.month + 1,2) + pad(param1.date,2) + "_" + pad(param1.hours,2) + pad(param1.minutes,2) + pad(param1.seconds,2) + "_" + pad(param1.milliseconds,3);
      }

      private static function pad(param1:int, param2:int) : String
      {
         var result:String = String(param1);
         while(result.length < param2)
         {
            result = "0" + result;
         }
         return result;
      }
   }
}
