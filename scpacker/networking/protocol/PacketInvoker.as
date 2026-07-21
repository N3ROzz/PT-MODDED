package scpacker.networking.protocol
{
   import alternativa.osgi.OSGi;
   import alternativa.osgi.service.logging.LogService;
   import platform.client.fp10.core.model.impl.Model;

   public class PacketInvoker
   {
      private var packetHandlers:Vector.<AbstractPacketHandler> = new Vector.<AbstractPacketHandler>(95);
      
      public function PacketInvoker()
      {
         super();
      }
      
      public function registerPacketHandler(param1:AbstractPacketHandler) : void
      {
         packetHandlers[param1.id] = param1;
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         var _loc2_:Object = Model.captureContextSnapshot();
         var _loc3_:int = Model.contextDepth;
         var _loc4_:uint = Model.popUnderflowGeneration;
         var _loc5_:int = -1;
         try
         {
            _loc5_ = param1.getPacketHandlerId();
            var _loc6_:Object = this.packetHandlers[_loc5_];
            _loc6_.invoke(param1);
         }
         finally
         {
            this.verifyAndRestoreContext(_loc2_,_loc3_,_loc4_,_loc5_);
         }
      }

      private function verifyAndRestoreContext(param1:Object, param2:int, param3:uint, param4:int) : void
      {
         try
         {
            this.verifyAndRestoreContextInternal(param1,param2,param3,param4);
         }
         catch(e:Error)
         {
            trace("[MODEL_CONTEXT] handlerId=" + param4 + " mismatch=BOUNDARY_GUARD_FAILURE error=" + e.name + ":" + e.message);
         }
      }

      private function verifyAndRestoreContextInternal(param1:Object, param2:int, param3:uint, param4:int) : void
      {
         var _loc5_:int = -1;
         var _loc6_:uint = Model.popUnderflowGeneration;
         var _loc7_:String = "";
         var _loc8_:String = "";
         try
         {
            _loc5_ = Model.contextDepth;
         }
         catch(depthError:Error)
         {
            _loc8_ = "depth=" + depthError.name + ":" + depthError.message;
         }
         try
         {
            _loc7_ = Model.describeContextMismatch(param1);
         }
         catch(compareError:Error)
         {
            _loc7_ = "SNAPSHOT_COMPARE_FAILURE";
            _loc8_ = this.appendDetail(_loc8_,"compare=" + compareError.name + ":" + compareError.message);
         }
         var _loc9_:Boolean = _loc7_.length > 0;
         if(_loc6_ != param3)
         {
            _loc7_ = this.appendMismatch(_loc7_,"POP_UNDERFLOW");
         }

         var _loc10_:String = "not_required";
         if(_loc9_)
         {
            try
            {
               Model.restoreContextSnapshot(param1);
               _loc10_ = "restored";
            }
            catch(restoreError:Error)
            {
               _loc10_ = "failed";
               _loc8_ = this.appendDetail(_loc8_,"restore=" + restoreError.name + ":" + restoreError.message);
            }
         }

         if(_loc7_.length > 0)
         {
            var _loc11_:String = "[MODEL_CONTEXT] handlerId=" + param4 + " entryDepth=" + param2 + " exitDepth=" + _loc5_ + " mismatch=" + _loc7_ + " underflowEntry=" + param3 + " underflowExit=" + _loc6_ + " restore=" + _loc10_;
            if(_loc8_.length > 0)
            {
               _loc11_ += " details=" + _loc8_;
            }
            this.reportContextMismatch(_loc11_);
         }
      }

      private function appendMismatch(param1:String, param2:String) : String
      {
         if(param1.length == 0)
         {
            return param2;
         }
         if(param1.indexOf(param2) >= 0)
         {
            return param1;
         }
         return param1 + "," + param2;
      }

      private function appendDetail(param1:String, param2:String) : String
      {
         return param1.length == 0 ? param2 : param1 + ";" + param2;
      }

      private function reportContextMismatch(param1:String) : void
      {
         try
         {
            var _loc2_:LogService = LogService(OSGi.getInstance().getService(LogService));
            if(_loc2_ != null)
            {
               _loc2_.getLogger("modelcontext").error(param1);
               return;
            }
         }
         catch(loggerError:Error)
         {
         }
         trace(param1);
      }
   }
}
