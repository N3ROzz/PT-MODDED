package juho.hacking {
   
   import juho.hacking.hacks.SpeedHack;
   import juho.hacking.Hack;
   import juho.hacking.hacks.BasicAIHack;
   import juho.hacking.hacks.TankIgnoreHack;
   import juho.hacking.hacks.AimHack;
   import juho.hacking.hacks.ShaftFovHack;
   import juho.hacking.hacks.WallHack;
   import juho.hacking.hacks.GoldBoxDiagnosticsHack;
   import utils.TankTraceUtil;
   
   public class HackRegistry {
      
      public static var allHacks:Vector.<Hack>;
      
      public function HackRegistry() {
         trace("HackRegistry constructor starting");
         TankTraceUtil.log("[TankTraceUtil] startup logger check");
         allHacks = new Vector.<Hack>();
         
         var tankIgnoreHack:TankIgnoreHack = new TankIgnoreHack()
         allHacks.push(tankIgnoreHack);
         trace("Added TankIgnoreHack, count: " + allHacks.length);
         
         var aimHack:AimHack = new AimHack()
         allHacks.push(aimHack);
         trace("Added AimHack, count: " + allHacks.length);
         
         trace("About to create WallHack...");
         var wallHack:WallHack = new WallHack()
         trace("WallHack created, adding to vector...");
         allHacks.push(wallHack);
         trace("Added WallHack, count: " + allHacks.length);

         var speedHack:SpeedHack = new SpeedHack()
         allHacks.push(speedHack);
         trace("Added SpeedHack, count: " + allHacks.length);
         
         var shaftFovHack:ShaftFovHack = new ShaftFovHack()
         allHacks.push(shaftFovHack);
         trace("Added ShaftFovHack, count: " + allHacks.length);
         
         var basicAIHack:BasicAIHack = new BasicAIHack()
         allHacks.push(basicAIHack);
         trace("Added BasicAIHack, count: " + allHacks.length);

         var goldBoxDiagnosticsHack:GoldBoxDiagnosticsHack = new GoldBoxDiagnosticsHack();
         allHacks.push(goldBoxDiagnosticsHack);
         trace("Added GoldBoxDiagnosticsHack, count: " + allHacks.length);

         trace("HackRegistry constructor complete, total hacks: " + allHacks.length);
      }
   }
}
