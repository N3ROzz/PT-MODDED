package juho.hacking.hackmenu
{
   import alternativa.osgi.OSGi;
   import flash.display.Stage;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.net.SharedObject;
   import flash.text.TextField;
   import flash.ui.Keyboard;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.dialogs.IDialogsService;
   
   public class HackMenuHotkeyManager
   {
      
      private static const STORAGE_NAME:String = "qa_tools_hotkey";
      private static const STORAGE_FIELD:String = "keyCode";
      private static const DEFAULT_KEY_CODE:int = Keyboard.INSERT;
      
      private static var stage:Stage;
      private static var currentKeyCode:int = DEFAULT_KEY_CODE;
      private static var window:HackMenuWindow;
      private static var loaded:Boolean = false;
      
      private static const OPTIONS:Array = [
         {label:"F1",keyCode:Keyboard.F1},
         {label:"F2",keyCode:Keyboard.F2},
         {label:"F3",keyCode:Keyboard.F3},
         {label:"F4",keyCode:Keyboard.F4},
         {label:"F5",keyCode:Keyboard.F5},
         {label:"F6",keyCode:Keyboard.F6},
         {label:"F7",keyCode:Keyboard.F7},
         {label:"F8",keyCode:Keyboard.F8},
         {label:"F9",keyCode:Keyboard.F9},
         {label:"F10",keyCode:Keyboard.F10},
         {label:"F11",keyCode:Keyboard.F11},
         {label:"F12",keyCode:Keyboard.F12},
         {label:"INS",keyCode:Keyboard.INSERT},
         {label:"HOME",keyCode:Keyboard.HOME},
         {label:"PGUP",keyCode:Keyboard.PAGE_UP},
         {label:"PGDN",keyCode:Keyboard.PAGE_DOWN},
         {label:"END",keyCode:Keyboard.END},
         {label:"DEL",keyCode:Keyboard.DELETE}
      ];
      
      public function HackMenuHotkeyManager()
      {
         super();
      }
      
      public static function init(param1:Stage) : void
      {
         loadHotkey();
         if(stage != null)
         {
            stage.removeEventListener(KeyboardEvent.KEY_UP,onKeyUp);
         }
         stage = param1;
         if(stage != null)
         {
            stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUp,false,10000,true);
         }
      }
      
      public static function getHotkeyOptions() : Array
      {
         return OPTIONS.concat();
      }
      
      public static function getHotkeyCode() : int
      {
         loadHotkey();
         return currentKeyCode;
      }
      
      public static function getHotkeyLabel() : String
      {
         return getLabelForKeyCode(getHotkeyCode());
      }
      
      public static function setHotkeyCode(param1:int) : void
      {
         if(!isAllowedKeyCode(param1))
         {
            return;
         }
         currentKeyCode = param1;
         saveHotkey();
      }
      
      public static function toggleMenu() : void
      {
         if(window == null)
         {
            openMenu();
         }
         else
         {
            closeMenu();
         }
      }
      
      public static function closeMenu() : void
      {
         var _loc1_:IDialogsService = null;
         if(window == null)
         {
            return;
         }
         window._closeButton.removeEventListener(MouseEvent.CLICK,onCloseButtonClick);
         window.removeEventListener(Event.REMOVED_FROM_STAGE,onWindowRemoved);
         _loc1_ = OSGi.getInstance().getService(IDialogsService) as IDialogsService;
         if(_loc1_ != null)
         {
            _loc1_.removeDialog(window);
         }
         window = null;
      }
      
      private static function openMenu() : void
      {
         var _loc1_:IDialogsService = OSGi.getInstance().getService(IDialogsService) as IDialogsService;
         if(_loc1_ == null)
         {
            return;
         }
         window = new HackMenuWindow();
         window._closeButton.addEventListener(MouseEvent.CLICK,onCloseButtonClick);
         window.addEventListener(Event.REMOVED_FROM_STAGE,onWindowRemoved);
         _loc1_.addDialog(window);
      }
      
      private static function onKeyUp(param1:KeyboardEvent) : void
      {
         if(param1.keyCode != currentKeyCode || param1.target is TextField)
         {
            return;
         }
         param1.preventDefault();
         param1.stopImmediatePropagation();
         toggleMenu();
      }
      
      private static function onCloseButtonClick(param1:MouseEvent) : void
      {
         closeMenu();
      }
      
      private static function onWindowRemoved(param1:Event) : void
      {
         if(param1.currentTarget == window)
         {
            window._closeButton.removeEventListener(MouseEvent.CLICK,onCloseButtonClick);
            window.removeEventListener(Event.REMOVED_FROM_STAGE,onWindowRemoved);
            window = null;
         }
      }
      
      private static function loadHotkey() : void
      {
         var _loc1_:SharedObject = null;
         var _loc2_:int = 0;
         if(loaded)
         {
            return;
         }
         loaded = true;
         try
         {
            _loc1_ = SharedObject.getLocal(STORAGE_NAME);
            _loc2_ = int(_loc1_.data[STORAGE_FIELD]);
            if(isAllowedKeyCode(_loc2_))
            {
               currentKeyCode = _loc2_;
            }
         }
         catch(error:Error)
         {
            currentKeyCode = DEFAULT_KEY_CODE;
         }
      }
      
      private static function saveHotkey() : void
      {
         var _loc1_:SharedObject = null;
         try
         {
            _loc1_ = SharedObject.getLocal(STORAGE_NAME);
            _loc1_.data[STORAGE_FIELD] = currentKeyCode;
            _loc1_.flush();
         }
         catch(error:Error)
         {
         }
      }
      
      private static function getLabelForKeyCode(param1:int) : String
      {
         var _loc2_:Object = null;
         for each(_loc2_ in OPTIONS)
         {
            if(_loc2_.keyCode == param1)
            {
               return _loc2_.label;
            }
         }
         return "INS";
      }
      
      private static function isAllowedKeyCode(param1:int) : Boolean
      {
         var _loc2_:Object = null;
         for each(_loc2_ in OPTIONS)
         {
            if(_loc2_.keyCode == param1)
            {
               return true;
            }
         }
         return false;
      }

   }
}
