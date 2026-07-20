package utils.goldbox
{
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;

   public class GoldBoxDiagnosticLogger
   {
      private static const FILE_NAME:String = "protanki-gold-diagnostics.log";

      private var lines:Vector.<String> = new Vector.<String>();

      public function append(param1:String) : void
      {
         this.lines.push(param1);
      }

      public function get hasPendingLines() : Boolean
      {
         return this.lines.length > 0;
      }

      public function flush() : void
      {
         var _loc1_:FileStream = null;
         if(this.lines.length == 0)
         {
            return;
         }
         _loc1_ = new FileStream();
         try
         {
            _loc1_.open(File.desktopDirectory.resolvePath(FILE_NAME),FileMode.APPEND);
            _loc1_.writeUTFBytes(this.lines.join("\r\n") + "\r\n");
            this.lines.length = 0;
         }
         catch(error:Error)
         {
         }
         finally
         {
            try
            {
               _loc1_.close();
            }
            catch(closeError:Error)
            {
            }
         }
      }

      public function clear() : void
      {
         this.lines.length = 0;
      }
   }
}
