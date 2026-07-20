package scpacker.networking.protocol.codec.custom
{
   import flash.utils.ByteArray;
   import projects.tanks.client.tanksservices.model.notifier.clan.UserClanInfoCC;
   import scpacker.networking.protocol.ProtocolInitializer;
   import scpacker.networking.protocol.codec.ICodec;
   
   public class CodecUserClanInfoCC implements ICodec
   {
      
      public const optionalVector:Boolean = false;
      
      public const element:Class = UserClanInfoCC;
      
      private var booleanCodec:ICodec;
      
      private var stringCodec:ICodec;
      
      public function CodecUserClanInfoCC(param1:ProtocolInitializer)
      {
         super();
         this.booleanCodec = param1.getCodec("scpacker.networking.protocol.codec.primitive.BooleanCodec");
         this.stringCodec = param1.getCodec("scpacker.networking.protocol.codec.primitive.StringCodec");
      }
      
      public function decode(param1:ByteArray) : Object
      {
         var _loc2_:UserClanInfoCC = new UserClanInfoCC();
         _loc2_.isInClan = this.booleanCodec.decode(param1) as Boolean;
         _loc2_.clanTag = this.stringCodec.decode(param1) as String;
         _loc2_.userId = this.stringCodec.decode(param1) as String;
         return _loc2_;
      }
      
      public function encode(param1:ByteArray, param2:Object) : int
      {
         if(param2 == null)
         {
            throw new Error("Object is null. Use @ProtocolOptional annotation.");
         }
         var _loc3_:UserClanInfoCC = UserClanInfoCC(param2);
         this.booleanCodec.encode(param1,_loc3_.isInClan);
         this.stringCodec.encode(param1,_loc3_.clanTag);
         this.stringCodec.encode(param1,_loc3_.userId);
         return 1;
      }
   }
}
