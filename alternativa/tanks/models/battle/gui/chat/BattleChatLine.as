package alternativa.tanks.models.battle.gui.chat
{
   import alternativa.osgi.service.locale.ILocaleService;
   import alternativa.tanks.models.battle.battlefield.common.MessageLine;
   import alternativa.tanks.models.battle.ctf.MessageColor;
   import alternativa.tanks.models.battle.gui.userlabel.BattleChatUserLabel;
   import alternativa.types.Long;
   import controls.Label;
   import flash.text.AntiAliasType;
   import projects.tanks.client.battleservice.model.battle.team.BattleTeam;
   import projects.tanks.clients.fp10.libraries.TanksLocale;
   import utils.FontParamsUtil;
   
   public class BattleChatLine extends MessageLine
   {
      
      [Inject] // added
      public static var localeService:ILocaleService;
      
      private var output:Label;
      
      private var _namesWidth:int = 0;
      
      private var _width:int = 300;
      
      private var chatUserLabel:BattleChatUserLabel;

      private static const TEXT_GAP:int = 5;

      private static const LINE_HEIGHT:int = 18;
      
      public function BattleChatLine(param1:String, param2:BattleTeam, param3:String, param4:Boolean, param5:Boolean)
      {
         var _loc7_:Label = null;
         this.output = new Label();
         super();
         var _loc6_:int = 0;
         if(param5)
         {
            _loc6_ = 14;
            _loc7_ = new Label();
            _loc7_.color = MessageColor.YELLOW;
            _loc7_.text = localeService.getText(TanksLocale.TEXT_SPECTATOR_NAME) + ":";
            _loc7_.thickness = 50;
            _loc7_.sharpness = 0;
            _loc7_.mouseEnabled = false;
            shadowContainer.addChild(_loc7_);
            _loc7_.x = _loc6_;
            _loc6_ += _loc7_.textWidth + 1;
         }
         else
         {
            this.chatUserLabel = new BattleChatUserLabel(param1);
            this.chatUserLabel.setUidColor(MessageColor.getUserNameColor(param2,param5),true);
            this.chatUserLabel.setAdditionalText(":");
            addChild(this.chatUserLabel);
            _loc6_ += this.chatUserLabel.width;
         }
         this.output.color = MessageColor.getTextColor(param2,param4,param5);
         this.output.antiAliasType = AntiAliasType.ADVANCED;
         this.output.thickness = FontParamsUtil.THICKNESS_LABEL_BASE;
         this.output.sharpness = FontParamsUtil.SHARPNESS_LABEL_BASE;
         this.output.multiline = true;
         this.output.wordWrap = true;
         this.output.mouseEnabled = false;
         shadowContainer.addChild(this.output);
         this._namesWidth = _loc6_;
         this.output.text = this.trimTrailingLineBreaks(param3);
         this.updateTextLayout();
      }
      
      [Obfuscation(rename="false")]
      public function alignChatUserLabel() : void
      {
         if(this.chatUserLabel == null)
         {
            return;
         }
         this._namesWidth = this.chatUserLabel.width;
         this.updateTextLayout();
      }
      
      [Obfuscation(rename="false")]
      override public function set width(param1:Number) : void
      {
         this._width = int(param1);
         this.updateTextLayout();
      }

      private function updateTextLayout() : void
      {
         if(this._namesWidth > this._width / 2 && this.output.text.length * 8 > this._width - this._namesWidth)
         {
            this.output.y = LINE_HEIGHT;
            this.output.x = 0;
            this.output.width = this._width - 5;
         }
         else
         {
            this.output.x = this._namesWidth + TEXT_GAP;
            this.output.y = 0;
            this.output.width = this._width - this.output.x - 5;
         }
         this.output.height = Math.max(LINE_HEIGHT,this.output.textHeight + 4);
      }

      private function trimTrailingLineBreaks(param1:String) : String
      {
         if(param1 == null)
         {
            return "";
         }
         while(param1.length > 0 && (param1.charAt(param1.length - 1) == "\n" || param1.charAt(param1.length - 1) == "\r"))
         {
            param1 = param1.substr(0,param1.length - 1);
         }
         return param1;
      }
   }
}
