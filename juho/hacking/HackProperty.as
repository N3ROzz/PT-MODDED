package juho.hacking {
   
   public class HackProperty {
      
      public var name:String;
      public var value:*;
      public var type:String;
      public var callBack:Function;
      public var choicesProvider:Function;
      public var minValue:Number;
      public var maxValue:Number;
      public var step:Number;
      
      public function HackProperty(_name:String, _value:*, _type:String, _callBack:Function, _choicesProvider:Function = null, _minValue:Number = 0, _maxValue:Number = 100, _step:Number = 1) {
         this.name = _name;
         this.value = _value;
         this.type = _type;
         this.callBack = _callBack;
         this.choicesProvider = _choicesProvider;
         this.minValue = _minValue;
         this.maxValue = _maxValue;
         this.step = _step;
      }
   
   }
}
