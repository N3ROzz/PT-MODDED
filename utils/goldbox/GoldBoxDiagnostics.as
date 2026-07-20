package utils.goldbox
{
   import alternativa.math.Vector3;
   import alternativa.osgi.OSGi;
   import alternativa.tanks.battle.BattleService;
   import alternativa.tanks.battle.objects.tank.Tank;
   import alternativa.tanks.battle.objects.tank.ClientTankState;
   import alternativa.tanks.models.tank.LocalTankInfoService;
   import alternativa.tanks.utils.DebugPanel;
   import alternativa.types.Long;
   import flash.events.TimerEvent;
   import flash.utils.Dictionary;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import scpacker.utils.LongUtils;

   public class GoldBoxDiagnostics
   {
      private static const TIMER_INTERVAL_MS:int = 250;
      private static const SHADOW_DISCOVERY_INTERVAL_MS:int = 200;
      private static const SHADOW_ACTIVE_INTERVAL_MS:int = 100;
      private static const SHADOW_ACTIVE_RANGE:Number = 750;
      private static const SHADOW_ACTIVE_RANGE_SQUARED:Number = SHADOW_ACTIVE_RANGE * SHADOW_ACTIVE_RANGE;
      private static const AIRBORNE_HORIZONTAL_ACTIVE_RANGE:Number = 750;
      private static const AIRBORNE_HORIZONTAL_ACTIVE_RANGE_SQUARED:Number = AIRBORNE_HORIZONTAL_ACTIVE_RANGE * AIRBORNE_HORIZONTAL_ACTIVE_RANGE;
      private static const AIRBORNE_POSITION_MAX_AGE_MS:int = 300;
      private static const AIRBORNE_MOTION_MIN_INTERVAL_MS:int = 20;
      private static const AIRBORNE_MOTION_MAX_INTERVAL_MS:int = 400;
      private static const AIRBORNE_MAX_SAMPLE_JUMP:Number = 500;
      private static const AIRBORNE_MAX_SAMPLE_JUMP_SQUARED:Number = AIRBORNE_MAX_SAMPLE_JUMP * AIRBORNE_MAX_SAMPLE_JUMP;
      private static const AIRBORNE_DESCENT_MIN_SPEED:Number = 1;
      private static const FLUSH_INTERVAL_MS:int = 1000;
      private static const PERIODIC_LOG_INTERVAL_MS:int = 1000;
      private static const RESPONSE_TIMEOUT_MS:int = 5000;
      private static const MAX_RETAINED_SESSIONS:int = 256;
      private static const TARGET_GOLD_VARIANT:String = "gold_variant";
      private static const TARGET_NORMAL_CRYSTAL:String = "normal_crystal";
      private static const TARGET_CRYSTAL_100_VARIANT:String = "crystal_100_variant";
      private static const PROXIMITY_FALLING_POSITION_MAX_AGE_MS:int = 200;
      private static const PROXIMITY_RANGE_HYSTERESIS:Number = 50;
      private static const PROXIMITY_EXIT_TICKS:int = 2;

      private static var enabled:Boolean;
      private static var fileLogEnabled:Boolean;
      private static var overlayEnabled:Boolean;
      private static var sessions:Dictionary = new Dictionary();
      private static var regions:Dictionary = new Dictionary();
      private static var timer:Timer;
      private static var logger:GoldBoxDiagnosticLogger = new GoldBoxDiagnosticLogger();
      private static var overlay:DebugPanel;
      private static var latestBonusId:String;
      private static var latestLocalAttemptBonusId:String;
      private static var pendingRequests:Dictionary = new Dictionary();
      private static var sessionCount:int;
      private static var sessionCapOverflowLogged:Boolean;
      private static var lastFlushAt:int;
      private static var diagnosticsEpoch:int = -1;
      private static var battleEpoch:int = -1;
      private static var regionSourceHints:Dictionary = new Dictionary();
      private static var catalogTypes:Dictionary = new Dictionary();
      private static var traceGoldVariants:Boolean = true;
      private static var traceNormalCrystal:Boolean;
      private static var traceCrystal100Variant:Boolean;
      private static var shadowRadiusProbeEnabled:Boolean;
      private static var shadowTargetNearby:Boolean;
      private static var airborneShadowCollectEnabled:Boolean;
      private static var airborneTargetNearby:Boolean;
      private static var airborneTrackedBonusId:String;
      private static var lastOverlayAt:int = -1;
      private static var proximityCollectEnabled:Boolean;
      private static var proximityCollectDistance:Number = 400;
      private static var proximityMaxHorizontal:Number = 400;
      private static var proximityRetryIntervalMs:int = 100;
      private static var proximityMaxAttempts:int = 30;
      private static var proximityPositionReader:Function;
      private static var proximityAttemptRequester:Function;
      private static var proximityRuntimeStatusProvider:Function;
      private static var proximitySendContextBonusId:String;
      private static var proximitySendContextAttempt:int;
      private static var proximityPositionBuffer:Vector3 = new Vector3();
      private static var proximityLastStatusAt:int = -1;
      private static var proximityPacketsSentTotal:int;
      private static var proximityLastLocalRejectionReason:String;

      public static function setProximityCollect(param1:Boolean, param2:Number, param3:Number, param4:int, param5:int) : void
      {
         var _loc6_:GoldBoxDiagnosticSession = null;
         proximityCollectEnabled = param1;
         proximityCollectDistance = clampNumber(param2,200,500,400);
         proximityMaxHorizontal = clampNumber(param3,200,500,400);
         proximityRetryIntervalMs = clampInt(param4,50,1000,100);
         proximityMaxAttempts = clampInt(param5,1,100,30);
         if(!param1)
         {
            for each(_loc6_ in sessions)
            {
               if(_loc6_.proximityTracking || _loc6_.proximityAttemptsSent > 0)
               {
                  logSession(_loc6_,"PROXIMITY_COLLECT_STOPPED","reason=toggle_off attemptsSent=" + _loc6_.proximityAttemptsSent);
               }
               clearProximityState(_loc6_);
            }
         }
         else if(enabled)
         {
            startTimer();
         }
         if(param1)
         {
            for each(_loc6_ in sessions)
            {
               if(_loc6_.targetKind == TARGET_NORMAL_CRYSTAL && !_loc6_.terminal)
               {
                  _loc6_.proximityStopped = false;
               }
            }
            if(enabled && hasProximitySession())
            {
               startTimer();
            }
         }
         if(enabled)
         {
            logRaw("bonusId=unbound event=PROXIMITY_COLLECT_STATE_CHANGED enabled=" + bool(param1) + " distance=" + number(proximityCollectDistance) + " maxHorizontal=" + number(proximityMaxHorizontal) + " retryIntervalMs=" + proximityRetryIntervalMs + " maxAttempts=" + proximityMaxAttempts);
         }
         if(!param1)
         {
            stopTimerIfIdle();
         }
      }

      public static function registerProximityBridge(param1:Function, param2:Function, param3:Function = null) : void
      {
         proximityPositionReader = param1;
         proximityAttemptRequester = param2;
         proximityRuntimeStatusProvider = param3;
         if(enabled && proximityCollectEnabled)
         {
            startTimer();
         }
      }

      public static function unregisterProximityBridge() : void
      {
         proximityPositionReader = null;
         proximityAttemptRequester = null;
         proximityRuntimeStatusProvider = null;
         proximitySendContextBonusId = null;
         proximitySendContextAttempt = 0;
      }

      public static function beginProximitySendContext(param1:String, param2:int) : void
      {
         proximitySendContextBonusId = param1;
         proximitySendContextAttempt = param2;
      }

      public static function endProximitySendContext(param1:String) : void
      {
         if(proximitySendContextBonusId == param1)
         {
            proximitySendContextBonusId = null;
            proximitySendContextAttempt = 0;
         }
      }

      public static function setTargets(param1:Boolean, param2:Boolean, param3:Boolean) : void
      {
         var _loc4_:GoldBoxDiagnosticSession = null;
         traceGoldVariants = param1;
         traceNormalCrystal = param2;
         traceCrystal100Variant = param3;
         for each(_loc4_ in sessions)
         {
            if(!isSessionTargetEnabled(_loc4_) && !_loc4_.localAttempt && _loc4_.requestAt < 0)
            {
               clearShadowState(_loc4_);
               clearAirborneState(_loc4_);
            }
         }
         if(enabled)
         {
            logRaw("bonusId=unbound event=DIAGNOSTIC_TARGETS_CHANGED traceGold=" + bool(traceGoldVariants) + " traceNormalCrystal=" + bool(traceNormalCrystal) + " traceCrystal100Variant=" + bool(traceCrystal100Variant));
            if(shadowRadiusProbeEnabled && hasShadowEligibleSession())
            {
               startTimer();
            }
            if(airborneShadowCollectEnabled && hasAirborneCandidateSession())
            {
               startTimer();
            }
         }
      }

      public static function setShadowRadiusProbe(param1:Boolean) : void
      {
         var _loc2_:GoldBoxDiagnosticSession = null;
         shadowRadiusProbeEnabled = param1;
         shadowTargetNearby = false;
         if(!param1)
         {
            for each(_loc2_ in sessions)
            {
               clearShadowState(_loc2_);
            }
            setTimerDelay(TIMER_INTERVAL_MS);
         }
         else if(enabled && hasShadowEligibleSession())
         {
            setTimerDelay(SHADOW_DISCOVERY_INTERVAL_MS);
            startTimer();
         }
      }

      public static function setAirborneShadowCollect(param1:Boolean) : void
      {
         var _loc2_:GoldBoxDiagnosticSession = null;
         airborneShadowCollectEnabled = param1;
         airborneTargetNearby = false;
         if(!param1)
         {
            airborneTrackedBonusId = null;
            for each(_loc2_ in sessions)
            {
               clearAirborneState(_loc2_);
            }
            if(!shadowRadiusProbeEnabled)
            {
               setTimerDelay(TIMER_INTERVAL_MS);
            }
         }
         else if(enabled && hasAirborneCandidateSession())
         {
            setTimerDelay(SHADOW_DISCOVERY_INTERVAL_MS);
            startTimer();
         }
      }

      public static function setEnabled(param1:Boolean, param2:Boolean = false, param3:Boolean = false) : void
      {
         fileLogEnabled = param2;
         overlayEnabled = param3;
         if(enabled == param1)
         {
            updateOverlayAttachment();
            return;
         }
         enabled = param1;
         if(enabled)
         {
            diagnosticsEpoch = getTimer();
            battleEpoch = -1;
            lastFlushAt = diagnosticsEpoch;
            proximityLastStatusAt = -1;
            proximityPacketsSentTotal = 0;
            proximityLastLocalRejectionReason = null;
            if(hasActiveWork())
            {
               startTimer();
            }
         }
         else
         {
            stopTimer();
            removeOverlay();
            logger.flush();
            sessions = new Dictionary();
            regions = new Dictionary();
            regionSourceHints = new Dictionary();
            catalogTypes = new Dictionary();
            latestBonusId = null;
            latestLocalAttemptBonusId = null;
            pendingRequests = new Dictionary();
            sessionCount = 0;
            sessionCapOverflowLogged = false;
            shadowTargetNearby = false;
            airborneTargetNearby = false;
            airborneTrackedBonusId = null;
            lastOverlayAt = -1;
            diagnosticsEpoch = -1;
            battleEpoch = -1;
            proximityLastStatusAt = -1;
            proximityPacketsSentTotal = 0;
            proximityLastLocalRejectionReason = null;
         }
      }

      public static function beginBattle() : void
      {
         if(!enabled)
         {
            return;
         }
         battleEpoch = getTimer();
         catalogTypes = new Dictionary();
         regionSourceHints = new Dictionary();
         sessionCapOverflowLogged = false;
         shadowTargetNearby = false;
         airborneTargetNearby = false;
         airborneTrackedBonusId = null;
         lastOverlayAt = -1;
         proximityLastStatusAt = -1;
         logRaw("bonusId=unbound event=BATTLE_DIAGNOSTICS_BEGIN");
      }

      public static function canonicalFromLong(param1:Long) : String
      {
         var _loc2_:String = null;
         if(param1 == null)
         {
            return "long:null";
         }
         _loc2_ = LongUtils.idToStr(param1);
         if(_loc2_ != null && _loc2_.length > 0)
         {
            return _loc2_;
         }
         return String(param1.high) + ":" + String(param1.low);
      }

      public static function canonicalBonusId(param1:String, param2:Long = null) : String
      {
         if(param1 != null && param1.length > 0)
         {
            return param1;
         }
         return canonicalFromLong(param2);
      }

      public static function baseBonusId(param1:String) : String
      {
         var _loc2_:int = 0;
         if(param1 == null)
         {
            return "";
         }
         _loc2_ = param1.indexOf("#");
         return _loc2_ < 0 ? param1 : param1.substring(0,_loc2_);
      }

      public static function isGoldCandidate(param1:String, param2:String) : Boolean
      {
         return hasGoldToken(baseBonusId(param1)) || hasGoldToken(param2);
      }

      public static function classificationReason(param1:String, param2:String) : String
      {
         if(hasGoldToken(baseBonusId(param1)))
         {
            return "raw_base_gold_token";
         }
         if(hasGoldToken(param2))
         {
            return "object_name_gold_token";
         }
         return "no_gold_token";
      }

      private static function classifyTarget(param1:String, param2:String) : Object
      {
         var _loc3_:String = normalizeIdentifier(param1);
         var _loc4_:String = normalizeIdentifier(param2);
         var _loc5_:String = exactCrystalTarget(_loc3_);
         var _loc6_:String = exactCrystalTarget(_loc4_);
         var _loc7_:String = null;
         var _loc8_:String = null;
         if(_loc5_ != null)
         {
            _loc7_ = _loc5_;
            _loc8_ = _loc6_ != null && _loc6_ != _loc5_ ? "exact_base_precedence_object_mismatch" : "exact_base_id";
         }
         else if(_loc6_ != null)
         {
            _loc7_ = _loc6_;
            _loc8_ = "exact_object_name";
         }
         else if(isGoldCandidate(_loc3_,_loc4_))
         {
            _loc7_ = TARGET_GOLD_VARIANT;
            _loc8_ = classificationReason(_loc3_,_loc4_);
         }
         else
         {
            _loc8_ = "not_selected_target";
         }
         return {
            kind:_loc7_,
            selected:isTargetEnabled(_loc7_) || proximityCollectEnabled && _loc7_ == TARGET_NORMAL_CRYSTAL,
            reason:_loc8_,
            baseId:_loc3_,
            objectName:_loc4_
         };
      }

      private static function exactCrystalTarget(param1:String) : String
      {
         if(param1 == "crystal")
         {
            return TARGET_NORMAL_CRYSTAL;
         }
         if(param1 == "crystal_100")
         {
            return TARGET_CRYSTAL_100_VARIANT;
         }
         return null;
      }

      private static function isTargetEnabled(param1:String) : Boolean
      {
         if(param1 == TARGET_GOLD_VARIANT)
         {
            return traceGoldVariants;
         }
         if(param1 == TARGET_NORMAL_CRYSTAL)
         {
            return traceNormalCrystal;
         }
         if(param1 == TARGET_CRYSTAL_100_VARIANT)
         {
            return traceCrystal100Variant;
         }
         return false;
      }

      public static function recordBonusTypeCatalog(param1:String, param2:String, param3:Object, param4:Object, param5:Object, param6:Object) : void
      {
         var _loc7_:String = normalizeIdentifier(param1);
         if(!enabled || _loc7_.length == 0 || catalogTypes[_loc7_])
         {
            return;
         }
         var _loc8_:Object = classifyTarget(_loc7_,param2);
         catalogTypes[_loc7_] = {
            baseId:_loc7_,
            objectName:param2,
            resourceId:safeValue(param3)
         };
         logRaw("bonusId=unbound event=BONUS_TYPE_CATALOG baseId=" + safe(_loc7_) + " objectName=" + safe(param2) + " resourceId=" + safeValue(param3) + " parachuteResource=" + safeValue(param4) + " parachuteInnerResource=" + safeValue(param5) + " pickupSoundResource=" + safeValue(param6) + " targetKind=" + safe(_loc8_.kind) + " targetSelected=" + bool(_loc8_.selected) + " classificationReason=" + safe(_loc8_.reason));
      }

      public static function recordRawBonusAdd(param1:String, param2:Long, param3:Number, param4:Number, param5:Number, param6:String, param7:Boolean, param8:String, param9:Boolean = true) : Boolean
      {
         var _loc10_:String = null;
         var _loc11_:String = null;
         var _loc12_:Object = null;
         var _loc13_:String = null;
         var _loc14_:GoldBoxDiagnosticSession = null;
         if(!enabled)
         {
            return false;
         }
         _loc10_ = canonicalBonusId(param1,param2);
         _loc11_ = baseBonusId(param1 != null && param1.length > 0 ? param1 : _loc10_);
         _loc12_ = classifyTarget(_loc11_,param6);
         _loc13_ = _loc12_.reason;
         if(param9 || _loc12_.selected || !param7 || traceGoldVariants)
         {
            logRaw("bonusId=" + safe(_loc10_) + " event=RAW_BONUS_ADD source=" + safe(param8) + " rawBonusId=" + safe(param1) + " baseId=" + safe(_loc11_) + " longHigh=" + longHigh(param2) + " longLow=" + longLow(param2) + " canonicalId=" + safe(_loc10_) + " position=" + position(true,param3,param4,param5) + " objectResolved=" + bool(param7) + " objectName=" + safe(param6) + " targetKind=" + safe(_loc12_.kind) + " targetSelected=" + bool(_loc12_.selected) + " classificationReason=" + safe(_loc13_));
         }
         if(_loc12_.selected)
         {
            _loc14_ = getOrCreateSession(_loc10_,param6);
            applyTargetMetadata(_loc14_,_loc12_);
            _loc14_.hasSpawnPosition = true;
            _loc14_.spawnX = param3;
            _loc14_.spawnY = param4;
            _loc14_.spawnZ = param5;
            _loc14_.lifecycleState = "SPAWN_PACKET";
            latestBonusId = _loc10_;
            logSession(_loc14_,"TARGET_SPAWN_CLASSIFIED","source=" + safe(param8) + " classificationReason=" + safe(_loc13_));
            if(_loc14_.targetKind == TARGET_GOLD_VARIANT)
            {
               bindSession(_loc14_);
            }
            ensureTimer();
         }
         return _loc12_.selected;
      }

      public static function recordModelSpawnEntry(param1:Long, param2:String, param3:Number, param4:Number, param5:Number, param6:int, param7:Boolean) : String
      {
         var _loc8_:String = canonicalFromLong(param1);
         var _loc9_:Object = classifyTarget(baseBonusId(_loc8_),param2);
         if(!enabled)
         {
            return _loc8_;
         }
         if(traceGoldVariants || _loc9_.selected)
         {
            logRaw("bonusId=" + safe(_loc8_) + " event=MODEL_SPAWN_ENTRY rawBonusId=" + safe(param1 == null ? null : LongUtils.idToStr(param1)) + " baseId=" + safe(baseBonusId(_loc8_)) + " longHigh=" + longHigh(param1) + " longLow=" + longLow(param1) + " objectName=" + safe(param2) + " targetKind=" + safe(_loc9_.kind) + " targetSelected=" + bool(_loc9_.selected) + " classificationReason=" + safe(_loc9_.reason) + " lifeTime=" + param6 + " onGround=" + bool(param7));
         }
         if(_loc9_.selected)
         {
            confirmTargetBonus(_loc8_,param2,param3,param4,param5,_loc9_);
         }
         return _loc8_;
      }

      public static function recordRawResponse(param1:String, param2:String, param3:Long, param4:Boolean) : void
      {
         var _loc5_:String = canonicalBonusId(param2,param3);
         if(!enabled)
         {
            return;
         }
         logRaw("bonusId=" + safe(_loc5_) + " event=" + param1 + " rawBonusId=" + safe(param2) + " canonicalId=" + safe(_loc5_) + " longHigh=" + longHigh(param3) + " longLow=" + longLow(param3) + " sessionExists=" + bool(sessions[_loc5_] != null) + " modelExistsBefore=" + bool(param4));
      }

      public static function recordGlobalEvent(param1:String, param2:String = "") : void
      {
         if(enabled && (traceGoldVariants || param1 == null || param1.indexOf("GOLD_") != 0))
         {
            logRaw("bonusId=unbound event=" + param1 + (param2.length > 0 ? " " + param2 : ""));
         }
      }

      public static function noteDropZoneSource(param1:String, param2:String, param3:String, param4:Number, param5:Number, param6:Number, param7:String) : void
      {
         if(!enabled || !traceGoldVariants || param1 == null)
         {
            return;
         }
         regionSourceHints[param1] = param2;
         logRaw("bonusId=unbound event=" + param7 + " regionKey=" + safe(param1) + " source=" + safe(param2) + " regionType=" + safe(param3) + " position=" + position(true,param4,param5,param6));
      }

      public static function consumeDropZoneSource(param1:String, param2:String = "unknown") : String
      {
         var _loc3_:String = regionSourceHints[param1];
         if(_loc3_ == null)
         {
            return param2;
         }
         delete regionSourceHints[param1];
         return _loc3_;
      }

      public static function setOutputModes(param1:Boolean, param2:Boolean) : void
      {
         fileLogEnabled = param1;
         overlayEnabled = param2;
         if(!fileLogEnabled)
         {
            logger.clear();
         }
         updateOverlayAttachment();
      }

      public static function get isEnabled() : Boolean
      {
         return enabled;
      }

      public static function isTracking(param1:String) : Boolean
      {
         return enabled && param1 != null && sessions[param1] != null;
      }

      public static function isGoldType(param1:String) : Boolean
      {
         return hasGoldToken(param1);
      }

      public static function onDropZoneShow(param1:String, param2:String, param3:Number, param4:Number, param5:Number, param6:String = "unknown") : void
      {
         var _loc6_:Object = null;
         if(!enabled || !traceGoldVariants || !isGoldType(param2) || param1 == null)
         {
            return;
         }
         _loc6_ = {
            key:param1,
            type:param2,
            sourceX:param3,
            sourceY:param4,
            sourceZ:param5,
            hasGround:false,
            visible:true,
            boundBonusId:null,
            source:param6
         };
         regions[param1] = _loc6_;
         logUnboundRegion(_loc6_,"DROP_ZONE_SHOW");
         bindRegion(_loc6_);
         ensureTimer();
      }

      public static function onDropZoneGrounded(param1:String, param2:Number, param3:Number, param4:Number, param5:Number, param6:Number, param7:Number, param8:String = "unknown") : void
      {
         var _loc8_:Object = null;
         var _loc9_:GoldBoxDiagnosticSession = null;
         if(!enabled || !traceGoldVariants || param1 == null)
         {
            return;
         }
         _loc8_ = regions[param1];
         if(_loc8_ == null)
         {
            _loc8_ = {key:param1,type:"gold",sourceX:param2,sourceY:param3,sourceZ:param4,visible:true,boundBonusId:null,source:param8};
            regions[param1] = _loc8_;
         }
         if(_loc8_.source == null || _loc8_.source == "unknown")
         {
            _loc8_.source = param8;
         }
         _loc8_.hasGround = true;
         _loc8_.groundX = param5;
         _loc8_.groundY = param6;
         _loc8_.groundZ = param7;
         if(_loc8_.boundBonusId != null)
         {
            _loc9_ = sessions[_loc8_.boundBonusId];
            if(_loc9_ != null)
            {
               applyGroundPosition(_loc9_,_loc8_);
               logSession(_loc9_,"DROP_ZONE_GROUNDED");
            }
         }
         else
         {
            logUnboundRegion(_loc8_,"DROP_ZONE_GROUNDED");
            bindRegion(_loc8_);
         }
         ensureTimer();
      }

      public static function onDropZoneHide(param1:String) : void
      {
         var _loc2_:Object = null;
         var _loc3_:GoldBoxDiagnosticSession = null;
         if(!enabled || !traceGoldVariants || param1 == null)
         {
            return;
         }
         _loc2_ = regions[param1];
         if(_loc2_ != null)
         {
            _loc2_.visible = false;
            if(_loc2_.boundBonusId != null)
            {
               _loc3_ = sessions[_loc2_.boundBonusId];
               if(_loc3_ != null)
               {
                  logSession(_loc3_,"DROP_ZONE_HIDE");
               }
            }
            else
            {
               logUnboundRegion(_loc2_,"DROP_ZONE_HIDE");
            }
            delete regions[param1];
         }
         stopTimerIfIdle();
      }

      public static function onSpawnPacket(param1:String, param2:String, param3:Number, param4:Number, param5:Number, param6:String) : void
      {
         var _loc7_:GoldBoxDiagnosticSession = null;
         if(!enabled || !traceGoldVariants || param1 == null || !isGoldType(param2))
         {
            return;
         }
         _loc7_ = getOrCreateSession(param1,param2);
         _loc7_.hasSpawnPosition = true;
         _loc7_.spawnX = param3;
         _loc7_.spawnY = param4;
         _loc7_.spawnZ = param5;
         _loc7_.lifecycleState = "SPAWN_PACKET";
         latestBonusId = param1;
         logSession(_loc7_,"SPAWN_PACKET_RECEIVED","source=" + safe(param6));
         bindSession(_loc7_);
         ensureTimer();
      }

      public static function onBatchSpawnPacket(param1:int, param2:int, param3:int = 0, param4:int = 0) : void
      {
         if(!enabled)
         {
            return;
         }
         logRaw("bonusId=batch event=ADD_BONUS_BOXES_PARSED parsedCount=" + param1 + " dispatchedCount=" + param2 + " selectedTargetCount=" + param3 + " unresolvedCount=" + param4);
      }

      private static function confirmTargetBonus(param1:String, param2:String, param3:Number, param4:Number, param5:Number, param6:Object) : void
      {
         var _loc6_:GoldBoxDiagnosticSession = null;
         if(!enabled || param1 == null || param6 == null || !param6.selected)
         {
            return;
         }
         _loc6_ = getOrCreateSession(param1,param2);
         applyTargetMetadata(_loc6_,param6);
         _loc6_.hasSpawnPosition = true;
         _loc6_.spawnX = param3;
         _loc6_.spawnY = param4;
         _loc6_.spawnZ = param5;
         _loc6_.lifecycleState = "CREATING";
         latestBonusId = param1;
         logSession(_loc6_,"TARGET_TYPE_CONFIRMED");
         if(_loc6_.targetKind == TARGET_GOLD_VARIANT)
         {
            bindSession(_loc6_);
         }
         ensureTimer();
      }

      public static function lifecycle(param1:String, param2:String, param3:String = null) : void
      {
         var _loc4_:GoldBoxDiagnosticSession = null;
         var _loc5_:int = 0;
         var _loc6_:String = null;
         if(!enabled || param1 == null)
         {
            return;
         }
         _loc4_ = sessions[param1];
         if(_loc4_ == null)
         {
            return;
         }
         _loc6_ = _loc4_.lifecycleState;
         if(param2 == "LOCAL_TANK_COLLISION")
         {
            _loc4_.proximityLocalCollisionObserved = true;
            _loc4_.proximityLocalCollisionAt = getTimer();
         }
         if(param3 != null)
         {
            _loc4_.lifecycleState = param3;
         }
         if(param2 == "SPAWN_BRANCH_ON_GROUND")
         {
            invalidateAirborneMotion(_loc4_);
            _loc4_.groundTouched = true;
            _loc4_.awaitingGroundedPosition = true;
         }
         else if(param2 == "FALLING_STARTED")
         {
            invalidateAirborneMotion(_loc4_);
         }
         else if(param2 == "GROUND_TOUCH")
         {
            _loc5_ = getTimer();
            _loc4_.groundTouched = true;
            _loc4_.airborneGroundTouchAt = _loc5_;
            _loc4_.airborneCandidateTracking = false;
            if(_loc4_.hasBonusPosition)
            {
               setGroundedPosition(_loc4_,_loc4_.bonusX,_loc4_.bonusY,_loc4_.bonusZ);
            }
            logAirborneComparison(_loc4_,"ground_touch",_loc5_);
            invalidateAirborneMotion(_loc4_,true);
         }
         if((_loc6_ == "FALLING" && param3 == "LANDING") || param2 == "GROUND_TOUCH")
         {
            rearmProximityOnGroundTouch(_loc4_);
         }
         latestBonusId = param1;
         if(isImmediateSnapshotEvent(param2))
         {
            sampleLocalTank(_loc4_);
         }
         logSession(_loc4_,param2);
         ensureTimer();
      }

      public static function setModelExists(param1:String, param2:Boolean, param3:String) : void
      {
         var _loc4_:GoldBoxDiagnosticSession = sessions[param1];
         if(!enabled || _loc4_ == null)
         {
            return;
         }
         _loc4_.modelExists = param2;
         logSession(_loc4_,param3);
         if(param2 && proximityCollectEnabled && _loc4_.targetKind == TARGET_NORMAL_CRYSTAL)
         {
            _loc4_.proximityStopped = false;
            ensureTimer();
         }
      }

      public static function shouldCaptureBonusPosition(param1:String) : Boolean
      {
         var _loc2_:GoldBoxDiagnosticSession = null;
         var _loc3_:int = 0;
         if(!enabled)
         {
            return false;
         }
         _loc2_ = sessions[param1];
         if(_loc2_ == null)
         {
            return false;
         }
         _loc3_ = getTimer();
         _loc2_.proximityTriggerAt = _loc3_;
         return (_loc2_.localAttempt || _loc2_.shadowTracking || _loc2_.airborneCandidateTracking || _loc2_.proximityTracking) && (_loc2_.lastPositionSampleAt < 0 || _loc3_ - _loc2_.lastPositionSampleAt >= (_loc2_.shadowTracking || _loc2_.airborneCandidateTracking || _loc2_.proximityTracking ? Math.min(SHADOW_ACTIVE_INTERVAL_MS,proximityRetryIntervalMs) : TIMER_INTERVAL_MS));
      }

      public static function captureBonusPosition(param1:String, param2:Number, param3:Number, param4:Number, param5:Boolean = false) : void
      {
         var _loc6_:GoldBoxDiagnosticSession = sessions[param1];
         var _loc7_:int = 0;
         var _loc8_:String = null;
         if(!enabled || _loc6_ == null)
         {
            return;
         }
         _loc7_ = getTimer();
         _loc8_ = param5 ? "event_snapshot" : "render_sample";
         updateAirborneMotion(_loc6_,param2,param3,param4,_loc7_,_loc8_);
         _loc6_.hasBonusPosition = true;
         _loc6_.bonusX = param2;
         _loc6_.bonusY = param3;
         _loc6_.bonusZ = param4;
         _loc6_.lastPositionSampleAt = _loc7_;
         _loc6_.airbornePositionSource = _loc8_;
         if(_loc6_.groundTouched || _loc6_.awaitingGroundedPosition)
         {
            _loc6_.groundTouched = true;
            _loc6_.awaitingGroundedPosition = false;
            setGroundedPosition(_loc6_,param2,param3,param4);
         }
         updateDistance(_loc6_);
         if(param5)
         {
            logSession(_loc6_,"BONUS_POSITION_SNAPSHOT");
         }
      }

      public static function triggerEnabled(param1:String, param2:Boolean) : void
      {
         var _loc3_:GoldBoxDiagnosticSession = sessions[param1];
         if(!enabled || _loc3_ == null)
         {
            return;
         }
         _loc3_.triggerState = "enabled";
         logSession(_loc3_,param2 ? "TRIGGER_RE_ENABLED" : "TRIGGER_ENABLED");
         if(shadowRadiusProbeEnabled || airborneShadowCollectEnabled)
         {
            ensureTimer();
         }
      }

      public static function triggerActivated(param1:String) : void
      {
         var _loc2_:GoldBoxDiagnosticSession = sessions[param1];
         var _loc3_:int = 0;
         var _loc4_:String = null;
         if(!enabled || _loc2_ == null)
         {
            return;
         }
         _loc2_.triggerState = "activated";
         _loc2_.localAttempt = true;
         if(_loc2_.proximityAttemptsSent > 0)
         {
            _loc2_.proximityLocalCollisionObserved = true;
            logSession(_loc2_,"PROXIMITY_COLLECT_REAL_TRIGGER_AFTER_ATTEMPT","attemptsSent=" + _loc2_.proximityAttemptsSent);
         }
         latestLocalAttemptBonusId = param1;
         _loc3_ = getTimer();
         _loc4_ = _loc2_.lifecycleState;
         sampleLocalTank(_loc2_,true);
         updateAirborneMetrics(_loc2_);
         if(airborneShadowCollectEnabled)
         {
            _loc2_.airborneTriggerObserved = true;
            _loc2_.airborneRealTriggerAt = _loc3_;
            _loc2_.airborneRealTriggerLifecycle = _loc4_;
            _loc2_.airborneRealTriggerDistance = _loc2_.airborneDistance3D;
            if(isConfirmedAirborneEvidence(_loc2_,_loc3_))
            {
               evaluateAirborneThresholds(_loc2_,_loc3_,"at_trigger");
            }
            if(_loc4_ == "FALLING" && !_loc2_.groundTouched)
            {
               _loc2_.airborneRealTriggerBeforeGround = true;
               logRealTriggerBeforeGround(_loc2_,"detected",_loc3_,null);
            }
            logAirborneComparison(_loc2_,"real_trigger",_loc3_);
            _loc2_.airborneCandidateTracking = false;
         }
         if(shadowRadiusProbeEnabled && canCompleteShadowAtTrigger(_loc2_))
         {
            evaluateShadowThresholds(_loc2_,_loc3_,"at_trigger");
         }
         logSession(_loc2_,"TRIGGER_ACTIVATED");
         if(shadowRadiusProbeEnabled && canCompleteShadowAtTrigger(_loc2_))
         {
            logShadowTriggerComparison(_loc2_,_loc3_);
            _loc2_.shadowFinalized = true;
            _loc2_.shadowTracking = false;
         }
         ensureTimer();
      }

      public static function triggerDisabled(param1:String) : void
      {
         var _loc2_:GoldBoxDiagnosticSession = sessions[param1];
         if(!enabled || _loc2_ == null)
         {
            return;
         }
         _loc2_.triggerState = "disabled";
         logSession(_loc2_,"TRIGGER_DISABLED");
      }

      public static function collectPacketSendBegin(param1:String) : void
      {
         var _loc2_:GoldBoxDiagnosticSession = sessions[param1];
         if(!enabled || _loc2_ == null)
         {
            return;
         }
         if(proximitySendContextBonusId == param1)
         {
            sampleLocalTank(_loc2_,true);
            logSession(_loc2_,"PROXIMITY_COLLECT_PACKET_SEND_BEGIN","attemptNumber=" + proximitySendContextAttempt + proximityMetrics(_loc2_,getTimer()));
            return;
         }
         _loc2_.requestAt = getTimer();
         _loc2_.responseAt = -1;
         _loc2_.timedOut = false;
         _loc2_.terminal = false;
         _loc2_.cleanupPending = false;
         _loc2_.localAttempt = true;
         _loc2_.lifecycleState = "REQUEST_PENDING";
         pendingRequests[param1] = true;
         latestLocalAttemptBonusId = param1;
         sampleLocalTank(_loc2_);
         logSession(_loc2_,"COLLECT_PACKET_SEND_BEGIN");
         ensureTimer();
      }

      public static function collectPacketSendCallReturned(param1:String) : void
      {
         var _loc2_:GoldBoxDiagnosticSession = sessions[param1];
         if(!enabled || _loc2_ == null)
         {
            return;
         }
         if(proximitySendContextBonusId == param1)
         {
            sampleLocalTank(_loc2_,true);
            logSession(_loc2_,"PROXIMITY_COLLECT_PACKET_SEND_RETURNED","attemptNumber=" + proximitySendContextAttempt + proximityMetrics(_loc2_,getTimer()));
            return;
         }
         sampleLocalTank(_loc2_);
         logSession(_loc2_,"COLLECT_PACKET_SEND_CALL_RETURNED");
         ensureTimer();
      }

      public static function responseReceived(param1:String, param2:String) : void
      {
         var _loc3_:GoldBoxDiagnosticSession = sessions[param1];
         var _loc4_:int = 0;
         var _loc5_:String = null;
         if(!enabled || _loc3_ == null)
         {
            return;
         }
         finalizeShadowBeforeTrigger(_loc3_,param2);
         _loc4_ = getTimer();
         if(_loc3_.proximityAttemptsSent > 0)
         {
            if(param2 == "TAKE_RESPONSE")
            {
               _loc5_ = proximityTakeClassification(_loc3_);
               logSession(_loc3_,"PROXIMITY_COLLECT_TAKE_OBSERVED","attemptsSent=" + _loc3_.proximityAttemptsSent + " elapsedSinceFirstAttemptMs=" + elapsed(_loc3_.proximityFirstAttemptAt,_loc4_) + " elapsedSinceLastAttemptMs=" + elapsed(_loc3_.proximityLastAttemptAt,_loc4_) + " localCollisionObserved=" + bool(_loc3_.proximityLocalCollisionObserved) + " localCollisionBeforeTake=" + bool(_loc3_.proximityLocalCollisionAt >= 0 && _loc3_.proximityLocalCollisionAt <= _loc4_) + " triggerActivatedBeforeTake=" + bool(_loc3_.proximityTriggerAt >= 0 && _loc3_.proximityTriggerAt <= _loc4_) + " collectorAttribution=unknown classification=" + _loc5_);
               if(_loc5_ == "silent_server_ignore_until_collision")
               {
                  logSession(_loc3_,"PROXIMITY_SERVER_VALIDATION_SUSPECTED","attemptsSent=" + _loc3_.proximityAttemptsSent + " attemptDistances=" + safe(_loc3_.proximityAttemptDistances) + " elapsedFirstToCollisionMs=" + elapsed(_loc3_.proximityFirstAttemptAt,_loc3_.proximityLocalCollisionAt) + " elapsedCollisionToTakeMs=" + elapsed(_loc3_.proximityLocalCollisionAt,_loc4_));
               }
            }
            logSession(_loc3_,"PROXIMITY_COLLECT_RESULT","result=" + safe(param2) + " classification=" + safe(_loc5_ == null ? "response_observed" : _loc5_) + " attemptsSent=" + _loc3_.proximityAttemptsSent + " elapsedSinceFirstAttemptMs=" + elapsed(_loc3_.proximityFirstAttemptAt,_loc4_) + " elapsedSinceLastAttemptMs=" + elapsed(_loc3_.proximityLastAttemptAt,_loc4_) + " localCollisionObserved=" + bool(_loc3_.proximityLocalCollisionObserved) + " triggerActivated=" + bool(_loc3_.proximityTriggerAt >= 0) + " collectorAttribution=unknown evidence=circumstantial");
            logSession(_loc3_,"PROXIMITY_COLLECT_STOPPED","reason=" + safe(param2));
            _loc3_.proximityStopped = true;
            _loc3_.proximityTracking = false;
         }
         logAirborneResponse(_loc3_,param2,_loc4_);
         _loc3_.responseAt = _loc4_;
         _loc3_.terminal = true;
         _loc3_.cleanupPending = true;
         _loc3_.lifecycleState = param2;
         delete pendingRequests[param1];
         logSession(_loc3_,param2 + "_IN_PACKET");
         enforceSessionCap(false);
         stopTimerIfIdle();
      }

      public static function collectionFailed(param1:String) : void
      {
         var _loc2_:GoldBoxDiagnosticSession = sessions[param1];
         if(!enabled || _loc2_ == null)
         {
            return;
         }
         _loc2_.responseAt = getTimer();
         _loc2_.lifecycleState = "COLLECTION_FAILED";
         delete pendingRequests[param1];
         logSession(_loc2_,"FAILED_TANK_NOT_ACTIVE_CALLBACK");
         stopTimerIfIdle();
      }

      public static function destroyed(param1:String) : void
      {
         var _loc2_:GoldBoxDiagnosticSession = sessions[param1];
         if(!enabled || _loc2_ == null)
         {
            return;
         }
         finalizeShadowBeforeTrigger(_loc2_,"DESTROYED");
         logAirborneComparison(_loc2_,"destroy",getTimer());
         invalidateAirborneMotion(_loc2_);
         if(_loc2_.proximityAttemptsSent > 0 && !_loc2_.proximityStopped)
         {
            logSession(_loc2_,"PROXIMITY_COLLECT_STOPPED","reason=destroyed attemptsSent=" + _loc2_.proximityAttemptsSent);
         }
         _loc2_.modelExists = false;
         _loc2_.cleanupPending = false;
         logSession(_loc2_,"BONUS_DESTROYED");
         delete sessions[param1];
         delete pendingRequests[param1];
         sessionCount--;
         if(latestBonusId == param1)
         {
            latestBonusId = null;
         }
         if(latestLocalAttemptBonusId == param1)
         {
            latestLocalAttemptBonusId = null;
         }
         enforceSessionCap(false);
         stopTimerIfIdle();
      }

      public static function onBattleUnload() : void
      {
         var _loc1_:GoldBoxDiagnosticSession = null;
         if(!enabled)
         {
            return;
         }
         for each(_loc1_ in sessions)
         {
            logAirborneComparison(_loc1_,"unload",getTimer());
         }
         logRaw("bonusId=all event=BATTLE_UNLOAD");
         logger.flush();
         sessions = new Dictionary();
         regions = new Dictionary();
         regionSourceHints = new Dictionary();
         catalogTypes = new Dictionary();
         latestBonusId = null;
         latestLocalAttemptBonusId = null;
         pendingRequests = new Dictionary();
         sessionCount = 0;
         sessionCapOverflowLogged = false;
         battleEpoch = -1;
         shadowTargetNearby = false;
         airborneTargetNearby = false;
         airborneTrackedBonusId = null;
         unregisterProximityBridge();
         lastOverlayAt = -1;
         proximityLastStatusAt = -1;
         stopTimer();
         removeOverlay();
      }

      private static function getOrCreateSession(param1:String, param2:String) : GoldBoxDiagnosticSession
      {
         var _loc3_:GoldBoxDiagnosticSession = sessions[param1];
         if(_loc3_ == null)
         {
            enforceSessionCap(true);
            _loc3_ = new GoldBoxDiagnosticSession(param1,param2,getTimer());
            sessions[param1] = _loc3_;
            sessionCount++;
            if(sessionCount > MAX_RETAINED_SESSIONS && !sessionCapOverflowLogged)
            {
               sessionCapOverflowLogged = true;
               logRaw("bonusId=unbound event=SESSION_CAP_TEMPORARY_OVERFLOW retainedSessions=" + sessionCount);
            }
         }
         else if(param2 != null)
         {
            _loc3_.bonusType = param2;
         }
         return _loc3_;
      }

      private static function applyTargetMetadata(param1:GoldBoxDiagnosticSession, param2:Object) : void
      {
         var _loc3_:Object = null;
         param1.targetKind = param2.kind;
         param1.baseId = param2.baseId;
         param1.objectName = param2.objectName;
         _loc3_ = catalogTypes[param1.baseId];
         if(_loc3_ != null)
         {
            param1.resourceId = _loc3_.resourceId;
         }
      }

      private static function enforceSessionCap(param1:Boolean) : void
      {
         var _loc1_:GoldBoxDiagnosticSession = null;
         var _loc2_:GoldBoxDiagnosticSession = null;
         if(sessionCount < MAX_RETAINED_SESSIONS || !param1 && sessionCount <= MAX_RETAINED_SESSIONS)
         {
            if(sessionCount <= MAX_RETAINED_SESSIONS)
            {
               sessionCapOverflowLogged = false;
            }
            return;
         }
         for each(_loc1_ in sessions)
         {
            if(!_loc1_.localAttempt && _loc1_.requestAt < 0 && !_loc1_.cleanupPending && (_loc2_ == null || _loc1_.lastEventAt < _loc2_.lastEventAt))
            {
               _loc2_ = _loc1_;
            }
         }
         if(_loc2_ != null)
         {
            logSession(_loc2_,"SESSION_EVICTED_CAP");
            delete sessions[_loc2_.bonusId];
            sessionCount--;
            if(latestBonusId == _loc2_.bonusId)
            {
               latestBonusId = null;
            }
         }
      }

      private static function bindSession(param1:GoldBoxDiagnosticSession) : void
      {
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc4_:int = 0;
         if(!param1.hasSpawnPosition || param1.regionKey != null)
         {
            return;
         }
         for each(_loc2_ in regions)
         {
            if(_loc2_.visible && _loc2_.boundBonusId == null && _loc2_.sourceX == param1.spawnX && _loc2_.sourceY == param1.spawnY)
            {
               _loc3_ = _loc2_;
               _loc4_++;
            }
         }
         if(_loc4_ == 1)
         {
            bind(param1,_loc3_);
         }
         else if(_loc4_ > 1)
         {
            logSession(param1,"DROP_ZONE_BIND_AMBIGUOUS","exactMatches=" + _loc4_);
         }
      }

      private static function bindRegion(param1:Object) : void
      {
         var _loc2_:GoldBoxDiagnosticSession = null;
         var _loc3_:GoldBoxDiagnosticSession = null;
         var _loc4_:int = 0;
         if(param1.boundBonusId != null)
         {
            return;
         }
         for each(_loc2_ in sessions)
         {
            if(_loc2_.targetKind == TARGET_GOLD_VARIANT && !_loc2_.terminal && _loc2_.regionKey == null && _loc2_.hasSpawnPosition && _loc2_.spawnX == param1.sourceX && _loc2_.spawnY == param1.sourceY)
            {
               _loc3_ = _loc2_;
               _loc4_++;
            }
         }
         if(_loc4_ == 1)
         {
            bind(_loc3_,param1);
         }
         else if(_loc4_ > 1)
         {
            logUnboundRegion(param1,"DROP_ZONE_BIND_AMBIGUOUS","exactMatches=" + _loc4_);
         }
      }

      private static function bind(param1:GoldBoxDiagnosticSession, param2:Object) : void
      {
         param1.regionKey = param2.key;
         param2.boundBonusId = param1.bonusId;
         if(param2.hasGround)
         {
            applyGroundPosition(param1,param2);
         }
         logSession(param1,"DROP_ZONE_BOUND","regionKey=" + safe(param2.key) + " match=exactXY");
      }

      private static function applyGroundPosition(param1:GoldBoxDiagnosticSession, param2:Object) : void
      {
         param1.hasGroundPosition = true;
         param1.groundX = param2.groundX;
         param1.groundY = param2.groundY;
         param1.groundZ = param2.groundZ;
      }

      private static function onTimer(param1:TimerEvent) : void
      {
         var _loc2_:GoldBoxDiagnosticSession = null;
         var _loc3_:int = getTimer();
         var _loc4_:String = null;
         var _loc5_:Boolean = false;
         var _loc6_:Boolean = false;
         var _loc7_:Boolean = false;
         if(proximityCollectEnabled)
         {
            _loc7_ = runProximityCollect(_loc3_);
         }
         if(shadowRadiusProbeEnabled)
         {
            shadowTargetNearby = runShadowProbe(_loc3_);
            _loc5_ = shadowTargetNearby;
         }
         else
         {
            shadowTargetNearby = false;
         }
         if(airborneShadowCollectEnabled)
         {
            airborneTargetNearby = runAirborneProbe(_loc3_);
            _loc6_ = airborneTargetNearby;
         }
         else
         {
            airborneTargetNearby = false;
         }
         if(_loc5_ || _loc6_)
         {
            setTimerDelay(SHADOW_ACTIVE_INTERVAL_MS);
         }
         else if(shadowRadiusProbeEnabled || airborneShadowCollectEnabled)
         {
            setTimerDelay(SHADOW_DISCOVERY_INTERVAL_MS);
         }
         else
         {
            setTimerDelay(TIMER_INTERVAL_MS);
         }
         if(_loc7_ && timer != null)
         {
            setTimerDelay(Math.min(int(timer.delay),proximityRetryIntervalMs));
         }
         for(_loc4_ in pendingRequests)
         {
            _loc2_ = sessions[_loc4_];
            if(_loc2_ == null || _loc2_.terminal || _loc2_.requestAt < 0 || _loc2_.responseAt >= _loc2_.requestAt)
            {
               delete pendingRequests[_loc4_];
               continue;
            }
            if(_loc2_.lastRequestSampleAt < 0 || _loc3_ - _loc2_.lastRequestSampleAt >= TIMER_INTERVAL_MS)
            {
               _loc2_.lastRequestSampleAt = _loc3_;
               sampleLocalTank(_loc2_);
            }
            if(!_loc2_.timedOut && _loc3_ - _loc2_.requestAt >= RESPONSE_TIMEOUT_MS)
            {
               _loc2_.timedOut = true;
               _loc2_.lifecycleState = "TIMEOUT";
               logSession(_loc2_,"RESPONSE_TIMEOUT");
            }
            else if(_loc3_ - _loc2_.lastPeriodicLogAt >= PERIODIC_LOG_INTERVAL_MS)
            {
               _loc2_.lastPeriodicLogAt = _loc3_;
               logSession(_loc2_,"AWAITING_RESPONSE_SNAPSHOT");
            }
         }
         if(overlayEnabled && (lastOverlayAt < 0 || _loc3_ - lastOverlayAt >= TIMER_INTERVAL_MS))
         {
            lastOverlayAt = _loc3_;
            updateOverlay();
         }
         if(fileLogEnabled && _loc3_ - lastFlushAt >= FLUSH_INTERVAL_MS)
         {
            logger.flush();
            lastFlushAt = _loc3_;
         }
         if(proximityCollectEnabled && (proximityLastStatusAt < 0 || _loc3_ - proximityLastStatusAt >= 1000))
         {
            proximityLastStatusAt = _loc3_;
            logProximityStatus(_loc3_);
         }
         stopTimerIfIdle();
      }

      private static function runProximityCollect(param1:int) : Boolean
      {
         var _loc2_:LocalTankInfoService = OSGi.getInstance().getService(LocalTankInfoService) as LocalTankInfoService;
         var _loc3_:Tank = null;
         var _loc4_:Vector3 = null;
         var _loc5_:GoldBoxDiagnosticSession = null;
         var _loc6_:GoldBoxDiagnosticSession = null;
         var _loc7_:Object = null;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc11_:Number = NaN;
         var _loc12_:Number = NaN;
         var _loc13_:Boolean = false;
         var _loc14_:Boolean = false;
         var _loc15_:String = null;
         var _loc16_:int = 0;
         var _loc17_:Object = null;
         if(!enabled || !proximityCollectEnabled || proximityPositionReader == null || proximityAttemptRequester == null)
         {
            return false;
         }
         if(_loc2_ == null || !_loc2_.isLocalTankLoaded())
         {
            return hasProximitySession();
         }
         _loc3_ = _loc2_.getLocalTank();
         if(_loc3_ == null || _loc3_.state != ClientTankState.ACTIVE || _loc3_.getBody() == null || _loc3_.getBody().state.position == null)
         {
            return hasProximitySession();
         }
         _loc4_ = _loc3_.getBody().state.position;
         for each(_loc5_ in sessions)
         {
            _loc5_.proximityTracking = false;
            if(!isProximitySessionEligible(_loc5_))
            {
               continue;
            }
            _loc13_ = false;
            _loc15_ = null;
            if(_loc5_.lifecycleState == "FALLING")
            {
               _loc8_ = _loc5_.hasBonusPosition ? _loc5_.bonusX : _loc5_.spawnX;
               _loc9_ = _loc5_.hasBonusPosition ? _loc5_.bonusY : _loc5_.spawnY;
               _loc10_ = _loc4_.x - _loc8_;
               _loc11_ = _loc4_.y - _loc9_;
               if(_loc5_.proximityInRange || _loc5_.proximityExhausted && !_loc5_.proximityExitedRange || _loc10_ * _loc10_ + _loc11_ * _loc11_ <= (proximityMaxHorizontal + PROXIMITY_RANGE_HYSTERESIS) * (proximityMaxHorizontal + PROXIMITY_RANGE_HYSTERESIS))
               {
                  _loc5_.proximityTracking = true;
               }
               if(_loc5_.hasBonusPosition && _loc5_.airbornePositionSource == "render_sample" && param1 - _loc5_.lastPositionSampleAt <= PROXIMITY_FALLING_POSITION_MAX_AGE_MS && validPosition(_loc5_.bonusX,_loc5_.bonusY,_loc5_.bonusZ))
               {
                  proximityPositionBuffer.x = _loc5_.bonusX;
                  proximityPositionBuffer.y = _loc5_.bonusY;
                  proximityPositionBuffer.z = _loc5_.bonusZ;
                  _loc13_ = true;
                  _loc15_ = "render";
               }
            }
            else
            {
               _loc7_ = proximityPositionReader(_loc5_.bonusId,proximityPositionBuffer);
               _loc13_ = _loc7_ != null && Boolean(_loc7_.ok) && validPosition(proximityPositionBuffer.x,proximityPositionBuffer.y,proximityPositionBuffer.z);
               _loc15_ = _loc7_ == null ? null : String(_loc7_.source);
            }
            _loc5_.proximityPositionValid = _loc13_;
            _loc5_.proximityPositionSource = _loc15_;
            _loc5_.proximityHasLivePosition = _loc13_;
            if(!_loc13_)
            {
               continue;
            }
            _loc5_.bonusX = proximityPositionBuffer.x;
            _loc5_.bonusY = proximityPositionBuffer.y;
            _loc5_.bonusZ = proximityPositionBuffer.z;
            _loc5_.hasBonusPosition = true;
            _loc5_.proximityPositionAt = _loc5_.lifecycleState == "FALLING" ? _loc5_.lastPositionSampleAt : param1;
            applyTankSnapshot(_loc5_,_loc4_,_loc3_.getBody().state.velocity);
            updateProximityMetrics(_loc5_);
            _loc14_ = _loc5_.proximityDistance3D <= proximityCollectDistance && _loc5_.proximityHorizontalDistance <= proximityMaxHorizontal;
            updateProximityRangeState(_loc5_,_loc14_,param1);
            if(!_loc14_ || _loc5_.proximityExhausted || _loc5_.proximityBurstAttempts >= proximityMaxAttempts || param1 < _loc5_.proximityNextAttemptAt)
            {
               continue;
            }
            if(_loc6_ == null || _loc5_.proximityBurstAttempts < _loc6_.proximityBurstAttempts || _loc5_.proximityBurstAttempts == _loc6_.proximityBurstAttempts && _loc5_.proximityDistance3D < _loc6_.proximityDistance3D)
            {
               _loc6_ = _loc5_;
            }
         }
         if(_loc6_ != null)
         {
            _loc16_ = _loc6_.proximityAttemptsSent + 1;
            if(_loc6_.proximityAttemptsSent > 0)
            {
               logSession(_loc6_,"PROXIMITY_COLLECT_RETRY","attemptNumber=" + _loc16_ + " elapsedSincePreviousAttemptMs=" + elapsed(_loc6_.proximityLastAttemptAt,param1));
            }
            logSession(_loc6_,"PROXIMITY_COLLECT_ATTEMPT","attemptNumber=" + _loc16_ + proximityMetrics(_loc6_,param1));
            _loc17_ = proximityAttemptRequester(_loc6_.bonusId,_loc16_);
            if(_loc17_ == null || !Boolean(_loc17_.ok))
            {
               proximityLastLocalRejectionReason = _loc17_ == null ? "unknown" : String(_loc17_.reason);
               logSession(_loc6_,"PROXIMITY_COLLECT_REQUEST_REJECTED_LOCALLY","reason=" + safe(proximityLastLocalRejectionReason) + proximityMetrics(_loc6_,param1));
               logSession(_loc6_,"PROXIMITY_COLLECT_RESULT","classification=local_request_rejected reason=" + safe(proximityLastLocalRejectionReason) + " evidence=client_local");
            }
            else
            {
               ++_loc6_.proximityAttemptsSent;
               ++_loc6_.proximityBurstAttempts;
               if(_loc6_.proximityFirstAttemptAt < 0)
               {
                  _loc6_.proximityFirstAttemptAt = param1;
               }
               _loc6_.proximityLastAttemptAt = param1;
               _loc6_.proximityLastPacketBonusId = String(_loc17_.packetBonusId);
               if(_loc6_.proximityAttemptDistances.length > 0)
               {
                  _loc6_.proximityAttemptDistances += ",";
               }
               _loc6_.proximityAttemptDistances += number(_loc6_.proximityDistance3D);
               ++proximityPacketsSentTotal;
               logSession(_loc6_,"PROXIMITY_PACKET_ACTUALLY_SENT","attemptNumber=" + _loc16_ + " packetBonusId=" + safe(_loc6_.proximityLastPacketBonusId) + " sentAt=" + param1 + proximityMetrics(_loc6_,param1));
               _loc6_.proximityNextAttemptAt = param1 + proximityRetryIntervalMs;
               latestLocalAttemptBonusId = _loc6_.bonusId;
               if(_loc6_.proximityBurstAttempts >= proximityMaxAttempts)
               {
                  _loc6_.proximityExhausted = true;
                  if(!_loc6_.proximityExhaustionLogged)
                  {
                     _loc6_.proximityExhaustionLogged = true;
                     logSession(_loc6_,"PROXIMITY_COLLECT_ATTEMPTS_EXHAUSTED","burstAttempts=" + _loc6_.proximityBurstAttempts + " attemptsSent=" + _loc6_.proximityAttemptsSent);
                     logSession(_loc6_,"PROXIMITY_COLLECT_RESULT","classification=no_take_before_exhaustion attemptsSent=" + _loc6_.proximityAttemptsSent + " attemptDistances=" + safe(_loc6_.proximityAttemptDistances) + " evidence=client_observation");
                  }
               }
            }
         }
         return hasProximitySession();
      }

      private static function sampleLocalTank(param1:GoldBoxDiagnosticSession, param2:Boolean = false) : Boolean
      {
         var _loc2_:LocalTankInfoService = OSGi.getInstance().getService(LocalTankInfoService) as LocalTankInfoService;
         var _loc3_:Tank = null;
         var _loc4_:Vector3 = null;
         var _loc5_:Vector3 = null;
         if(_loc2_ == null || !_loc2_.isLocalTankLoaded())
         {
            return false;
         }
         _loc3_ = _loc2_.getLocalTank();
         if(_loc3_ == null || param2 && _loc3_.state != ClientTankState.ACTIVE || _loc3_.getBody() == null)
         {
            return false;
         }
         _loc4_ = _loc3_.getBody().state.position;
         if(_loc4_ == null)
         {
            return false;
         }
         _loc5_ = _loc3_.getBody().state.velocity;
         applyTankSnapshot(param1,_loc4_,_loc5_);
         return true;
      }

      private static function runShadowProbe(param1:int) : Boolean
      {
         var _loc2_:LocalTankInfoService = OSGi.getInstance().getService(LocalTankInfoService) as LocalTankInfoService;
         var _loc3_:Tank = null;
         var _loc4_:Vector3 = null;
         var _loc5_:Vector3 = null;
         var _loc6_:GoldBoxDiagnosticSession = null;
         var _loc7_:GoldBoxDiagnosticSession = null;
         var _loc8_:GoldBoxDiagnosticSession = null;
         var _loc9_:Number = Number.MAX_VALUE;
         var _loc10_:Number = Number.MAX_VALUE;
         var _loc11_:Number = NaN;
         var _loc12_:Number = NaN;
         var _loc13_:Number = NaN;
         var _loc14_:Number = NaN;
         if(_loc2_ == null || !_loc2_.isLocalTankLoaded())
         {
            clearShadowTrackingFlags();
            return false;
         }
         _loc3_ = _loc2_.getLocalTank();
         if(_loc3_ == null || _loc3_.state != ClientTankState.ACTIVE || _loc3_.getBody() == null)
         {
            clearShadowTrackingFlags();
            return false;
         }
         _loc4_ = _loc3_.getBody().state.position;
         _loc5_ = _loc3_.getBody().state.velocity;
         if(_loc4_ == null)
         {
            clearShadowTrackingFlags();
            return false;
         }
         for each(_loc6_ in sessions)
         {
            _loc6_.shadowTracking = false;
            if(isShadowEligible(_loc6_))
            {
               _loc11_ = _loc4_.x - _loc6_.groundedX;
               _loc12_ = _loc4_.y - _loc6_.groundedY;
               _loc13_ = _loc4_.z - _loc6_.groundedZ;
               _loc14_ = _loc11_ * _loc11_ + _loc12_ * _loc12_ + _loc13_ * _loc13_;
               if(_loc14_ <= SHADOW_ACTIVE_RANGE_SQUARED)
               {
                  if(_loc14_ < _loc9_)
                  {
                     _loc8_ = _loc7_;
                     _loc10_ = _loc9_;
                     _loc7_ = _loc6_;
                     _loc9_ = _loc14_;
                  }
                  else if(_loc14_ < _loc10_)
                  {
                     _loc8_ = _loc6_;
                     _loc10_ = _loc14_;
                  }
               }
            }
         }
         if(_loc7_ != null)
         {
            evaluateShadowCandidate(_loc7_,_loc4_,_loc5_,param1);
         }
         if(_loc8_ != null)
         {
            evaluateShadowCandidate(_loc8_,_loc4_,_loc5_,param1);
         }
         return _loc7_ != null;
      }

      private static function evaluateShadowCandidate(param1:GoldBoxDiagnosticSession, param2:Vector3, param3:Vector3, param4:int) : void
      {
         param1.shadowTracking = true;
         param1.shadowObserved = true;
         applyTankSnapshot(param1,param2,param3);
         evaluateShadowThresholds(param1,param4,"sampled");
      }

      private static function applyTankSnapshot(param1:GoldBoxDiagnosticSession, param2:Vector3, param3:Vector3) : void
      {
         param1.hasTankPosition = true;
         param1.tankX = param2.x;
         param1.tankY = param2.y;
         param1.tankZ = param2.z;
         if(param3 != null)
         {
            param1.hasTankVelocity = true;
            param1.tankVelocityX = param3.x;
            param1.tankVelocityY = param3.y;
            param1.tankVelocityZ = param3.z;
            param1.shadowTankSpeed = Math.sqrt(param3.x * param3.x + param3.y * param3.y + param3.z * param3.z);
         }
         else
         {
            param1.hasTankVelocity = false;
         }
         updateDistance(param1);
         updateShadowMetrics(param1,param3);
      }

      private static function runAirborneProbe(param1:int) : Boolean
      {
         var _loc2_:LocalTankInfoService = OSGi.getInstance().getService(LocalTankInfoService) as LocalTankInfoService;
         var _loc3_:Tank = null;
         var _loc4_:Vector3 = null;
         var _loc5_:Vector3 = null;
         var _loc6_:GoldBoxDiagnosticSession = null;
         var _loc7_:GoldBoxDiagnosticSession = null;
         var _loc8_:Number = Number.MAX_VALUE;
         var _loc9_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc11_:Number = NaN;
         var _loc12_:Number = NaN;
         var _loc13_:Number = NaN;
         var _loc14_:Number = NaN;
         var _loc15_:String = null;
         var _loc16_:GoldBoxDiagnosticSession = null;
         if(_loc2_ == null || !_loc2_.isLocalTankLoaded())
         {
            clearAirborneTrackingFlags();
            return false;
         }
         _loc3_ = _loc2_.getLocalTank();
         if(_loc3_ == null || _loc3_.state != ClientTankState.ACTIVE || _loc3_.getBody() == null)
         {
            clearAirborneTrackingFlags();
            return false;
         }
         _loc4_ = _loc3_.getBody().state.position;
         _loc5_ = _loc3_.getBody().state.velocity;
         if(_loc4_ == null)
         {
            clearAirborneTrackingFlags();
            return false;
         }
         for each(_loc6_ in sessions)
         {
            _loc6_.airborneCandidateTracking = false;
            if(isAirborneCandidateEligible(_loc6_))
            {
               _loc13_ = hasValidLiveXY(_loc6_) ? _loc6_.bonusX : _loc6_.spawnX;
               _loc14_ = hasValidLiveXY(_loc6_) ? _loc6_.bonusY : _loc6_.spawnY;
               _loc9_ = _loc4_.x - _loc13_;
               _loc10_ = _loc4_.y - _loc14_;
               _loc12_ = _loc9_ * _loc9_ + _loc10_ * _loc10_;
               if(_loc12_ <= AIRBORNE_HORIZONTAL_ACTIVE_RANGE_SQUARED && _loc12_ < _loc8_)
               {
                  _loc7_ = _loc6_;
                  _loc8_ = _loc12_;
               }
            }
         }
         if(airborneTrackedBonusId != null && (_loc7_ == null || airborneTrackedBonusId != _loc7_.bonusId))
         {
            _loc16_ = sessions[airborneTrackedBonusId];
            if(_loc16_ != null)
            {
               _loc16_.airborneCandidateTracking = false;
               invalidateAirborneMotion(_loc16_,true);
            }
         }
         if(_loc7_ == null)
         {
            airborneTrackedBonusId = null;
            return false;
         }
         airborneTrackedBonusId = _loc7_.bonusId;
         _loc7_.airborneCandidateTracking = true;
         applyTankSnapshot(_loc7_,_loc4_,_loc5_);
         _loc15_ = hasValidLiveXY(_loc7_) ? "live_xy" : "spawn_xy";
         if(!_loc7_.airborneBootstrapLogged)
         {
            _loc7_.airborneBootstrapLogged = true;
            logSession(_loc7_,"AIRBORNE_BOOTSTRAP_SELECTED","positionSource=" + _loc15_ + " horizontalDistance=" + number(Math.sqrt(_loc8_)) + " hasLivePosition=" + bool(hasValidLiveXY(_loc7_)));
         }
         if(_loc7_.hasBonusPosition)
         {
            updateAirborneMetrics(_loc7_);
            if(isConfirmedAirborneEvidence(_loc7_,param1))
            {
               evaluateAirborneThresholds(_loc7_,param1,"sampled");
            }
         }
         return true;
      }

      private static function updateAirborneMotion(param1:GoldBoxDiagnosticSession, param2:Number, param3:Number, param4:Number, param5:int, param6:String) : void
      {
         var _loc7_:int = 0;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc11_:Number = NaN;
         if(!isFiniteNumber(param2) || !isFiniteNumber(param3) || !isFiniteNumber(param4))
         {
            invalidateAirborneMotion(param1);
            return;
         }
         if(param6 != "render_sample" || param1.lifecycleState != "FALLING" || param1.groundTouched || param1.terminal)
         {
            invalidateAirborneMotion(param1,true);
            return;
         }
         param1.airborneConfirmedDescending = false;
         if(param1.airborneMotionHasPrevious && param1.airbornePreviousSource == "render_sample")
         {
            _loc7_ = param5 - param1.airbornePreviousAt;
            _loc8_ = param2 - param1.airbornePreviousX;
            _loc9_ = param3 - param1.airbornePreviousY;
            _loc10_ = param4 - param1.airbornePreviousZ;
            _loc11_ = _loc8_ * _loc8_ + _loc9_ * _loc9_ + _loc10_ * _loc10_;
            if(_loc7_ >= AIRBORNE_MOTION_MIN_INTERVAL_MS && _loc7_ <= AIRBORNE_MOTION_MAX_INTERVAL_MS && _loc11_ <= AIRBORNE_MAX_SAMPLE_JUMP_SQUARED)
            {
               param1.airborneVerticalDelta = _loc10_;
               param1.airborneVerticalVelocity = _loc10_ * 1000 / _loc7_;
               param1.airborneConfirmedDescending = isFiniteNumber(param1.airborneVerticalVelocity) && param1.airborneVerticalVelocity < -AIRBORNE_DESCENT_MIN_SPEED;
               if(param1.airborneConfirmedDescending)
               {
                  param1.airborneLastConfirmedVerticalVelocity = param1.airborneVerticalVelocity;
                  param1.airborneLastConfirmedAt = param5;
               }
            }
         }
         param1.airborneMotionHasPrevious = true;
         param1.airbornePreviousX = param2;
         param1.airbornePreviousY = param3;
         param1.airbornePreviousZ = param4;
         param1.airbornePreviousAt = param5;
         param1.airbornePreviousSource = param6;
      }

      private static function updateAirborneMetrics(param1:GoldBoxDiagnosticSession) : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         if(!param1.hasTankPosition || !param1.hasBonusPosition)
         {
            return;
         }
         _loc2_ = param1.bonusX - param1.tankX;
         _loc3_ = param1.bonusY - param1.tankY;
         _loc4_ = param1.bonusZ - param1.tankZ;
         _loc5_ = Math.sqrt(_loc2_ * _loc2_ + _loc3_ * _loc3_);
         _loc6_ = Math.sqrt(_loc5_ * _loc5_ + _loc4_ * _loc4_);
         param1.airborneHorizontalDistance = _loc5_;
         param1.airborneDistance3D = _loc6_;
         param1.airborneVerticalSeparation = _loc4_;
         if(param1.hasTankVelocity)
         {
            param1.airborneTankSpeed = Math.sqrt(param1.tankVelocityX * param1.tankVelocityX + param1.tankVelocityY * param1.tankVelocityY + param1.tankVelocityZ * param1.tankVelocityZ);
            param1.airborneHorizontalClosingSpeed = _loc5_ > 0 ? (param1.tankVelocityX * _loc2_ + param1.tankVelocityY * _loc3_) / _loc5_ : NaN;
            param1.airborneRadialClosingSpeed3D = _loc6_ > 0 && param1.airborneConfirmedDescending ? (param1.tankVelocityX * _loc2_ + param1.tankVelocityY * _loc3_ + (param1.tankVelocityZ - param1.airborneVerticalVelocity) * _loc4_) / _loc6_ : NaN;
         }
      }

      private static function updateShadowMetrics(param1:GoldBoxDiagnosticSession, param2:Vector3) : void
      {
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         if(!param1.hasTankPosition || !param1.hasGroundedPosition)
         {
            return;
         }
         _loc3_ = param1.groundedX - param1.tankX;
         _loc4_ = param1.groundedY - param1.tankY;
         _loc5_ = param1.groundedZ - param1.tankZ;
         param1.shadowDistance = Math.sqrt(_loc3_ * _loc3_ + _loc4_ * _loc4_ + _loc5_ * _loc5_);
         if(param2 != null && param1.shadowDistance > 0)
         {
            param1.shadowClosingSpeed = (param2.x * _loc3_ + param2.y * _loc4_ + param2.z * _loc5_) / param1.shadowDistance;
         }
      }

      private static function setGroundedPosition(param1:GoldBoxDiagnosticSession, param2:Number, param3:Number, param4:Number) : void
      {
         if(isNaN(param2) || isNaN(param3) || isNaN(param4))
         {
            return;
         }
         param1.hasGroundedPosition = true;
         param1.groundedX = param2;
         param1.groundedY = param3;
         param1.groundedZ = param4;
         param1.groundedPositionAt = getTimer();
      }

      private static function isSessionTargetEnabled(param1:GoldBoxDiagnosticSession) : Boolean
      {
         return param1 != null && isTargetEnabled(param1.targetKind);
      }

      private static function isProximitySessionEligible(param1:GoldBoxDiagnosticSession) : Boolean
      {
         return proximityCollectEnabled && param1 != null && param1.targetKind == TARGET_NORMAL_CRYSTAL && param1.modelExists && !param1.terminal && !param1.proximityStopped;
      }

      private static function hasProximitySession() : Boolean
      {
         var _loc1_:GoldBoxDiagnosticSession = null;
         if(!enabled || !proximityCollectEnabled)
         {
            return false;
         }
         for each(_loc1_ in sessions)
         {
            if(isProximitySessionEligible(_loc1_))
            {
               return true;
            }
         }
         return false;
      }

      private static function clearProximityState(param1:GoldBoxDiagnosticSession) : void
      {
         if(param1 == null)
         {
            return;
         }
         param1.proximityTracking = false;
         param1.proximityInRange = false;
         param1.proximityExitedRange = false;
         param1.proximityOutsideTicks = 0;
         param1.proximityBurstAttempts = 0;
         param1.proximityExhausted = false;
         param1.proximityExhaustionLogged = false;
         param1.proximityNextAttemptAt = -1;
         param1.proximityStopped = true;
      }

      private static function rearmProximityOnGroundTouch(param1:GoldBoxDiagnosticSession) : void
      {
         if(param1 == null || param1.targetKind != TARGET_NORMAL_CRYSTAL || param1.proximityGroundTransitionSeen)
         {
            return;
         }
         param1.proximityGroundTransitionSeen = true;
         if(param1.proximityExhausted && !param1.proximityGroundRearmUsed)
         {
            param1.proximityGroundRearmUsed = true;
            rearmProximity(param1,"ground_touch");
         }
      }

      private static function rearmProximity(param1:GoldBoxDiagnosticSession, param2:String) : void
      {
         param1.proximityBurstAttempts = 0;
         param1.proximityExhausted = false;
         param1.proximityExhaustionLogged = false;
         param1.proximityNextAttemptAt = getTimer();
         param1.proximityStopped = false;
         logSession(param1,"PROXIMITY_COLLECT_REARMED","reason=" + param2 + " attemptsSent=" + param1.proximityAttemptsSent);
      }

      private static function updateProximityRangeState(param1:GoldBoxDiagnosticSession, param2:Boolean, param3:int) : void
      {
         var _loc4_:Boolean = param1.proximityDistance3D > proximityCollectDistance + PROXIMITY_RANGE_HYSTERESIS || param1.proximityHorizontalDistance > proximityMaxHorizontal + PROXIMITY_RANGE_HYSTERESIS;
         if(param2)
         {
            if(!param1.proximityInRange)
            {
               logSession(param1,"PROXIMITY_COLLECT_ENTERED_RANGE",proximityMetrics(param1,param3));
            }
            if(param1.proximityExitedRange)
            {
               if(param1.proximityExhausted)
               {
                  rearmProximity(param1,"range_reentry");
               }
               param1.proximityExitedRange = false;
            }
            param1.proximityInRange = true;
            param1.proximityOutsideTicks = 0;
         }
         else if(_loc4_)
         {
            ++param1.proximityOutsideTicks;
            if(param1.proximityOutsideTicks >= PROXIMITY_EXIT_TICKS && param1.proximityInRange)
            {
               param1.proximityInRange = false;
               param1.proximityExitedRange = true;
               logSession(param1,"PROXIMITY_COLLECT_EXITED_RANGE",proximityMetrics(param1,param3));
            }
         }
         else
         {
            param1.proximityOutsideTicks = 0;
         }
      }

      private static function updateProximityMetrics(param1:GoldBoxDiagnosticSession) : void
      {
         var _loc2_:Number = param1.bonusX - param1.tankX;
         var _loc3_:Number = param1.bonusY - param1.tankY;
         var _loc4_:Number = param1.bonusZ - param1.tankZ;
         param1.proximityHorizontalDistance = Math.sqrt(_loc2_ * _loc2_ + _loc3_ * _loc3_);
         param1.proximityDistance3D = Math.sqrt(_loc2_ * _loc2_ + _loc3_ * _loc3_ + _loc4_ * _loc4_);
         param1.proximityVerticalDelta = _loc4_;
         param1.distance = param1.proximityDistance3D;
      }

      private static function proximityMetrics(param1:GoldBoxDiagnosticSession, param2:int) : String
      {
         return " lifecycle=" + safe(param1.lifecycleState) + " distance3D=" + number(param1.proximityDistance3D) + " horizontalDistance=" + number(param1.proximityHorizontalDistance) + " verticalDelta=" + number(param1.proximityVerticalDelta) + " box=" + position(param1.proximityPositionValid,param1.bonusX,param1.bonusY,param1.bonusZ) + " tank=" + position(param1.hasTankPosition,param1.tankX,param1.tankY,param1.tankZ) + " modelExists=" + bool(param1.modelExists) + " trigger=" + safe(param1.triggerState) + " groundTouched=" + bool(param1.groundTouched) + " positionSource=" + safe(param1.proximityPositionSource) + " positionAgeMs=" + (param1.proximityPositionAt < 0 ? "unknown" : String(param2 - param1.proximityPositionAt)) + " hasLivePosition=" + bool(param1.proximityHasLivePosition) + " positionValid=" + bool(param1.proximityPositionValid) + " elapsedSincePreviousAttemptMs=" + elapsed(param1.proximityLastAttemptAt,param2);
      }

      private static function proximityTakeClassification(param1:GoldBoxDiagnosticSession) : String
      {
         if(param1.proximityLocalCollisionAt < 0)
         {
            return "take_before_local_collision";
         }
         if(param1.proximityFirstAttemptAt >= 0 && param1.proximityLocalCollisionAt >= param1.proximityFirstAttemptAt)
         {
            return "silent_server_ignore_until_collision";
         }
         return "take_after_local_collision";
      }

      private static function logProximityStatus(param1:int) : void
      {
         var _loc2_:GoldBoxDiagnosticSession = null;
         var _loc3_:GoldBoxDiagnosticSession = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Object = proximityRuntimeStatusProvider == null ? null : proximityRuntimeStatusProvider();
         var _loc7_:BattleService = OSGi.getInstance().getService(BattleService) as BattleService;
         var _loc8_:LocalTankInfoService = OSGi.getInstance().getService(LocalTankInfoService) as LocalTankInfoService;
         var _loc9_:Tank = null;
         var _loc10_:String = "not_loaded";
         for each(_loc2_ in sessions)
         {
            if(_loc2_.targetKind != TARGET_NORMAL_CRYSTAL || _loc2_.terminal)
            {
               continue;
            }
            ++_loc4_;
            if(isProximitySessionEligible(_loc2_) && _loc2_.proximityPositionValid && !_loc2_.proximityExhausted)
            {
               ++_loc5_;
            }
            if(_loc2_.proximityPositionValid && (_loc3_ == null || _loc2_.proximityDistance3D < _loc3_.proximityDistance3D))
            {
               _loc3_ = _loc2_;
            }
         }
         if(_loc8_ != null && _loc8_.isLocalTankLoaded())
         {
            _loc9_ = _loc8_.getLocalTank();
            _loc10_ = _loc9_ == null ? "missing" : String(_loc9_.state);
         }
         logRaw("bonusId=unbound event=PROXIMITY_COLLECT_STATUS enabled=" + bool(enabled && proximityCollectEnabled) + " bridgeRegistered=" + bool(proximityPositionReader != null && proximityAttemptRequester != null) + " modelBattleActive=" + bool(_loc6_ != null && Boolean(_loc6_.modelBattleActive)) + " battleServiceActive=" + bool(_loc7_ != null && _loc7_.isBattleActive()) + " tankLoaded=" + bool(_loc8_ != null && _loc8_.isLocalTankLoaded()) + " tankState=" + safe(_loc10_) + " activeNormalCrystalSessions=" + _loc4_ + " eligibleSessions=" + _loc5_ + " nearestBonusId=" + safe(_loc3_ == null ? null : _loc3_.bonusId) + " nearestDistance3D=" + number(_loc3_ == null ? NaN : _loc3_.proximityDistance3D) + " nearestHorizontalDistance=" + number(_loc3_ == null ? NaN : _loc3_.proximityHorizontalDistance) + " nearestLifecycle=" + safe(_loc3_ == null ? null : _loc3_.lifecycleState) + " nearestPositionSource=" + safe(_loc3_ == null ? null : _loc3_.proximityPositionSource) + " nearestPositionAgeMs=" + (_loc3_ == null || _loc3_.proximityPositionAt < 0 ? "unknown" : String(param1 - _loc3_.proximityPositionAt)) + " packetsSentTotal=" + proximityPacketsSentTotal + " lastLocalRejectionReason=" + safe(proximityLastLocalRejectionReason));
      }

      private static function isShadowEligible(param1:GoldBoxDiagnosticSession) : Boolean
      {
         return shadowRadiusProbeEnabled && isSessionTargetEnabled(param1) && param1.groundTouched && param1.hasGroundedPosition && !isNaN(param1.groundedX) && !isNaN(param1.groundedY) && !isNaN(param1.groundedZ) && !param1.terminal && !param1.shadowFinalized && param1.triggerState == "enabled";
      }

      private static function canCompleteShadowAtTrigger(param1:GoldBoxDiagnosticSession) : Boolean
      {
         return isSessionTargetEnabled(param1) && param1.groundTouched && param1.hasGroundedPosition && !param1.shadowFinalized;
      }

      private static function hasShadowEligibleSession() : Boolean
      {
         var _loc1_:GoldBoxDiagnosticSession = null;
         if(!shadowRadiusProbeEnabled)
         {
            return false;
         }
         for each(_loc1_ in sessions)
         {
            if(isShadowEligible(_loc1_))
            {
               return true;
            }
         }
         return false;
      }

      private static function clearShadowTrackingFlags() : void
      {
         var _loc1_:GoldBoxDiagnosticSession = null;
         for each(_loc1_ in sessions)
         {
            _loc1_.shadowTracking = false;
         }
      }

      private static function evaluateShadowThresholds(param1:GoldBoxDiagnosticSession, param2:int, param3:String) : void
      {
         if(isNaN(param1.shadowDistance))
         {
            return;
         }
         evaluateShadowThreshold(param1,450,param2,param3);
         evaluateShadowThreshold(param1,425,param2,param3);
         evaluateShadowThreshold(param1,400,param2,param3);
         evaluateShadowThreshold(param1,375,param2,param3);
         evaluateShadowThreshold(param1,350,param2,param3);
      }

      private static function evaluateShadowThreshold(param1:GoldBoxDiagnosticSession, param2:int, param3:int, param4:String) : void
      {
         if(param1.shadowDistance > param2 || getShadowThresholdAt(param1,param2) >= 0)
         {
            return;
         }
         setShadowThreshold(param1,param2,param3,param4);
         if(param1.shadowCrossingOrder.length > 0)
         {
            param1.shadowCrossingOrder += ",";
         }
         param1.shadowCrossingOrder += String(param2);
         param1.shadowObserved = true;
         logSession(param1,"SHADOW_RANGE_CROSSED","threshold=" + param2 + " crossingDetection=" + param4 + " shadowDistance=" + number(param1.shadowDistance) + " shadowTank=" + position(param1.hasTankPosition,param1.tankX,param1.tankY,param1.tankZ) + " shadowBox=" + position(param1.hasGroundedPosition,param1.groundedX,param1.groundedY,param1.groundedZ) + " tankSpeed=" + number(param1.shadowTankSpeed) + " closingSpeed=" + number(param1.shadowClosingSpeed) + (param4 == "sampled" ? " timeUntilActualTriggerMs=pending" : " leadTimeMs=unknown"));
      }

      private static function getShadowThresholdAt(param1:GoldBoxDiagnosticSession, param2:int) : int
      {
         switch(param2)
         {
            case 450:
               return param1.shadow450At;
            case 425:
               return param1.shadow425At;
            case 400:
               return param1.shadow400At;
            case 375:
               return param1.shadow375At;
            case 350:
               return param1.shadow350At;
            default:
               return -1;
         }
      }

      private static function getShadowThresholdDetection(param1:GoldBoxDiagnosticSession, param2:int) : String
      {
         switch(param2)
         {
            case 450:
               return param1.shadow450Detection;
            case 425:
               return param1.shadow425Detection;
            case 400:
               return param1.shadow400Detection;
            case 375:
               return param1.shadow375Detection;
            case 350:
               return param1.shadow350Detection;
            default:
               return null;
         }
      }

      private static function setShadowThreshold(param1:GoldBoxDiagnosticSession, param2:int, param3:int, param4:String) : void
      {
         switch(param2)
         {
            case 450:
               param1.shadow450At = param3;
               param1.shadow450Detection = param4;
               break;
            case 425:
               param1.shadow425At = param3;
               param1.shadow425Detection = param4;
               break;
            case 400:
               param1.shadow400At = param3;
               param1.shadow400Detection = param4;
               break;
            case 375:
               param1.shadow375At = param3;
               param1.shadow375Detection = param4;
               break;
            case 350:
               param1.shadow350At = param3;
               param1.shadow350Detection = param4;
         }
      }

      private static function shadowSince(param1:GoldBoxDiagnosticSession, param2:int, param3:int) : String
      {
         var _loc4_:int = getShadowThresholdAt(param1,param2);
         if(_loc4_ < 0 || getShadowThresholdDetection(param1,param2) != "sampled")
         {
            return "unknown";
         }
         return String(param3 - _loc4_);
      }

      private static function logShadowTriggerComparison(param1:GoldBoxDiagnosticSession, param2:int) : void
      {
         logSession(param1,"SHADOW_TRIGGER_COMPARISON","actualTriggerDistance=" + number(param1.shadowDistance) + " crossingOrder=" + safe(param1.shadowCrossingOrder) + " crossed450=" + bool(param1.shadow450At >= 0) + " sampled450=" + bool(param1.shadow450Detection == "sampled") + " since450Ms=" + shadowSince(param1,450,param2) + " crossed425=" + bool(param1.shadow425At >= 0) + " sampled425=" + bool(param1.shadow425Detection == "sampled") + " since425Ms=" + shadowSince(param1,425,param2) + " crossed400=" + bool(param1.shadow400At >= 0) + " sampled400=" + bool(param1.shadow400Detection == "sampled") + " since400Ms=" + shadowSince(param1,400,param2) + " crossed375=" + bool(param1.shadow375At >= 0) + " sampled375=" + bool(param1.shadow375Detection == "sampled") + " since375Ms=" + shadowSince(param1,375,param2) + " crossed350=" + bool(param1.shadow350At >= 0) + " sampled350=" + bool(param1.shadow350Detection == "sampled") + " since350Ms=" + shadowSince(param1,350,param2) + " tankSpeed=" + number(param1.shadowTankSpeed) + " closingSpeed=" + number(param1.shadowClosingSpeed) + " bonusPositionAgeMs=" + groundedPositionAge(param1,param2));
      }

      private static function finalizeShadowBeforeTrigger(param1:GoldBoxDiagnosticSession, param2:String) : void
      {
         var _loc3_:int = getTimer();
         if(!shadowRadiusProbeEnabled || param1.shadowFinalized || !param1.shadowObserved || param1.localAttempt)
         {
            return;
         }
         logSession(param1,"SHADOW_TARGET_TERMINATED_BEFORE_TRIGGER","result=" + safe(param2) + " crossed=" + safe(param1.shadowCrossingOrder) + " elapsedSince450Ms=" + (param1.shadow450At < 0 ? "unknown" : String(_loc3_ - param1.shadow450At)));
         param1.shadowFinalized = true;
         param1.shadowTracking = false;
      }

      private static function groundedPositionAge(param1:GoldBoxDiagnosticSession, param2:int) : String
      {
         return param1.groundedPositionAt < 0 ? "unknown" : String(param2 - param1.groundedPositionAt);
      }

      private static function clearShadowState(param1:GoldBoxDiagnosticSession) : void
      {
         param1.shadowTracking = false;
         param1.shadowObserved = false;
         param1.shadowFinalized = false;
         param1.shadowCrossingOrder = "";
         param1.shadowDistance = NaN;
         param1.shadowTankSpeed = NaN;
         param1.shadowClosingSpeed = NaN;
         param1.shadow450At = -1;
         param1.shadow425At = -1;
         param1.shadow400At = -1;
         param1.shadow375At = -1;
         param1.shadow350At = -1;
         param1.shadow450Detection = null;
         param1.shadow425Detection = null;
         param1.shadow400Detection = null;
         param1.shadow375Detection = null;
         param1.shadow350Detection = null;
      }

      private static function isAirborneCandidateEligible(param1:GoldBoxDiagnosticSession) : Boolean
      {
         return airborneShadowCollectEnabled && isSessionTargetEnabled(param1) && param1.bonusId != null && param1.bonusId.length > 0 && param1.lifecycleState == "FALLING" && !param1.groundTouched && (hasValidLiveXY(param1) || hasValidSpawnXY(param1)) && !param1.terminal && !param1.airborneTriggerObserved && param1.triggerState != "disabled" && param1.triggerState != "activated";
      }

      private static function hasValidLiveXY(param1:GoldBoxDiagnosticSession) : Boolean
      {
         return param1.hasBonusPosition && isFiniteNumber(param1.bonusX) && isFiniteNumber(param1.bonusY);
      }

      private static function hasValidSpawnXY(param1:GoldBoxDiagnosticSession) : Boolean
      {
         return param1.hasSpawnPosition && isFiniteNumber(param1.spawnX) && isFiniteNumber(param1.spawnY);
      }

      private static function hasAirborneCandidateSession() : Boolean
      {
         var _loc1_:GoldBoxDiagnosticSession = null;
         if(!airborneShadowCollectEnabled)
         {
            return false;
         }
         for each(_loc1_ in sessions)
         {
            if(isAirborneCandidateEligible(_loc1_))
            {
               return true;
            }
         }
         return false;
      }

      private static function clearAirborneTrackingFlags() : void
      {
         var _loc1_:GoldBoxDiagnosticSession = null;
         for each(_loc1_ in sessions)
         {
            if(_loc1_.airborneCandidateTracking)
            {
               invalidateAirborneMotion(_loc1_,true);
            }
            _loc1_.airborneCandidateTracking = false;
         }
         airborneTrackedBonusId = null;
      }

      private static function isConfirmedAirborneEvidence(param1:GoldBoxDiagnosticSession, param2:int) : Boolean
      {
         return airborneShadowCollectEnabled && isSessionTargetEnabled(param1) && param1.lifecycleState == "FALLING" && !param1.groundTouched && !param1.terminal && param1.airborneConfirmedDescending && param1.airbornePreviousSource == "render_sample" && param1.airborneMotionHasPrevious && param1.lastPositionSampleAt >= 0 && param2 - param1.lastPositionSampleAt <= AIRBORNE_POSITION_MAX_AGE_MS && param1.airborneLastConfirmedAt >= 0 && param2 - param1.airborneLastConfirmedAt <= AIRBORNE_POSITION_MAX_AGE_MS;
      }

      private static function evaluateAirborneThresholds(param1:GoldBoxDiagnosticSession, param2:int, param3:String) : void
      {
         if(!isConfirmedAirborneEvidence(param1,param2) || isNaN(param1.airborneDistance3D))
         {
            return;
         }
         evaluateAirborneThreshold(param1,450,param2,param3);
         evaluateAirborneThreshold(param1,400,param2,param3);
         evaluateAirborneThreshold(param1,350,param2,param3);
      }

      private static function evaluateAirborneThreshold(param1:GoldBoxDiagnosticSession, param2:int, param3:int, param4:String) : void
      {
         if(param1.airborneDistance3D > param2 || getAirborneThresholdAt(param1,param2) >= 0)
         {
            return;
         }
         setAirborneThreshold(param1,param2,param3,param4);
         if(param1.airborneCrossingOrder.length > 0)
         {
            param1.airborneCrossingOrder += ",";
         }
         param1.airborneCrossingOrder += String(param2);
         param1.airborneObserved = true;
         logSession(param1,"AIRBORNE_SHADOW_COLLECT_ELIGIBLE","threshold=" + param2 + " crossingDetection=" + param4 + " distance3D=" + number(param1.airborneDistance3D) + " horizontalDistance=" + number(param1.airborneHorizontalDistance) + " verticalDelta=" + number(param1.airborneVerticalSeparation) + " distance=" + number(param1.airborneDistance3D) + " tank=" + position(param1.hasTankPosition,param1.tankX,param1.tankY,param1.tankZ) + " box=" + position(param1.hasBonusPosition,param1.bonusX,param1.bonusY,param1.bonusZ) + " bonusZ=" + number(param1.bonusZ) + " tankSpeed=" + number(param1.airborneTankSpeed) + " radialClosingSpeed3D=" + number(param1.airborneRadialClosingSpeed3D) + " horizontalClosingSpeed=" + number(param1.airborneHorizontalClosingSpeed) + " bonusVerticalVelocity=" + number(param1.airborneVerticalVelocity) + " groundTouched=" + bool(param1.groundTouched) + " positionAgeMs=" + airbornePositionAge(param1,param3) + " positionSource=" + safe(param1.airbornePositionSource) + (param4 == "at_trigger" ? " leadTimeMs=unknown" : " timeUntilActualTriggerMs=pending"));
      }

      private static function getAirborneThresholdAt(param1:GoldBoxDiagnosticSession, param2:int) : int
      {
         switch(param2)
         {
            case 450:
               return param1.airborne450At;
            case 400:
               return param1.airborne400At;
            case 350:
               return param1.airborne350At;
            default:
               return -1;
         }
      }

      private static function setAirborneThreshold(param1:GoldBoxDiagnosticSession, param2:int, param3:int, param4:String) : void
      {
         switch(param2)
         {
            case 450:
               param1.airborne450At = param3;
               param1.airborne450Detection = param4;
               break;
            case 400:
               param1.airborne400At = param3;
               param1.airborne400Detection = param4;
               break;
            case 350:
               param1.airborne350At = param3;
               param1.airborne350Detection = param4;
         }
      }

      private static function firstAirborneThresholdAt(param1:GoldBoxDiagnosticSession) : int
      {
         var _loc2_:int = -1;
         if(param1.airborne450At >= 0)
         {
            _loc2_ = param1.airborne450At;
         }
         if(param1.airborne400At >= 0 && (_loc2_ < 0 || param1.airborne400At < _loc2_))
         {
            _loc2_ = param1.airborne400At;
         }
         if(param1.airborne350At >= 0 && (_loc2_ < 0 || param1.airborne350At < _loc2_))
         {
            _loc2_ = param1.airborne350At;
         }
         return _loc2_;
      }

      private static function firstAirborneThreshold(param1:GoldBoxDiagnosticSession) : String
      {
         if(param1.airborneCrossingOrder == null || param1.airborneCrossingOrder.length == 0)
         {
            return "none";
         }
         var _loc2_:int = param1.airborneCrossingOrder.indexOf(",");
         return _loc2_ < 0 ? param1.airborneCrossingOrder : param1.airborneCrossingOrder.substr(0,_loc2_);
      }

      private static function elapsedFromAirborneFirst(param1:GoldBoxDiagnosticSession, param2:int) : String
      {
         var _loc3_:int = firstAirborneThresholdAt(param1);
         return _loc3_ < 0 || param2 < 0 ? "pending" : String(param2 - _loc3_);
      }

      private static function logRealTriggerBeforeGround(param1:GoldBoxDiagnosticSession, param2:String, param3:int, param4:String) : void
      {
         var _loc5_:Boolean = param1.requestAt >= 0;
         var _loc6_:String = _loc5_ && param2 == "response" ? String(param3 - param1.requestAt) : "unknown";
         logSession(param1,"REAL_TRIGGER_BEFORE_GROUND_TOUCH","phase=" + param2 + " evidenceQuality=" + (isConfirmedAirborneEvidence(param1,param3) ? "confirmed_descending" : "unconfirmed_or_stale") + " lifecycleAtTrigger=" + safe(param1.airborneRealTriggerLifecycle) + " distance3D=" + number(param1.airborneDistance3D) + " horizontalDistance=" + number(param1.airborneHorizontalDistance) + " verticalDelta=" + number(param1.airborneVerticalSeparation) + " box=" + position(param1.hasBonusPosition,param1.bonusX,param1.bonusY,param1.bonusZ) + " positionAgeMs=" + airbornePositionAge(param1,param3) + " positionSource=" + safe(param1.airbornePositionSource) + " bonusVerticalVelocity=" + number(param1.airborneLastConfirmedVerticalVelocity) + " localRequest=" + bool(_loc5_) + " response=" + safe(param4) + " collectResponseLatencyMs=" + _loc6_);
      }

      private static function logAirborneResponse(param1:GoldBoxDiagnosticSession, param2:String, param3:int) : void
      {
         var _loc4_:String = param2.indexOf("TAKE") >= 0 ? "take" : "remove";
         if(_loc4_ == "take")
         {
            param1.airborneTakeSeen = true;
         }
         if(param1.airborneRealTriggerBeforeGround && !param1.airborneResponseLogged)
         {
            param1.airborneResponseLogged = true;
            logRealTriggerBeforeGround(param1,"response",param3,param2);
         }
         logAirborneComparison(param1,_loc4_,param3);
         invalidateAirborneMotion(param1,true);
      }

      private static function logAirborneComparison(param1:GoldBoxDiagnosticSession, param2:String, param3:int) : void
      {
         var _loc4_:int = firstAirborneThresholdAt(param1);
         if(!param1.airborneObserved && !param1.airborneRealTriggerBeforeGround)
         {
            return;
         }
         if(!markAirborneComparisonLogged(param1,param2))
         {
            return;
         }
         logSession(param1,"AIRBORNE_SHADOW_COMPARISON","phase=" + param2 + " firstHypotheticalThreshold=" + firstAirborneThreshold(param1) + " crossed=" + safe(param1.airborneCrossingOrder) + " elapsedToGroundTouchMs=" + elapsedFromAirborneFirst(param1,param1.airborneGroundTouchAt) + " elapsedToRealTriggerMs=" + elapsedFromAirborneFirst(param1,param1.airborneRealTriggerAt) + " realTriggerLifecycle=" + safe(param1.airborneRealTriggerLifecycle) + " realTriggerDistance=" + number(param1.airborneRealTriggerDistance) + " distance3D=" + number(param1.airborneDistance3D) + " horizontalDistance=" + number(param1.airborneHorizontalDistance) + " verticalDelta=" + number(param1.airborneVerticalSeparation) + " numericallyDescending=" + bool(param1.airborneLastConfirmedAt >= 0 && param3 - param1.airborneLastConfirmedAt <= AIRBORNE_POSITION_MAX_AGE_MS) + " bonusVerticalVelocity=" + number(param1.airborneLastConfirmedVerticalVelocity) + " positionAgeMs=" + airbornePositionAge(param1,param3) + " localRequest=" + bool(param1.requestAt >= 0) + " serverLaterSentTake=" + bool(param1.airborneTakeSeen) + " firstCrossingAt=" + (_loc4_ < 0 ? "unknown" : String(_loc4_)));
      }

      private static function markAirborneComparisonLogged(param1:GoldBoxDiagnosticSession, param2:String) : Boolean
      {
         switch(param2)
         {
            case "ground_touch":
               if(param1.airborneComparisonGroundLogged) return false;
               param1.airborneComparisonGroundLogged = true;
               return true;
            case "real_trigger":
               if(param1.airborneComparisonTriggerLogged) return false;
               param1.airborneComparisonTriggerLogged = true;
               return true;
            case "take":
               if(param1.airborneComparisonTakeLogged) return false;
               param1.airborneComparisonTakeLogged = true;
               return true;
            case "remove":
               if(param1.airborneComparisonRemoveLogged) return false;
               param1.airborneComparisonRemoveLogged = true;
               return true;
            case "destroy":
               if(param1.airborneComparisonDestroyLogged) return false;
               param1.airborneComparisonDestroyLogged = true;
               return true;
            case "unload":
               if(param1.airborneComparisonUnloadLogged) return false;
               param1.airborneComparisonUnloadLogged = true;
               return true;
         }
         return false;
      }

      private static function airbornePositionAge(param1:GoldBoxDiagnosticSession, param2:int) : String
      {
         return param1.lastPositionSampleAt < 0 ? "unknown" : String(param2 - param1.lastPositionSampleAt);
      }

      private static function invalidateAirborneMotion(param1:GoldBoxDiagnosticSession, param2:Boolean = false) : void
      {
         param1.airborneCandidateTracking = false;
         param1.airborneConfirmedDescending = false;
         param1.airborneMotionHasPrevious = false;
         param1.airbornePreviousAt = -1;
         param1.airbornePreviousSource = null;
         param1.airborneVerticalDelta = NaN;
         param1.airborneVerticalVelocity = NaN;
         if(!param2)
         {
            param1.airborneLastConfirmedVerticalVelocity = NaN;
            param1.airborneLastConfirmedAt = -1;
         }
      }

      private static function clearAirborneState(param1:GoldBoxDiagnosticSession) : void
      {
         invalidateAirborneMotion(param1);
         param1.airborneBootstrapLogged = false;
         param1.airborneObserved = false;
         param1.airborneTriggerObserved = false;
         param1.airborneRealTriggerBeforeGround = false;
         param1.airborneTakeSeen = false;
         param1.airborneResponseLogged = false;
         param1.airborneComparisonGroundLogged = false;
         param1.airborneComparisonTriggerLogged = false;
         param1.airborneComparisonTakeLogged = false;
         param1.airborneComparisonRemoveLogged = false;
         param1.airborneComparisonDestroyLogged = false;
         param1.airborneComparisonUnloadLogged = false;
         param1.airbornePositionSource = null;
         param1.airborneDistance3D = NaN;
         param1.airborneHorizontalDistance = NaN;
         param1.airborneVerticalSeparation = NaN;
         param1.airborneTankSpeed = NaN;
         param1.airborneRadialClosingSpeed3D = NaN;
         param1.airborneHorizontalClosingSpeed = NaN;
         param1.airborneCrossingOrder = "";
         param1.airborneGroundTouchAt = -1;
         param1.airborneRealTriggerAt = -1;
         param1.airborneRealTriggerLifecycle = null;
         param1.airborneRealTriggerDistance = NaN;
         param1.airborne450At = -1;
         param1.airborne400At = -1;
         param1.airborne350At = -1;
         param1.airborne450Detection = null;
         param1.airborne400Detection = null;
         param1.airborne350Detection = null;
      }

      private static function isFiniteNumber(param1:Number) : Boolean
      {
         return !isNaN(param1) && param1 != Number.POSITIVE_INFINITY && param1 != Number.NEGATIVE_INFINITY;
      }

      private static function updateDistance(param1:GoldBoxDiagnosticSession) : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         if(param1.hasTankPosition && param1.hasBonusPosition)
         {
            _loc2_ = param1.tankX - param1.bonusX;
            _loc3_ = param1.tankY - param1.bonusY;
            _loc4_ = param1.tankZ - param1.bonusZ;
            param1.distance = Math.sqrt(_loc2_ * _loc2_ + _loc3_ * _loc3_ + _loc4_ * _loc4_);
         }
      }

      private static function logSession(param1:GoldBoxDiagnosticSession, param2:String, param3:String = "") : void
      {
         var _loc4_:int = getTimer();
         param1.lastEventAt = _loc4_;
         logRaw("bonusId=" + safe(param1.bonusId) + " event=" + param2 + " targetKind=" + safe(param1.targetKind) + " baseId=" + safe(param1.baseId) + " objectName=" + safe(param1.objectName) + " resourceId=" + safe(param1.resourceId) + " state=" + safe(param1.lifecycleState) + " box=" + position(param1.hasBonusPosition,param1.bonusX,param1.bonusY,param1.bonusZ) + " tank=" + position(param1.hasTankPosition,param1.tankX,param1.tankY,param1.tankZ) + " distance=" + number(param1.distance) + " trigger=" + safe(param1.triggerState) + " exists=" + (param1.modelExists ? "1" : "0") + " requestAgeMs=" + requestAge(param1,_loc4_) + (param3.length > 0 ? " " + param3 : ""),_loc4_ - param1.createdAt);
      }

      private static function logUnboundRegion(param1:Object, param2:String, param3:String = "") : void
      {
         logRaw("bonusId=unbound event=" + param2 + " regionKey=" + safe(param1.key) + " source=" + safe(param1.source) + " origin=" + position(true,param1.sourceX,param1.sourceY,param1.sourceZ) + (param1.hasGround ? " ground=" + position(true,param1.groundX,param1.groundY,param1.groundZ) : "") + (param3.length > 0 ? " " + param3 : ""));
      }

      private static function logRaw(param1:String, param2:int = -1) : void
      {
         var _loc3_:int = getTimer();
         if(!enabled || !fileLogEnabled)
         {
            return;
         }
         if(param2 < 0)
         {
            if(battleEpoch < 0)
            {
               battleEpoch = _loc3_;
            }
            param2 = _loc3_ - (battleEpoch >= 0 ? battleEpoch : diagnosticsEpoch);
         }
         logger.append("t=" + _loc3_ + " dt=" + param2 + " [GOLD_DIAG] " + sanitize(param1));
         startTimer();
      }

      public static function sanitize(param1:String) : String
      {
         return param1 == null ? "-" : param1.replace(/[\r\n]+/g," ");
      }

      private static function requestAge(param1:GoldBoxDiagnosticSession, param2:int) : String
      {
         if(param1.requestAt < 0)
         {
            return "-1";
         }
         return String((param1.responseAt >= 0 ? param1.responseAt : param2) - param1.requestAt);
      }

      private static function position(param1:Boolean, param2:Number, param3:Number, param4:Number) : String
      {
         return param1 ? "(" + number(param2) + "," + number(param3) + "," + number(param4) + ")" : "(-)";
      }

      private static function number(param1:Number) : String
      {
         return isNaN(param1) ? "-" : param1.toFixed(2);
      }

      private static function validPosition(param1:Number, param2:Number, param3:Number) : Boolean
      {
         return isFiniteNumber(param1) && isFiniteNumber(param2) && isFiniteNumber(param3);
      }

      private static function elapsed(param1:int, param2:int) : String
      {
         return param1 < 0 ? "unknown" : String(param2 - param1);
      }

      private static function clampNumber(param1:Number, param2:Number, param3:Number, param4:Number) : Number
      {
         if(isNaN(param1))
         {
            return param4;
         }
         return Math.max(param2,Math.min(param3,param1));
      }

      private static function clampInt(param1:int, param2:int, param3:int, param4:int) : int
      {
         if(param1 < param2 || param1 > param3)
         {
            return param4;
         }
         return param1;
      }

      private static function safe(param1:String) : String
      {
         return param1 == null ? "-" : sanitize(param1).replace(/\s+/g,"_");
      }

      private static function safeValue(param1:Object) : String
      {
         return safe(param1 == null ? null : String(param1));
      }

      private static function hasGoldToken(param1:String) : Boolean
      {
         var _loc2_:String = null;
         if(param1 == null)
         {
            return false;
         }
         _loc2_ = param1.toLowerCase();
         return _loc2_ == "gold" || _loc2_ == "goldbox" || _loc2_ == "gold_box" || /(^|[^a-z0-9])gold($|[^a-z0-9])/.test(_loc2_);
      }

      private static function normalizeIdentifier(param1:String) : String
      {
         return baseBonusId(param1 == null ? "" : param1).toLowerCase();
      }

      private static function isImmediateSnapshotEvent(param1:String) : Boolean
      {
         return param1 == "MANDATORY_UPDATE_DISPATCH_BEGIN" || param1 == "MANDATORY_UPDATE_DISPATCH_COMPLETE";
      }

      private static function bool(param1:Boolean) : String
      {
         return param1 ? "1" : "0";
      }

      private static function longHigh(param1:Long) : String
      {
         return param1 == null ? "-" : String(param1.high);
      }

      private static function longLow(param1:Long) : String
      {
         return param1 == null ? "-" : String(param1.low);
      }

      private static function ensureTimer() : void
      {
         if(enabled && hasActiveWork())
         {
            startTimer();
         }
      }

      private static function startTimer() : void
      {
         if(timer == null)
         {
            timer = new Timer(TIMER_INTERVAL_MS);
            timer.addEventListener(TimerEvent.TIMER,onTimer);
         }
         if(!timer.running)
         {
            timer.start();
         }
         updateOverlayAttachment();
      }

      private static function setTimerDelay(param1:int) : void
      {
         if(timer != null && timer.delay != param1)
         {
            timer.delay = param1;
         }
      }

      private static function stopTimer() : void
      {
         if(timer != null)
         {
            timer.stop();
         }
      }

      private static function stopTimerIfIdle() : void
      {
         if(!hasActiveWork())
         {
            stopTimer();
            removeOverlay();
            if(fileLogEnabled)
            {
               logger.flush();
            }
         }
      }

      private static function hasActiveWork() : Boolean
      {
         var _loc1_:String = null;
         var _loc2_:Object = null;
         if(fileLogEnabled && logger.hasPendingLines)
         {
            return true;
         }
         for(_loc1_ in pendingRequests)
         {
            return true;
         }
         if(overlayEnabled && latestLocalAttemptBonusId != null && sessions[latestLocalAttemptBonusId] != null)
         {
            return true;
         }
         if(shadowRadiusProbeEnabled && hasShadowEligibleSession())
         {
            return true;
         }
         if(airborneShadowCollectEnabled && hasAirborneCandidateSession())
         {
            return true;
         }
         if(proximityCollectEnabled)
         {
            return true;
         }
         for each(_loc2_ in regions)
         {
            if(_loc2_.visible)
            {
               return true;
            }
         }
         return false;
      }

      private static function updateOverlayAttachment() : void
      {
         var _loc1_:BattleService = null;
         if(!enabled || !overlayEnabled || !hasActiveWork())
         {
            removeOverlay();
            return;
         }
         if(overlay == null)
         {
            overlay = new DebugPanel();
            overlay.x = 10;
            overlay.y = 80;
         }
         if(overlay.parent == null)
         {
            _loc1_ = OSGi.getInstance().getService(BattleService) as BattleService;
            if(_loc1_ != null && _loc1_.getBattleView() != null)
            {
               _loc1_.getBattleView().addOverlayObject(overlay);
            }
         }
      }

      private static function updateOverlay() : void
      {
         var _loc1_:GoldBoxDiagnosticSession = sessions[latestLocalAttemptBonusId];
         updateOverlayAttachment();
         if(overlay == null || overlay.parent == null || _loc1_ == null)
         {
            return;
         }
         overlay.printValue("Bonus",_loc1_.bonusId);
         overlay.printValue("Target",_loc1_.targetKind);
         overlay.printValue("State",_loc1_.lifecycleState);
         overlay.printValue("Distance",number(_loc1_.distance));
         overlay.printValue("Trigger",_loc1_.triggerState);
         overlay.printValue("Request age",requestAge(_loc1_,getTimer()) + " ms");
      }

      private static function removeOverlay() : void
      {
         if(overlay != null && overlay.parent != null)
         {
            overlay.parent.removeChild(overlay);
         }
      }
   }
}
