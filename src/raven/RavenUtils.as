package raven
{
   import com.adobe.crypto.HMAC;
   import com.adobe.crypto.SHA1;
   import com.adobe.utils.StringUtil;
   import flash.utils.getQualifiedClassName;
   
   public class RavenUtils
   {
       
      
      public function RavenUtils()
      {
         super();
      }
      
      public static function uuid4() : String
      {
         var _loc1_:String = "";
         _loc1_ = _loc1_ + randInt(0,65535).toString(16).substr(0,4);
         _loc1_ = _loc1_ + randInt(0,65535).toString(16).substr(0,4);
         _loc1_ = _loc1_ + randInt(0,65535).toString(16).substr(0,4);
         _loc1_ = _loc1_ + (randInt(0,4095) | 16384).toString(16).substr(0,4);
         _loc1_ = _loc1_ + (randInt(0,16383) | 32768).toString(16).substr(0,4);
         _loc1_ = _loc1_ + randInt(0,65535).toString(16).substr(0,4);
         _loc1_ = _loc1_ + randInt(0,65535).toString(16).substr(0,4);
         _loc1_ = _loc1_ + randInt(0,65535).toString(16).substr(0,4);
         return _loc1_;
      }
      
      public static function getHostname() : String
      {
         return "test";
      }
      
      public static function getSignature(param1:String, param2:Number, param3:String) : String
      {
         return HMAC.hash(param3,param2 + " " + param1,SHA1);
      }
      
      public static function randInt(param1:int, param2:int) : int
      {
         return Math.round(param1 + Math.random() * (param2 - param1));
      }
      
      public static function parseStackTrace(param1:Error) : Array
      {
         var _loc5_:String = null;
         var _loc6_:Object = null;
         var _loc7_:Object = null;
         var _loc8_:Array = null;
         var _loc9_:String = null;
         var _loc10_:int = 0;
         var _loc2_:Array = new Array();
         var _loc3_:Array = param1.getStackTrace().split("\n");
         _loc3_.shift();
         var _loc4_:String = RavenUtils.getClassName(param1);
         if(_loc4_)
         {
            _loc6_ = new Object();
            _loc6_["filename"] = "Caused by " + _loc4_ + "(" + param1.message + ")";
            _loc6_["lineno"] = -1;
            _loc2_.push(_loc6_);
         }
         for each(_loc5_ in _loc3_)
         {
            _loc7_ = new Object();
            _loc8_ = _loc5_.split("[");
            _loc7_["function"] = StringUtil.trim(_loc8_[0]).substr(3);
            if(_loc8_.length > 1)
            {
               _loc9_ = String(_loc8_[1]);
               _loc10_ = _loc9_.lastIndexOf(":");
               _loc7_["filename"] = _loc9_.substr(0,_loc10_);
               _loc7_["lineno"] = parseInt(_loc9_.substr(_loc10_ + 1));
            }
            else
            {
               _loc7_["filename"] = "(Unknown file)";
               _loc7_["lineno"] = -1;
            }
            _loc2_.push(_loc7_);
         }
         return _loc2_;
      }
      
      public static function getClassName(param1:Object) : String
      {
         var _loc2_:String = getQualifiedClassName(param1);
         var _loc3_:Array = _loc2_.split("::");
         return _loc3_[1];
      }
      
      public static function getModuleName(param1:Object) : String
      {
         var _loc2_:String = getQualifiedClassName(param1);
         var _loc3_:Array = _loc2_.split("::");
         return _loc3_[0];
      }
      
      public static function formatTimestamp(param1:Date) : String
      {
         var _loc2_:String = "";
         var _loc3_:int = param1.monthUTC + 1;
         _loc2_ = _loc2_ + (param1.fullYearUTC + "-");
         _loc2_ = _loc2_ + (_loc3_ < 10?"0" + _loc3_ + "-":_loc3_ + "-");
         _loc2_ = _loc2_ + (param1.dateUTC + "T");
         _loc2_ = _loc2_ + (param1.hoursUTC + ":");
         _loc2_ = _loc2_ + (param1.minutesUTC + ":");
         _loc2_ = _loc2_ + param1.secondsUTC;
         return _loc2_;
      }
   }
}
