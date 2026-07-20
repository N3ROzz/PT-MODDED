package utils.goldbox
{
   public class GoldBoxDiagnosticSession
   {
      public var bonusId:String;
      public var bonusType:String;
      public var targetKind:String = "gold_variant";
      public var baseId:String;
      public var objectName:String;
      public var resourceId:String;
      public var lifecycleState:String = "SPAWN_PACKET";
      public var triggerState:String = "unknown";
      public var createdAt:int;
      public var lastEventAt:int;
      public var requestAt:int = -1;
      public var responseAt:int = -1;
      public var lastPositionSampleAt:int = -1;
      public var lastRequestSampleAt:int = -1;
      public var lastPeriodicLogAt:int = -1;
      public var timedOut:Boolean;
      public var terminal:Boolean;
      public var localAttempt:Boolean;
      public var cleanupPending:Boolean;
      public var modelExists:Boolean;
      public var regionKey:String;

      public var hasSpawnPosition:Boolean;
      public var spawnX:Number;
      public var spawnY:Number;
      public var spawnZ:Number;

      public var hasGroundPosition:Boolean;
      public var groundX:Number;
      public var groundY:Number;
      public var groundZ:Number;

      public var hasBonusPosition:Boolean;
      public var bonusX:Number;
      public var bonusY:Number;
      public var bonusZ:Number;

      public var hasTankPosition:Boolean;
      public var tankX:Number;
      public var tankY:Number;
      public var tankZ:Number;

      public var distance:Number = NaN;

      public var groundTouched:Boolean;
      public var awaitingGroundedPosition:Boolean;
      public var hasGroundedPosition:Boolean;
      public var groundedX:Number;
      public var groundedY:Number;
      public var groundedZ:Number;
      public var groundedPositionAt:int = -1;

      public var shadowTracking:Boolean;
      public var shadowObserved:Boolean;
      public var shadowFinalized:Boolean;
      public var shadowCrossingOrder:String = "";
      public var shadowDistance:Number = NaN;
      public var shadowTankSpeed:Number = NaN;
      public var shadowClosingSpeed:Number = NaN;

      public var shadow450At:int = -1;
      public var shadow425At:int = -1;
      public var shadow400At:int = -1;
      public var shadow375At:int = -1;
      public var shadow350At:int = -1;

      public var shadow450Detection:String;
      public var shadow425Detection:String;
      public var shadow400Detection:String;
      public var shadow375Detection:String;
      public var shadow350Detection:String;

      public var hasTankVelocity:Boolean;
      public var tankVelocityX:Number;
      public var tankVelocityY:Number;
      public var tankVelocityZ:Number;

      public var airborneCandidateTracking:Boolean;
      public var airborneBootstrapLogged:Boolean;
      public var airborneConfirmedDescending:Boolean;
      public var airborneObserved:Boolean;
      public var airborneTriggerObserved:Boolean;
      public var airborneRealTriggerBeforeGround:Boolean;
      public var airborneTakeSeen:Boolean;
      public var airborneResponseLogged:Boolean;
      public var airborneComparisonGroundLogged:Boolean;
      public var airborneComparisonTriggerLogged:Boolean;
      public var airborneComparisonTakeLogged:Boolean;
      public var airborneComparisonRemoveLogged:Boolean;
      public var airborneComparisonDestroyLogged:Boolean;
      public var airborneComparisonUnloadLogged:Boolean;
      public var airbornePositionSource:String;
      public var airborneMotionHasPrevious:Boolean;
      public var airbornePreviousX:Number;
      public var airbornePreviousY:Number;
      public var airbornePreviousZ:Number;
      public var airbornePreviousAt:int = -1;
      public var airbornePreviousSource:String;
      public var airborneVerticalDelta:Number = NaN;
      public var airborneVerticalVelocity:Number = NaN;
      public var airborneLastConfirmedVerticalVelocity:Number = NaN;
      public var airborneLastConfirmedAt:int = -1;
      public var airborneDistance3D:Number = NaN;
      public var airborneHorizontalDistance:Number = NaN;
      public var airborneVerticalSeparation:Number = NaN;
      public var airborneTankSpeed:Number = NaN;
      public var airborneRadialClosingSpeed3D:Number = NaN;
      public var airborneHorizontalClosingSpeed:Number = NaN;
      public var airborneCrossingOrder:String = "";
      public var airborneGroundTouchAt:int = -1;
      public var airborneRealTriggerAt:int = -1;
      public var airborneRealTriggerLifecycle:String;
      public var airborneRealTriggerDistance:Number = NaN;

      public var airborne450At:int = -1;
      public var airborne400At:int = -1;
      public var airborne350At:int = -1;
      public var airborne450Detection:String;
      public var airborne400Detection:String;
      public var airborne350Detection:String;

      public var proximityTracking:Boolean;
      public var proximityInRange:Boolean;
      public var proximityExitedRange:Boolean;
      public var proximityOutsideTicks:int;
      public var proximityAttemptsSent:int;
      public var proximityBurstAttempts:int;
      public var proximityFirstAttemptAt:int = -1;
      public var proximityLastAttemptAt:int = -1;
      public var proximityNextAttemptAt:int = -1;
      public var proximityExhausted:Boolean;
      public var proximityExhaustionLogged:Boolean;
      public var proximityGroundRearmUsed:Boolean;
      public var proximityGroundTransitionSeen:Boolean;
      public var proximityLocalCollisionObserved:Boolean;
      public var proximityLocalCollisionAt:int = -1;
      public var proximityTriggerAt:int = -1;
      public var proximityAttemptDistances:String = "";
      public var proximityLastPacketBonusId:String;
      public var proximityDistance3D:Number = NaN;
      public var proximityHorizontalDistance:Number = NaN;
      public var proximityVerticalDelta:Number = NaN;
      public var proximityPositionSource:String;
      public var proximityPositionAt:int = -1;
      public var proximityPositionValid:Boolean;
      public var proximityHasLivePosition:Boolean;
      public var proximityStopped:Boolean;

      public function GoldBoxDiagnosticSession(param1:String, param2:String, param3:int)
      {
         super();
         this.bonusId = param1;
         this.bonusType = param2;
         this.createdAt = param3;
         this.lastEventAt = param3;
      }
   }
}
