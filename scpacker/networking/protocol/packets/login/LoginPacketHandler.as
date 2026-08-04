package scpacker.networking.protocol.packets.login
{
   import scpacker.networking.protocol.AbstractPacketHandler;
   import alternativa.types.Long;
   import alternativa.tanks.servermodels.EntranceModel;
   import alternativa.tanks.servermodels.login.LoginModel;
   import scpacker.networking.protocol.AbstractPacket;
   import projects.tanks.client.entrance.model.entrance.login.LoginModelBase;
   import projects.tanks.client.entrance.model.entrance.entrance.EntranceModelBase;
   import utils.LoginDebugTrace;
   
   public class LoginPacketHandler extends AbstractPacketHandler
   {
      private var loginModel:LoginModel;
      
      private var entranceModel:EntranceModel;
      
      public function LoginPacketHandler()
      {
         super();
         this.id = 0;
         this.loginModel = LoginModel(modelRegistry.getModel(LoginModelBase.modelId));
         this.entranceModel = EntranceModel(modelRegistry.getModel(EntranceModelBase.modelId));
      }
      
      public function invoke(param1:AbstractPacket) : void
      {
         switch(param1.getId())
         {
            case LoginSuccessInPacket.id:
               LoginDebugTrace.recordAuthSuccess(param1.getId());
               this.loginSuccess();
               break;
            case LoginFailedInPacket.id:
               LoginDebugTrace.recordAuthFailure("password",param1.getId());
               this.wrongPassword();
         }
      }
      
      public function wrongPassword() : void
      {
         this.loginModel.wrongPassword();
      }
      
      public function loginSuccess() : void
      {
         this.entranceModel.objectUnloaded();
         this.entranceModel.objectUnloadedPost();
      }
   }
}
