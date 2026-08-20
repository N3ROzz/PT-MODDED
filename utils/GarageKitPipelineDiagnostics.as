package utils
{
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.utils.Dictionary;
   import flash.utils.getTimer;
   import platform.client.fp10.core.type.IGameObject;

   public final class GarageKitPipelineDiagnostics
   {
      private static const BUILD_ID:String = "GARAGE_KIT_PIPELINE_DIAG_01";

      private static var sequence:uint;

      private static var marketGeneration:uint;

      private static var sessionStarted:Boolean;

      private static var records:Vector.<Object> = new Vector.<Object>();

      private static var recordsBySource:Dictionary = new Dictionary();

      private static var recordsByObject:Dictionary = new Dictionary();

      public static function beginMarket(jsonLength:int) : void
      {
         ensureSession();
         ++marketGeneration;
         records = new Vector.<Object>();
         recordsBySource = new Dictionary();
         recordsByObject = new Dictionary();
         write("MARKET_PACKET_RECEIVED generation=" + marketGeneration + " jsonLength=" + jsonLength);
      }

      public static function received(source:Object, serverIndex:int, componentCount:int) : void
      {
         var record:Object = getOrCreateSource(source);
         record.received = true;
         record.parsed = true;
         record.serverIndex = serverIndex;
         record.componentsTotal = componentCount;
         status(record,"RECEIVED");
      }

      public static function componentResolution(source:Object, componentId:String, resolved:Boolean, resolutionSource:String, reason:String) : void
      {
         var record:Object = getOrCreateSource(source);
         if(resolved)
         {
            ++record.componentsResolved;
         }
         else
         {
            setDropReason(record,"component_" + safe(reason) + ":" + safe(componentId));
         }
         write("KIT_COMPONENT generation=" + marketGeneration + " kit=" + safe(record.id) + " component=" + safe(componentId) + " resolved=" + yesNo(resolved) + " source=" + safe(resolutionSource) + " reason=" + safe(reason));
         status(record,"COMPONENT_RESOLUTION");
      }

      public static function dropSource(source:Object, reason:String) : void
      {
         var record:Object = getOrCreateSource(source);
         setDropReason(record,reason);
         status(record,"DROPPED");
      }

      public static function objectCreated(source:Object, object:IGameObject) : void
      {
         var record:Object = getOrCreateSource(source);
         record.objectCreated = object != null;
         record.object = object;
         if(object != null)
         {
            recordsByObject[object] = record;
         }
         else
         {
            setDropReason(record,"object_not_created");
         }
         status(record,"OBJECT_CREATED");
      }

      public static function objectFailure(source:Object, stage:String, error:Error) : void
      {
         var record:Object = getOrCreateSource(source);
         setDropReason(record,"exception_" + safe(stage) + ":" + safe(error == null ? "unknown" : error.name));
         write("KIT_EXCEPTION generation=" + marketGeneration + " kit=" + safe(record.id) + " stage=" + safe(stage) + " name=" + safe(error == null ? "" : error.name) + " message=" + safe(error == null ? "" : error.message) + " stack=" + safe(error == null ? "" : error.getStackTrace()));
         status(record,"EXCEPTION");
      }

      public static function marketCollected(object:IGameObject) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         record.marketCollected = true;
         status(record,"MARKET_COLLECTION");
      }

      public static function classification(object:IGameObject, categoryKit:Boolean, hasGarageKit:Boolean, result:Boolean) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         record.isKit = result ? "yes" : "no";
         record.classificationDetails = "categoryKit=" + yesNo(categoryKit) + ",garageKitModel=" + yesNo(hasGarageKit);
         if(!result)
         {
            setDropReason(record,"is_kit_false");
         }
         status(record,"KIT_CLASSIFICATION");
      }

      public static function buyable(object:IGameObject, modelBuyable:Boolean, timeEnabled:Boolean, result:Boolean) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         record.buyableDetails = "model=" + yesNo(modelBuyable) + ",time=" + yesNo(timeEnabled);
         if(!result)
         {
            record.canBuyReason = modelBuyable ? "time_disabled" : "buyable_model_false";
         }
         status(record,"BUYABLE_EVALUATED");
      }

      public static function timeState(object:IGameObject, enabled:Boolean, timeless:Boolean, timeLeft:int, timeToStart:int, effectiveResult:Boolean) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         record.timeDetails = "enabled=" + yesNo(enabled) + ",timeless=" + yesNo(timeless) + ",left=" + timeLeft + ",startsIn=" + timeToStart + ",effective=" + yesNo(effectiveResult);
         status(record,"TIME_EVALUATED");
      }

      public static function kitCanBuy(object:IGameObject, result:Boolean, reason:String, savings:int) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         record.kitCanBuyDetails = "result=" + yesNo(result) + ",reason=" + safe(reason) + ",savings=" + savings;
         record.canBuyReason = reason;
         status(record,"KIT_CAN_BUY");
      }

      public static function canBuy(object:IGameObject, result:Boolean, reason:String, userRank:int, minRank:int, maxRank:int, grouped:Boolean, groupOwned:Boolean, owned:Boolean) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         record.canBuyReason = reason;
         record.filterDetails = "result=" + yesNo(result) + ",rank=" + userRank + ",min=" + minRank + ",max=" + maxRank + ",grouped=" + yesNo(grouped) + ",groupOwned=" + yesNo(groupOwned) + ",owned=" + yesNo(owned);
         status(record,"CAN_BUY_EVALUATED");
      }

      public static function marketFilter(object:IGameObject, canBuy:Boolean, partnerAvailable:Boolean) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         if(!canBuy)
         {
            setDropReason(record,"can_buy_false:" + safe(record.canBuyReason));
         }
         else if(!partnerAvailable)
         {
            setDropReason(record,"partner_unavailable");
         }
         status(record,"MARKET_FILTER");
      }

      public static function marketInserted(object:IGameObject) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         record.marketInserted = true;
         status(record,"MARKET_INSERTED");
      }

      public static function dropObject(object:IGameObject, reason:String) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         setDropReason(record,reason);
         status(record,"DROPPED");
      }

      public static function objectException(object:IGameObject, stage:String, error:Error) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         setDropReason(record,"exception_" + safe(stage) + ":" + safe(error == null ? "unknown" : error.name));
         write("KIT_EXCEPTION generation=" + marketGeneration + " kit=" + safe(record.id) + " stage=" + safe(stage) + " name=" + safe(error == null ? "" : error.name) + " message=" + safe(error == null ? "" : error.message) + " stack=" + safe(error == null ? "" : error.getStackTrace()));
         status(record,"EXCEPTION");
      }

      public static function categoryEvaluated(object:IGameObject, selectedCategory:String, itemCategory:String, matches:Boolean) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         record.categoryDetails = "selected=" + safe(selectedCategory) + ",item=" + safe(itemCategory) + ",matches=" + yesNo(matches);
         status(record,matches ? "UI_CATEGORY_MATCH" : "UI_CATEGORY_NOT_SELECTED");
      }

      public static function finalVisible(object:IGameObject) : void
      {
         var record:Object = getRecord(object);
         if(record == null)
         {
            return;
         }
         record.finalVisible = true;
         status(record,"FINAL_VISIBLE");
      }

      public static function reportAll(stage:String) : void
      {
         for each(var record:Object in records)
         {
            status(record,stage);
         }
      }

      public static function isTracked(object:IGameObject) : Boolean
      {
         return getRecord(object) != null;
      }

      public static function getCanBuyReason(object:IGameObject) : String
      {
         var record:Object = getRecord(object);
         return record == null ? "not_tracked" : String(record.canBuyReason);
      }

      private static function getOrCreateSource(source:Object) : Object
      {
         var record:Object = source == null ? null : recordsBySource[source];
         if(record != null)
         {
            return record;
         }
         record = {
            id:field(source,"id"),
            name:field(source,"name"),
            received:false,
            parsed:false,
            objectCreated:false,
            isKit:"unknown",
            componentsResolved:0,
            componentsTotal:0,
            marketCollected:false,
            marketInserted:false,
            finalVisible:false,
            dropReason:"none",
            canBuyReason:"not_evaluated"
         };
         records.push(record);
         if(source != null)
         {
            recordsBySource[source] = record;
         }
         return record;
      }

      private static function getRecord(object:IGameObject) : Object
      {
         return object == null ? null : recordsByObject[object];
      }

      private static function setDropReason(record:Object, reason:String) : void
      {
         if(record.dropReason == "none")
         {
            record.dropReason = safe(reason);
         }
      }

      private static function status(record:Object, stage:String) : void
      {
         write("KIT_STATUS generation=" + marketGeneration + " stage=" + safe(stage) + " KIT=" + safe(record.id) + " NAME=" + safe(record.name) + " RECEIVED=" + yesNo(record.received) + " PARSED=" + yesNo(record.parsed) + " OBJECT_CREATED=" + yesNo(record.objectCreated) + " IS_KIT=" + record.isKit + " COMPONENTS_RESOLVED=" + record.componentsResolved + "/" + record.componentsTotal + " MARKET_COLLECTED=" + yesNo(record.marketCollected) + " MARKET_INSERTED=" + yesNo(record.marketInserted) + " FINAL_VISIBLE=" + yesNo(record.finalVisible) + " DROP_REASON=" + safe(record.dropReason) + detail(" classification",record.classificationDetails) + detail(" time",record.timeDetails) + detail(" buyable",record.buyableDetails) + detail(" kitCanBuy",record.kitCanBuyDetails) + detail(" filter",record.filterDetails) + detail(" category",record.categoryDetails));
      }

      private static function detail(label:String, value:Object) : String
      {
         return value == null ? "" : label + "=" + safe(value);
      }

      private static function field(source:Object, name:String) : String
      {
         return source != null && source.hasOwnProperty(name) && source[name] != null ? String(source[name]) : "";
      }

      private static function yesNo(value:Boolean) : String
      {
         return value ? "yes" : "no";
      }

      private static function safe(value:Object) : String
      {
         if(value == null)
         {
            return "";
         }
         return String(value).replace(/[\r\n\t]+/g," ");
      }

      private static function ensureSession() : void
      {
         if(sessionStarted)
         {
            return;
         }
         sessionStarted = true;
         var stream:FileStream = null;
         try
         {
            stream = new FileStream();
            stream.open(File.desktopDirectory.resolvePath("protanki-garage-kit-debug.log"),FileMode.WRITE);
            stream.writeUTFBytes("t=" + getTimer() + " [" + BUILD_ID + "] seq=" + sequence++ + " event=SESSION_BEGIN\n");
         }
         catch(error:Error)
         {
            trace("[" + BUILD_ID + "] logger failure " + error.message);
         }
         finally
         {
            if(stream != null)
            {
               try
               {
                  stream.close();
               }
               catch(closeError:Error)
               {
               }
            }
         }
      }

      private static function write(message:String) : void
      {
         ensureSession();
         var line:String = "t=" + getTimer() + " [" + BUILD_ID + "] seq=" + sequence++ + " event=" + message;
         var stream:FileStream = null;
         try
         {
            stream = new FileStream();
            stream.open(File.desktopDirectory.resolvePath("protanki-garage-kit-debug.log"),FileMode.APPEND);
            stream.writeUTFBytes(line + "\n");
         }
         catch(error:Error)
         {
            trace(line);
         }
         finally
         {
            if(stream != null)
            {
               try
               {
                  stream.close();
               }
               catch(closeError:Error)
               {
               }
            }
         }
      }
   }
}
