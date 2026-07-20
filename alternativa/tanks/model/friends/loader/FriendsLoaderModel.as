package alternativa.tanks.model.friends.loader
{
   import alternativa.osgi.service.display.IDisplay;
   import alternativa.tanks.gui.friends.FriendsWindow;
   import alternativa.tanks.gui.friends.FriendsWindowState;
   import forms.events.MainButtonBarEvents;
   import platform.client.fp10.core.model.ObjectLoadPostListener;
   import platform.client.fp10.core.model.ObjectUnloadListener;
   import projects.tanks.client.panel.model.friends.FriendsLoaderModelBase;
   import projects.tanks.client.panel.model.friends.IFriendsLoaderModelBase;
   import projects.tanks.clients.fp10.libraries.tanksservices.model.IFriends;
   import projects.tanks.clients.fp10.libraries.tanksservices.service.friend.IFriendInfoService;
   import services.buttonbar.IButtonBarService;
   
   [ModelInfo]
   public class FriendsLoaderModel extends FriendsLoaderModelBase implements IFriendsLoaderModelBase, ObjectLoadPostListener, ObjectUnloadListener
   {
      
      [Inject] // added
      public static var display:IDisplay;
      
      [Inject] // added
      public static var friendInfoService:IFriendInfoService;
      
      [Inject] // added
      public static var buttonBarService:IButtonBarService;
      
      //[Inject]
      //public static var clanUserInfoService:ClanUserInfoService;
      
      public static var loaded:Boolean = false;

      private static var currentModel:FriendsLoaderModel;

      private static var openWhenLoaded:Boolean = false;
      
      private var friendsWindow:FriendsWindow;
      
      public function FriendsLoaderModel()
      {
         super();
      }
      
      public function objectLoadedPost() : void
      {
         if(!IFriends(object.adapt(IFriends)).isLocal())
         {
            return;
         }
         if(this.friendsWindow == null)
         {
            this.friendsWindow = new FriendsWindow();
         }
         //clanUserInfoService.updateFriendsClanButtonFunction = this.friendsWindow.updateClanButton;
         buttonBarService.addEventListener(MainButtonBarEvents.PANEL_BUTTON_PRESSED,getFunctionWrapper(this.onButtonBarButtonClick));
         currentModel = this;
         loaded = true;
      }

      public static function showLoadedWindow() : Boolean
      {
         if(currentModel != null && currentModel.friendsWindow != null)
         {
            currentModel.showWindow();
            return true;
         }
         return false;
      }

      public static function requestOpenWhenLoaded() : void
      {
         openWhenLoaded = true;
      }
      
      private function onButtonBarButtonClick(param1:MainButtonBarEvents) : void
      {
         if(param1.typeButton == MainButtonBarEvents.FRIENDS)
         {
            this.showWindow();
         }
      }
      
      public function objectUnloaded() : void
      {
         if(!IFriends(object.adapt(IFriends)).isLocal())
         {
            return;
         }
         if(this.friendsWindow != null)
         {
            this.friendsWindow.destroy();
            this.friendsWindow = null;
         }
         buttonBarService.removeEventListener(MainButtonBarEvents.PANEL_BUTTON_PRESSED,getFunctionWrapper(this.onButtonBarButtonClick));
         if(currentModel == this)
         {
            currentModel = null;
         }
         loaded = false;
      }
      
      public function onUsersLoaded() : void
      {
         if(openWhenLoaded)
         {
            openWhenLoaded = false;
            this.showWindow();
         }
      }

      private function showWindow() : void
      {
         if(friendInfoService.newIncomingFriendsLength > 0)
         {
            this.friendsWindow.show(FriendsWindowState.INCOMING);
         }
         else
         {
            this.friendsWindow.show(FriendsWindowState.ACCEPTED);
         }
      }
   }
}
