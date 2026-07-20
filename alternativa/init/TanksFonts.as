package alternativa.init
{
   import alternativa.osgi.bundle.IBundleActivator;
   import flash.text.Font;
   import flash.text.TextFormat;
   import fonts.TanksFontService;
   import alternativa.osgi.OSGi;
   
   public class TanksFonts implements IBundleActivator
   {
      
      private static const MyriadPro:Class = TanksFonts_MyriadPro;
      
      private static const MyriadProB:Class = TanksFonts_MyriadProB;
      
      public function TanksFonts()
      {
         super();
      }
      
      public static function init() : void
      {
         Font.registerFont(MyriadPro);
         Font.registerFont(MyriadProB);
         TanksFontService.setTextFormat(new TextFormat("MyriadPro",12,16777215),true);
      }
      
      public function start(osgi:OSGi) : void
      {
         Font.registerFont(MyriadPro);
         Font.registerFont(MyriadProB);
         TanksFontService.setTextFormat(new TextFormat("MyriadPro",12,16777215),true);
      }
      
      public function stop(osgi:OSGi) : void
      {
      }
   }
}
