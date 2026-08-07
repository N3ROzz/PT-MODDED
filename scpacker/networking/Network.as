package scpacker.networking
{
   import platform.client.fp10.core.network.connection.ConnectionCloseStatus;
   import platform.client.fp10.core.network.handler.OnConnectionClosedServiceListener;
   import platform.client.fp10.core.service.errormessage.errors.ConnectionClosedError;
   import alternativa.osgi.OSGi;
   import alternativa.osgi.service.display.IDisplay;
   import alternativa.osgi.service.logging.LogService;
   import alternativa.osgi.service.logging.Logger;
   import alternativa.tanks.bg.IBackgroundService;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.ProgressEvent;
   import flash.events.SecurityErrorEvent;
   import flash.net.Socket;
   import flash.utils.ByteArray;
   import flash.utils.getQualifiedClassName;
   import platform.client.fp10.core.service.errormessage.IErrorMessageService;
   import scpacker.networking.protocol.PacketInvoker;
   import scpacker.networking.protocol.ProtocolInitializer;
   import scpacker.networking.protocol.PacketFactory;
   import scpacker.networking.protocol.AbstractPacket;
   import scpacker.networking.protocol.PacketInitializer;
   import utils.TankTraceUtil;
   import utils.BattleSelectionTrace;
   import utils.LoginDebugTrace;
   import scpacker.networking.protocol.packets.battlelist.SelectBattleInOutPacket;
   
   public class Network
   {
      private static const MIN_FRAME_LENGTH:int = 8;

      private static const MAX_FRAME_LENGTH:int = 8 * 1024 * 1024;

      private static const MAX_PAYLOAD_LENGTH:int = MAX_FRAME_LENGTH - MIN_FRAME_LENGTH;

      private static const MAX_UNCOMPRESSED_PAYLOAD_LENGTH:int = 16 * 1024 * 1024;

      private static var packetInvoker:PacketInvoker;
      
      private static var protocolInitializer:ProtocolInitializer;
      
      private static var packetFactory:PacketFactory;
      
      public static var backgroundService:IBackgroundService;
      
      private var socket:Socket;
      
      private var readPosition:int;
      
      private var payloadBuffer:ByteArray = new ByteArray();
      
      private var inputBuffer:ByteArray = new ByteArray();
      
      private var useExtraHost:Boolean = false;
      
      private var sendBuffer:ByteArray = new ByteArray();
      
      private var extraHost:String;
      
      private var extraPort:int;

      private var transportFailed:Boolean;
      
      public function Network()
      {
         super();
         this.socket = new Socket();
         packetFactory = new PacketFactory();
         packetInvoker = new PacketInvoker();
         OSGi.getInstance().registerService(PacketInvoker,packetInvoker);
         OSGi.getInstance().registerService(PacketFactory,packetFactory);
         protocolInitializer = new ProtocolInitializer();
         OSGi.getInstance().registerService(ProtocolInitializer,protocolInitializer);
         AbstractPacket.protocolInitializer = protocolInitializer;
         BattleSelectionTrace.startSession();
      }
      
      public function connect(param1:String, param2:int) : void
      {
         var _loc3_:OSGi = null;
         var _loc4_:ProtocolInitializer = null;
         LoginDebugTrace.beginConnection(param1,param2,useExtraHost);
         this.transportFailed = false;
         if(!useExtraHost)
         {
            _loc3_ = OSGi.getInstance();
            _loc4_ = ProtocolInitializer(_loc3_.getService(ProtocolInitializer));
            _loc4_.init();
            new PacketInitializer().init(_loc3_);
         }
         this.socket.connect(param1,param2);
         this.socket.addEventListener("socketData",this.onSocketData);
         this.socket.addEventListener("connect",this.onConnect);
         this.socket.addEventListener("close",this.onClose);
         this.socket.addEventListener("ioError",this.ioError);
         this.socket.addEventListener("securityError",this.onSecurityError);
      }
      
      public function destroy() : void
      {
         this.socket.removeEventListener("socketData",this.onSocketData);
         this.socket.removeEventListener("connect",this.onConnect);
         this.socket.removeEventListener("close",this.onClose);
         this.socket.removeEventListener("ioError",this.ioError);
         this.socket.removeEventListener("securityError",this.onSecurityError);
         this.inputBuffer.clear();
         this.payloadBuffer.clear();
         this.sendBuffer.clear();
         this.readPosition = 0;
      }
      
      public function send(param1:AbstractPacket) : void
      {
         var _loc1_:SelectBattleInOutPacket = null;
         var _loc2_:String = null;
         var _loc3_:Network = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:Boolean = param1 != null && param1.getId() == SelectBattleInOutPacket.id && BattleSelectionTrace.ENABLED;
         var _loc8_:String = "diagnostics";
         this.sendBuffer.clear();
         if(param1 != null && this.socket != null && this.socket.connected)
         {
            try
            {
               LoginDebugTrace.recordPacket("OUT",param1.getId(),param1.getPacketHandlerId(),-1,getQualifiedClassName(param1));
            }
            catch(loginDiagnosticError:Error)
            {
               this.reportNetworkError("DIAGNOSTIC_FAILURE","login_debug_out",param1.getId(),-1,-1,false,loginDiagnosticError,true,false);
            }
         }
         if(param1 == null || this.socket == null || !this.socket.connected || this.transportFailed)
         {
            if(_loc7_)
            {
               _loc1_ = param1 as SelectBattleInOutPacket;
               _loc2_ = _loc1_ == null ? "" : _loc1_.battleId;
               try
               {
                  BattleSelectionTrace.record("NETWORK_SEND_SKIPPED","Network.send",_loc2_,null,this.transportFailed ? "transportFailed" : "socketDisconnected");
               }
               catch(skipDiagnosticError:Error)
               {
                  this.reportNetworkError("DIAGNOSTIC_FAILURE","battle_selection_skip",param1.getId(),-1,-1,false,skipDiagnosticError,true,false);
               }
            }
            return;
         }
         try
         {
            if(_loc7_)
            {
               _loc1_ = param1 as SelectBattleInOutPacket;
               _loc2_ = _loc1_ == null ? "" : _loc1_.battleId;
               _loc3_ = Network(OSGi.getInstance().getService(Network));
               BattleSelectionTrace.record("NETWORK_SEND_ENTER","Network.send",_loc2_,null,"packetId=" + param1.getId() + " packetClass=" + getQualifiedClassName(param1));
               BattleSelectionTrace.record("NETWORK_INSTANCE_CHECK","Network.send",_loc2_,null,"thisNetwork=" + BattleSelectionTrace.identity(this) + " activeNetwork=" + BattleSelectionTrace.identity(_loc3_) + " same=" + (this === _loc3_));
               BattleSelectionTrace.record("NETWORK_SOCKET_STATE","Network.send",_loc2_,null,"connected=" + this.socket.connected + " sendBufferLength=" + this.sendBuffer.length + " sendBufferPosition=" + this.sendBuffer.position + " stringLength=" + _loc2_.length + " trailingCodes=" + this.getTrailingCharacterCodes(_loc2_) + " trailingAsciiSpace=" + (_loc2_.length > 0 && _loc2_.charCodeAt(_loc2_.length - 1) == 32));
               BattleSelectionTrace.record("PACKET_WRAP_BEGIN","Network.send",_loc2_,null,"bufferLengthBefore=" + this.sendBuffer.length + " bufferPositionBefore=" + this.sendBuffer.position + " packetLengthBefore=" + param1.getPacketLength());
            }
            else if(param1.getId() == 2092412133 || param1.getId() == -1284211503)
            {
               TankTraceUtil.logBattleListStale("send packetId=" + param1.getId() + " lastSelect=" + TankTraceUtil.lastBattleSelectId + " lastJoin=" + TankTraceUtil.lastBattleJoinId);
            }

            _loc8_ = "wrap";
            param1.wrap(this.sendBuffer);
            _loc8_ = "post_wrap";
            if(_loc7_)
            {
               _loc4_ = this.sendBuffer.position;
               this.sendBuffer.position = 0;
               _loc5_ = this.sendBuffer.readInt();
               _loc6_ = this.sendBuffer.readInt();
               this.sendBuffer.position = _loc4_;
               BattleSelectionTrace.record("PACKET_WRAP_END","Network.send",_loc2_,null,"bufferLengthAfter=" + this.sendBuffer.length + " bufferPositionAfter=" + this.sendBuffer.position + " packetLength=" + param1.getPacketLength() + " frameHeaderLength=" + _loc5_ + " framePacketId=" + _loc6_);
               BattleSelectionTrace.record("SOCKET_WRITE_BEGIN","Network.send",_loc2_,null,"bufferLength=" + this.sendBuffer.length + " bufferPosition=" + this.sendBuffer.position + " frameHeaderLength=" + _loc5_ + " framePacketId=" + _loc6_);
            }
            _loc8_ = "write";
            this.socket.writeBytes(this.sendBuffer);
            _loc8_ = "post_write";
            if(_loc7_)
            {
               BattleSelectionTrace.record("SOCKET_WRITE_END","Network.send",_loc2_,null,"bufferLength=" + this.sendBuffer.length + " socketBytesPending=" + this.socket.bytesPending);
               BattleSelectionTrace.record("SOCKET_FLUSH_BEGIN","Network.send",_loc2_,null,"socketBytesPending=" + this.socket.bytesPending);
            }
            _loc8_ = "flush";
            this.socket.flush();
            _loc8_ = "complete";
            if(_loc7_)
            {
               BattleSelectionTrace.record("SOCKET_FLUSH_END","Network.send",_loc2_,null,"socketBytesPending=" + this.socket.bytesPending);
            }
         }
         catch(e:Error)
         {
            if(_loc7_)
            {
               try
               {
                  BattleSelectionTrace.record("NETWORK_SEND_ERROR","Network.send",_loc2_,null,"stage=" + _loc8_ + " type=" + e.name + " message=" + e.message + " bufferLength=" + this.sendBuffer.length + " bufferPosition=" + this.sendBuffer.position);
               }
               catch(diagnosticError:Error)
               {
               }
            }
            this.reportNetworkError("SEND_FAILURE",_loc8_,param1.getId(),-1,-1,false,e,false,false);
            if(this.isFatalSendStage(_loc8_))
            {
               this.terminateTransportWithoutFlush();
            }
            throw e;
         }
         finally
         {
            this.sendBuffer.clear();
            _loc1_ = null;
            _loc3_ = null;
         }
      }

      private function getTrailingCharacterCodes(param1:String) : String
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:Array = [];
         if(param1 == null || param1.length == 0)
         {
            return "";
         }
         _loc2_ = Math.max(0,param1.length - 3);
         _loc3_ = _loc2_;
         while(_loc3_ < param1.length)
         {
            _loc4_.push(param1.charCodeAt(_loc3_));
            _loc3_++;
         }
         return _loc4_.join(",");
      }
      
      private function onConnect(param1:Event) : void
      {
         LoginDebugTrace.recordEvent("SOCKET_CONNECTED");
      }
      
      private function onSocketData(param1:ProgressEvent) : void
      {
         try
         {
            this.socket.readBytes(this.inputBuffer,this.inputBuffer.length);
            this.processIncoming();
         }
         catch(e:Error)
         {
            this.reportNetworkError("RECEIVE_FAILURE","socket_read",-1,-1,-1,false,e,false,false);
            this.failIncomingTransport();
         }
      }
       
      private function processIncoming() : void
      {
         var _loc10_:int = 0;
         var _loc7_:Boolean = false;
         var _loc3_:int = 0;
         var _loc1_:int = 0;
         var _loc4_:int = 0;
         var _loc11_:AbstractPacket = null;
         var _loc5_:int = 0;
         var _loc8_:String = "header";
         var _loc6_:Boolean = false;
         var _loc2_:Error = null;
         this.inputBuffer.position = this.readPosition;
         while(true)
         {
            _loc5_ = this.inputBuffer.position;
            if(this.inputBuffer.bytesAvailable < 8)
            {
               this.inputBuffer.position = _loc5_;
               this.readPosition = _loc5_;
               return;
            }
            _loc10_ = this.inputBuffer.readInt();
            _loc7_ = (_loc10_ >>> 24 & 0x40) != 0;
            _loc3_ = _loc10_ & 16777215;
            _loc1_ = this.inputBuffer.readInt();
            if(_loc3_ < MIN_FRAME_LENGTH || _loc3_ > MAX_FRAME_LENGTH)
            {
               _loc2_ = new Error("Invalid frame length " + _loc3_);
               this.reportNetworkError("FATAL_FRAME","header",_loc1_,_loc3_,-1,_loc7_,_loc2_,false,false);
               this.failIncomingTransport();
               return;
            }
            _loc4_ = _loc3_ - 8;
            if(_loc4_ < 0 || _loc4_ > MAX_PAYLOAD_LENGTH)
            {
               _loc2_ = new Error("Invalid payload length " + _loc4_);
               this.reportNetworkError("FATAL_FRAME","payload_length",_loc1_,_loc3_,_loc4_,_loc7_,_loc2_,false,false);
               this.failIncomingTransport();
               return;
            }
            if(this.inputBuffer.bytesAvailable < _loc4_)
            {
               this.inputBuffer.position = _loc5_;
               this.readPosition = _loc5_;
               return;
            }
            var _loc12_:int = this.inputBuffer.position + _loc4_;
            _loc6_ = false;
            _loc2_ = null;
            _loc11_ = null;
            this.payloadBuffer.clear();
            try
            {
               _loc8_ = "payload_read";
               if(_loc4_ > 0)
               {
                  this.inputBuffer.readBytes(this.payloadBuffer,0,_loc4_);
               }
               _loc8_ = "decrypt";
               protocolInitializer.getProtection().decrypt(this.payloadBuffer,_loc4_);
               if(_loc7_)
               {
                  _loc8_ = "decompress";
                  this.payloadBuffer.uncompress("deflate");
                  if(this.payloadBuffer.length > MAX_UNCOMPRESSED_PAYLOAD_LENGTH)
                  {
                     _loc8_ = "decompressed_size";
                     throw new Error("Uncompressed payload exceeds limit: " + this.payloadBuffer.length);
                  }
               }
               _loc8_ = "packet_resolution";
               _loc11_ = packetFactory.getPacket(_loc1_);
               this.recordInboundDiagnosticsSafely(_loc1_,_loc11_,_loc3_,_loc7_);
               if(_loc11_ == null)
               {
                  this.reportNetworkError("UNKNOWN_PACKET","packet_resolution",_loc1_,_loc3_,_loc4_,_loc7_,null,true,false);
               }
               else
               {
                  try
                  {
                     _loc8_ = "unwrap";
                     _loc11_.unwrap(this.payloadBuffer);
                     _loc8_ = "handler";
                     packetInvoker.invoke(_loc11_);
                  }
                  catch(packetError:Error)
                  {
                     this.reportNetworkError("PACKET_FAILURE",_loc8_,_loc1_,_loc3_,_loc4_,_loc7_,packetError,true,false);
                  }
               }
            }
            catch(e:Error)
            {
               _loc6_ = true;
               _loc2_ = e;
            }
            finally
            {
               this.payloadBuffer.clear();
            }
            if(_loc6_)
            {
               this.reportNetworkError("FATAL_RECEIVE",_loc8_,_loc1_,_loc3_,_loc4_,_loc7_,_loc2_,false,false);
               this.failIncomingTransport();
               return;
            }
            this.inputBuffer.position = _loc12_;
            this.readPosition = _loc12_;
            if(this.inputBuffer.bytesAvailable == 0)
            {
               break;
            }
         }
         this.inputBuffer.clear();
         this.readPosition = 0;
      }

      private function recordInboundDiagnosticsSafely(param1:int, param2:AbstractPacket, param3:int, param4:Boolean) : void
      {
         var _loc4_:int = -1;
         var _loc5_:String = "unresolved";
         if(param2 != null)
         {
            try
            {
               _loc4_ = param2.getPacketHandlerId();
               _loc5_ = getQualifiedClassName(param2);
            }
            catch(packetMetadataError:Error)
            {
               this.reportNetworkError("DIAGNOSTIC_FAILURE","packet_metadata",param1,param3,param3 - MIN_FRAME_LENGTH,param4,packetMetadataError,true,false);
            }
         }
         try
         {
            BattleSelectionTrace.recordInboundPacket(param1,_loc4_,param3);
         }
         catch(battleDiagnosticError:Error)
         {
            this.reportNetworkError("DIAGNOSTIC_FAILURE","battle_selection",param1,param3,param3 - MIN_FRAME_LENGTH,param4,battleDiagnosticError,true,false);
         }
         try
         {
            LoginDebugTrace.recordPacket("IN",param1,_loc4_,param3,_loc5_);
         }
         catch(loginDiagnosticError:Error)
         {
            this.reportNetworkError("DIAGNOSTIC_FAILURE","login_debug",param1,param3,param3 - MIN_FRAME_LENGTH,param4,loginDiagnosticError,true,false);
         }
      }

      private function isFatalSendStage(param1:String) : Boolean
      {
         return param1 == "wrap" || param1 == "post_wrap" || param1 == "write" || param1 == "post_write" || param1 == "flush";
      }

      private function failIncomingTransport() : void
      {
         this.inputBuffer.clear();
         this.payloadBuffer.clear();
         this.readPosition = 0;
         this.terminateTransportWithoutFlush();
      }

      private function terminateTransportWithoutFlush() : void
      {
         this.transportFailed = true;
         try
         {
            if(this.socket != null && this.socket.connected)
            {
               this.socket.close();
            }
         }
         catch(closeError:Error)
         {
            this.reportNetworkError("TERMINATION_FAILURE","close",-1,-1,-1,false,closeError,false,false);
         }
      }

      private function reportNetworkError(param1:String, param2:String, param3:int, param4:int, param5:int, param6:Boolean, param7:Error, param8:Boolean, param9:Boolean) : void
      {
         var _loc10_:String = "[NETWORK] category=" + param1 + " stage=" + param2 + " packetId=" + param3 + " frameLength=" + param4 + " payloadLength=" + param5 + " compressed=" + param6 + " transportRecoverable=" + param8 + " applicationStateGuaranteed=" + param9;
         if(param7 != null)
         {
            try
            {
               _loc10_ += " error=" + this.cleanLogText(param7.name + ":" + param7.message);
               var _loc11_:String = param7.getStackTrace();
               if(_loc11_ != null && _loc11_.length > 0)
               {
                  _loc10_ += " stack=" + this.cleanLogText(_loc11_);
               }
            }
            catch(errorFormattingError:Error)
            {
               _loc10_ += " error=unavailable";
            }
         }
         try
         {
            var _loc12_:LogService = LogService(OSGi.getInstance().getService(LogService));
            if(_loc12_ != null)
            {
               var _loc13_:Logger = _loc12_.getLogger("net");
               if(_loc13_ != null)
               {
                  _loc13_.error(_loc10_);
               }
            }
         }
         catch(logError:Error)
         {
         }
         try
         {
            trace(_loc10_);
         }
         catch(traceError:Error)
         {
         }
      }

      private function cleanLogText(param1:String) : String
      {
         if(param1 == null)
         {
            return "";
         }
         var _loc2_:String = param1.replace(/[\r\n\t]+/g," ");
         return _loc2_.length > 2048 ? _loc2_.substr(0,2048) : _loc2_;
      }
       
      private function closeSocket() : void
      {
         if(this.socket == null || !this.socket.connected)
         {
            return;
         }
         try
         {
            this.socket.flush();
         }
         catch(flushError:Error)
         {
            this.reportNetworkError("CONTROLLED_CLOSE_FAILURE","flush",-1,-1,-1,false,flushError,false,false);
         }
         try
         {
            this.socket.close();
         }
         catch(closeError:Error)
         {
            this.reportNetworkError("CONTROLLED_CLOSE_FAILURE","close",-1,-1,-1,false,closeError,false,false);
         }
      }
      
      private function onClose(param1:Event) : void
      {
         var _loc4_:int = 0;
         LoginDebugTrace.recordEvent("SOCKET_CLOSED");
         LoginDebugTrace.endSession("socket_closed");
         TankTraceUtil.logBattleListStale("socket close lastSelect=" + TankTraceUtil.lastBattleSelectId + " lastJoin=" + TankTraceUtil.lastBattleJoinId + " useExtraHost=" + useExtraHost);
         closeSocket();
         var _loc3_:IDisplay = IDisplay(OSGi.getInstance().getService(IDisplay));
         _loc4_ = _loc3_.mainContainer.numChildren - 1;
         while(_loc4_ >= 0)
         {
            if(_loc3_.mainContainer.getChildAt(_loc4_) != _loc3_.backgroundLayer)
            {
               _loc3_.mainContainer.removeChildAt(_loc4_);
            }
            _loc4_--;
         }
         for each(var _loc2_ in OSGi.getInstance().serviceList)
         {
            if(_loc2_ is OnConnectionClosedServiceListener)
            {
               OnConnectionClosedServiceListener(_loc2_).onConnectionClosed(ConnectionCloseStatus.CLOSED_BY_SERVER);
            }
         }
         backgroundService.drawBg();
         backgroundService.showBg();
         IErrorMessageService(OSGi.getInstance().getService(IErrorMessageService)).showMessage(new ConnectionClosedError(ConnectionCloseStatus.CLOSED_BY_SERVER));
      }
      
      private function ioError(param1:IOErrorEvent) : void
      {
         LoginDebugTrace.recordEvent("SOCKET_IO_ERROR","text=" + param1.text);
         LoginDebugTrace.endSession("socket_io_error");
         TankTraceUtil.logBattleListStale("socket ioError text=" + param1.text + " lastSelect=" + TankTraceUtil.lastBattleSelectId + " lastJoin=" + TankTraceUtil.lastBattleJoinId + " useExtraHost=" + useExtraHost);
         closeSocket();
         if(!useExtraHost)
         {
            reconnectToExtraHost();
            return;
         }
         IErrorMessageService(OSGi.getInstance().getService(IErrorMessageService)).showMessage(new ConnectionClosedError(ConnectionCloseStatus.CONNECTION_ERROR));
         backgroundService.drawBg();
         backgroundService.showBg();
      }
      
      private function onSecurityError(param1:SecurityErrorEvent) : void
      {
         LoginDebugTrace.recordEvent("SOCKET_SECURITY_ERROR","text=" + param1.text);
         LoginDebugTrace.endSession("socket_security_error");
         TankTraceUtil.logBattleListStale("socket securityError text=" + param1.text + " lastSelect=" + TankTraceUtil.lastBattleSelectId + " lastJoin=" + TankTraceUtil.lastBattleJoinId + " useExtraHost=" + useExtraHost);
         closeSocket();
         if(!useExtraHost)
         {
            reconnectToExtraHost();
            return;
         }
         IErrorMessageService(OSGi.getInstance().getService(IErrorMessageService)).showMessage(new ConnectionClosedError(ConnectionCloseStatus.CLOSED_BY_SERVER));
         backgroundService.drawBg();
         backgroundService.showBg();
      }
      
      public function setExtraHost(param1:String, param2:int) : void
      {
         extraHost = param1;
         extraPort = param2;
      }
      
      public function reconnectToExtraHost() : void
      {
         if(useExtraHost)
         {
            return;
         }
         closeSocket();
         OSGi.clientLog.log("net","Reconnecting to extra server");
         destroy();
         socket = new Socket();
         protocolInitializer.reset();
         useExtraHost = true;
         connect(extraHost,extraPort);
      }
   }
}
