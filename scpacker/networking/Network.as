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
   import flash.net.Socket;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;
   import flash.utils.ByteArray;
   import flash.utils.getTimer;
   import flash.utils.getQualifiedClassName;
   import platform.client.fp10.core.service.errormessage.IErrorMessageService;
   import scpacker.networking.protocol.PacketInvoker;
   import scpacker.networking.protocol.ProtocolInitializer;
   import scpacker.networking.protocol.PacketFactory;
   import scpacker.networking.protocol.AbstractPacket;
   import scpacker.networking.protocol.PacketInitializer;
   import utils.LoginDebugTrace;
   import scpacker.networking.protocol.packets.battlelist.SelectBattleInOutPacket;
   import scpacker.networking.protocol.packets.init.LoadResourcesInPacket;
   import scpacker.networking.protocol.packets.init.ResourcesLoadedOutPacket;
   
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

      private var afterJoinTraceUntil:int;
      
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
         var _loc1_:String = "wrap";
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
            return;
         }
         this.recordBattleSelectTrace(param1.getId(),true);
         try
         {
            param1.wrap(this.sendBuffer);
            _loc1_ = "write";
            this.socket.writeBytes(this.sendBuffer);
            _loc1_ = "flush";
            this.socket.flush();
            if(param1.getId() == -1284211503)
            {
               this.afterJoinTraceUntil = getTimer() + 3000;
            }
            if(param1.getId() == ResourcesLoadedOutPacket.id)
            {
               this.writeBattleSelectTrace("RESOURCES_LOADED_OUT packetId=" + ResourcesLoadedOutPacket.id + " callbackId=" + ResourcesLoadedOutPacket(param1).callbackID);
            }
         }
         catch(e:Error)
         {
            this.reportNetworkError("SEND_FAILURE",_loc1_,param1.getId(),-1,-1,false,e,false,false);
            if(this.isFatalSendStage(_loc1_))
            {
               this.terminateTransportWithoutFlush();
            }
            throw e;
         }
         finally
         {
            this.sendBuffer.clear();
         }
      }

      private function onConnect(param1:Event) : void
      {
         LoginDebugTrace.recordEvent("SOCKET_CONNECTED");
      }
      
      private function onSocketData(param1:ProgressEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         try
         {
            _loc2_ = this.socket.bytesAvailable;
            _loc3_ = this.inputBuffer.length;
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
         var _loc13_:int = -1;
         var _loc14_:int = -1;
         var _loc15_:Boolean = false;
         this.inputBuffer.position = this.readPosition;
         while(true)
         {
            _loc5_ = this.inputBuffer.position;
            if(this.inputBuffer.bytesAvailable < 8)
            {
               this.compactInputBufferFrom(_loc5_);
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
               this.compactInputBufferFrom(_loc5_);
               return;
            }
            _loc13_ = -1;
            _loc14_ = getTimer();
            _loc15_ = false;
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
               _loc13_ = -1;
               if(_loc11_ != null)
               {
                  try
                  {
                     _loc13_ = _loc11_.getPacketHandlerId();
                  }
                  catch(packetHandlerMetadataError:Error)
                  {
                  }
               }
               _loc15_ = true;
               this.recordBattleSelectTrace(_loc1_,false,_loc13_,_loc11_ == null ? "unresolved" : getQualifiedClassName(_loc11_));
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
                     this.recordResourceHandshakeInbound(_loc11_);
                     _loc8_ = "handler";
                     packetInvoker.invoke(_loc11_);
                  }
                  catch(packetError:Error)
                  {
                     this.reportNetworkError(
   "PACKET_FAILURE",
   _loc8_,
   _loc1_,
   _loc3_,
   _loc4_,
   _loc7_,
   packetError,
   true,
   false,
   getQualifiedClassName(_loc11_),
   _loc13_
);
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

      private function recordBattleSelectTrace(param1:int, param2:Boolean, param3:int = -1, param4:String = null) : void
      {
         var _loc3_:String = null;
         var _loc4_:String = null;
         if(!param2 && this.afterJoinTraceUntil > 0 && getTimer() <= this.afterJoinTraceUntil)
         {
            _loc4_ = "BATTLE_SELECT_TRACE AFTER_JOIN_IN packetId=" + param1 + " handlerId=" + param3 + " class=" + param4;
         }
         else if(param2 && param1 == 2092412133)
         {
            _loc3_ = "OUT_SELECT";
         }
         else if(param2 && param1 == -1284211503)
         {
            _loc3_ = "OUT_JOIN_BATTLE";
         }
         else if(!param2 && param1 == 2092412133)
         {
            _loc3_ = "IN_SELECT_ACK";
         }
         else if(!param2 && param1 == 546722394)
         {
            _loc3_ = "IN_LOAD_BATTLE_INFO";
         }
         else
         {
            return;
         }
         if(_loc4_ == null)
         {
            _loc4_ = "BATTLE_SELECT_TRACE " + _loc3_ + " packetId=" + param1;
         }
         this.writeBattleSelectTrace(_loc4_.substr("BATTLE_SELECT_TRACE ".length));
      }

      private function recordResourceHandshakeInbound(param1:AbstractPacket) : void
      {
         if(param1.getId() == LoadResourcesInPacket.id)
         {
            var _loc1_:LoadResourcesInPacket = LoadResourcesInPacket(param1);
            var _loc3_:int = 0;
            try
            {
               var _loc2_:Object = JSON.parse(_loc1_.resourcesJson);
               for each(var _loc4_:Object in _loc2_)
               {
                  _loc3_++;
               }
            }
            catch(resourceCountError:Error)
            {
               _loc3_ = -1;
            }
            this.writeBattleSelectTrace("LOAD_RESOURCES_IN callbackId=" + _loc1_.callbackId + " resourceCount=" + _loc3_);
         }
         else if(param1.getId() == -593368100)
         {
            this.writeBattleSelectTrace("END_LAYOUT_SWITCH packetId=-593368100");
         }
      }

      public function writeBattleSelectTrace(param1:String) : void
      {
         var _loc4_:String = "BATTLE_SELECT_TRACE " + param1;
         try
         {
            var _loc5_:LogService = LogService(OSGi.getInstance().getService(LogService));
            if(_loc5_ != null)
            {
               var _loc6_:Logger = _loc5_.getLogger("net");
               if(_loc6_ != null)
               {
                  _loc6_.info(_loc4_);
               }
            }
         }
         catch(logError:Error)
         {
         }
         try
         {
            trace(_loc4_);
         }
         catch(traceError:Error)
         {
         }
         var _loc7_:FileStream = null;
         try
         {
            _loc7_ = new FileStream();
            _loc7_.open(File.desktopDirectory.resolvePath("protanki-network-errors.log"),FileMode.APPEND);
            _loc7_.writeUTFBytes(_loc4_ + "\r\n");
         }
         catch(fileError:Error)
         {
         }
         finally
         {
            if(_loc7_ != null)
            {
               try
               {
                  _loc7_.close();
               }
               catch(closeError:Error)
               {
               }
            }
         }
      }

      private function compactInputBufferFrom(param1:int) : void
      {
         if(param1 < 0 || param1 > this.inputBuffer.length)
         {
            throw new RangeError("Invalid input buffer compaction offset: " + param1);
         }
         if(param1 == 0)
         {
            this.inputBuffer.position = 0;
            this.readPosition = 0;
            return;
         }
         var _loc2_:ByteArray = new ByteArray();
         this.inputBuffer.position = param1;
         this.inputBuffer.readBytes(_loc2_,0,this.inputBuffer.length - param1);
         this.inputBuffer.clear();
         if(_loc2_.length > 0)
         {
            this.inputBuffer.writeBytes(_loc2_,0,_loc2_.length);
         }
         this.inputBuffer.position = 0;
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

  private function reportNetworkError(
   category:String,
   stage:String,
   packetId:int,
   frameLength:int,
   payloadLength:int,
   compressed:Boolean,
   error:Error,
   transportRecoverable:Boolean,
   applicationStateGuaranteed:Boolean,
   packetClass:String = null,
   handlerId:int = -1
) : void
{
   var logMessage:String =
      "[NETWORK]" +
      " category=" + category +
      " stage=" + stage +
      " packetId=" + packetId +
      " frameLength=" + frameLength +
      " payloadLength=" + payloadLength +
      " compressed=" + compressed +
      " transportRecoverable=" + transportRecoverable +
      " applicationStateGuaranteed=" + applicationStateGuaranteed;

   // Packet/handler diagnostics when available
   if(packetClass != null && packetClass.length > 0)
   {
      logMessage += " packetClass=" + this.cleanLogText(packetClass);
   }

   if(handlerId >= 0)
   {
      logMessage += " handlerId=" + handlerId;
   }

   // Error diagnostics
   if(error != null)
   {
      try
      {
         logMessage +=
            " error=" +
            this.cleanLogText(error.name + ":" + error.message) +
            " errorId=" +
            error.errorID;

         var stackTrace:String = error.getStackTrace();

         if(stackTrace != null && stackTrace.length > 0)
         {
            logMessage +=
               " stack=" +
               this.cleanLogText(stackTrace);
         }
         else
         {
            logMessage += " stack=unavailable";
         }
      }
      catch(errorFormattingError:Error)
      {
         logMessage += " error=unavailable";
      }
   }

   // LogService
   try
   {
      var logService:LogService =
         LogService(
            OSGi.getInstance().getService(LogService)
         );

      if(logService != null)
      {
         var logger:Logger =
            logService.getLogger("net");

         if(logger != null)
         {
            logger.error(logMessage);
         }
      }
   }
   catch(logError:Error)
   {
   }

   // Flash/AIR trace
   try
   {
      trace(logMessage);
   }
   catch(traceError:Error)
   {
   }

   // Persistent file logging for important network failures
   if(
      category == "PACKET_FAILURE" ||
      category == "FATAL_RECEIVE" ||
      category == "RECEIVE_FAILURE" ||
      category == "SEND_FAILURE" ||
      category == "FATAL_FRAME"
   )
   {
      var fileStream:FileStream = null;

      try
      {
         var logFile:File =
            File.desktopDirectory.resolvePath(
               "protanki-network-errors.log"
            );

         fileStream = new FileStream();

         fileStream.open(
            logFile,
            FileMode.APPEND
         );

         fileStream.writeUTFBytes(
            new Date().toString() +
            " " +
            logMessage +
            "\r\n"
         );
      }
      catch(fileLogError:Error)
      {
      }
      finally
      {
         if(fileStream != null)
         {
            try
            {
               fileStream.close();
            }
            catch(closeFileLogError:Error)
            {
            }
         }
      }
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
