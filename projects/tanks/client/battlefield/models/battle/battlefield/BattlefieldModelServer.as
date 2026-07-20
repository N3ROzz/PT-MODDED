package projects.tanks.client.battlefield.models.battle.battlefield
{
   import alternativa.osgi.OSGi;
   import platform.client.fp10.core.model.IModel;
   import projects.tanks.client.battlefield.models.battle.battlefield.fps.FpsStatisticType;
   import scpacker.networking.Network;
   import scpacker.networking.protocol.packets.battle.newname_3685__END;
   import scpacker.networking.protocol.packets.battle.newname_3687__END;

   public class BattlefieldModelServer
   {

      private var model:IModel;
      
      private var network:Network = OSGi.getInstance().getService(Network) as Network;

      public function BattlefieldModelServer(param1:IModel)
      {
         super();
         this.model = param1;
      }

      public function dg(param1:Vector.<int>) : void
      {
         this.network.send(new newname_3687__END(param1));
      }

      public function kd(param1:int) : void
      {
         this.network.send(new newname_3685__END(param1));
      }

      public function sendTimeStatisticsCommand(param1:FpsStatisticType, param2:Number) : void
      {
      }

      public function xc() : void
      {
      }
   }
}
