package forms
{
   import alternativa.osgi.OSGi;
   import alternativa.osgi.service.locale.ILocaleService;
   import base.DiscreteSprite;
   import controls.TankWindow;
   import controls.base.LabelBase;
   import filters.Filters;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.text.TextFormat;
   import resources.windowheaders.background.BackgroundHeader;
   
   public class TankWindowWithHeader extends DiscreteSprite
   {
      
      [Inject] // added
      public static var localeService:ILocaleService;
      
      private static const HEADER_BACKGROUND_HEIGHT:int = 25;
      
      private static const HEADER_BACKGROUND_INNER_HEIGHT:int = 22;
      
      private const GAP_11:int = 11;
      
      private var label:* = new LabelBase();
      
      private var window:TankWindow;
      
      private var headerBackground:Bitmap;

      private var headerBitmap:Bitmap;
      
      public function TankWindowWithHeader(param1:String = null)
      {
         super();
         this.window = new TankWindow();
         addChild(this.window);
         this.initHeaderStyle();
         if(param1 != null)
         {
            this.setHeader(param1);
         }
      }
      
      public static function createWindow(param1:String, param2:int = -1, param3:int = -1) : TankWindowWithHeader
      {
         var _loc4_:TankWindowWithHeader = new TankWindowWithHeader(param1);
         _loc4_.width = param2;
         _loc4_.height = param3;
         return _loc4_;
      }
      
      private function initHeaderStyle() : void
      {
         var _loc1_:String = ILocaleService(OSGi.getInstance().getService(ILocaleService)).language;
         if(_loc1_ == "fa")
         {
            this.label.setTextFormat(new TextFormat("IRANYekan"));
         }
         else if(_loc1_ == "cn")
         {
            this.label.setTextFormat(new TextFormat("simsun"));
         }
         this.label.filters = Filters.SHADOW_FILTERS;
         this.label.size = 16;
         this.label.color = 12632256;
         this.label.bold = true;
      }
      
      private function setHeader(param1:String) : void
      {
         var _loc2_:BitmapData = localeService == null ? null : localeService.getImage(param1);
         this.clearHeader();
         if(_loc2_ != null)
         {
            this.headerBitmap = new Bitmap(_loc2_);
            this.addHeader(this.headerBitmap);
         }
         else
         {
            this.label.htmlText = localeService == null ? param1 : localeService.getText(param1);
            this.addHeader(this.label);
         }
         this.resize();
      }

      private function addHeader(param1:*) : void
      {
         if(param1.width > param1.height)
         {
            if(param1.width + 2 * this.GAP_11 < BackgroundHeader.shortBackgroundHeader.width)
            {
               this.headerBackground = new Bitmap(BackgroundHeader.shortBackgroundHeader);
            }
            else
            {
               this.headerBackground = new Bitmap(BackgroundHeader.longBackgroundHeader);
            }
         }
         else
         {
            this.headerBackground = new Bitmap(BackgroundHeader.verticalBackgroundHeader);
         }
         addChild(this.headerBackground);
         addChild(param1);
      }

      private function clearHeader() : void
      {
         if(this.headerBackground != null && contains(this.headerBackground))
         {
            removeChild(this.headerBackground);
         }
         if(this.headerBitmap != null && contains(this.headerBitmap))
         {
            removeChild(this.headerBitmap);
         }
         if(contains(this.label))
         {
            removeChild(this.label);
         }
         this.headerBackground = null;
         this.headerBitmap = null;
      }
      
      public function setHeaderId(param1:String) : void
      {
         this.setHeader(param1);
      }
      
      override public function set width(param1:Number) : void
      {
         this.window.width = param1;
         this.resize();
      }
      
      override public function get width() : Number
      {
         return this.window.width;
      }
      
      override public function set height(param1:Number) : void
      {
         this.window.height = param1;
         this.resize();
      }
      
      override public function get height() : Number
      {
         return this.window.height;
      }
      
      private function resize() : void
      {
         if(this.headerBackground != null)
         {
            var _loc1_:* = this.headerBitmap == null ? this.label : this.headerBitmap;
            if(_loc1_.width > _loc1_.height)
            {
               this.headerBackground.x = this.window.width - this.headerBackground.width >> 1;
               this.headerBackground.y = -HEADER_BACKGROUND_HEIGHT;
               _loc1_.x = this.window.width - _loc1_.width >> 1;
               _loc1_.y = 5 - (HEADER_BACKGROUND_INNER_HEIGHT + _loc1_.height >> 1);
            }
            else
            {
               this.headerBackground.x = -HEADER_BACKGROUND_HEIGHT;
               this.headerBackground.y = this.window.height - this.headerBackground.height >> 1;
               _loc1_.x = 5 - (HEADER_BACKGROUND_INNER_HEIGHT + _loc1_.width >> 1);
               _loc1_.y = this.window.height - _loc1_.height >> 1;
            }
         }
      }
   }
}
