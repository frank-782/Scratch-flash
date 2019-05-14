package raven
{
   import com.adobe.crypto.MD5;
   import com.adobe.serialization.json.JSONEncoder;
   import com.adobe.utils.StringUtil;
   import flash.system.Capabilities;
   import flash.utils.ByteArray;
   
   public class RavenClient
   {
      
      public static const DEBUG:uint = 10;
      
      public static const INFO:uint = 20;
      
      public static const WARN:uint = 30;
      
      public static const ERROR:uint = 40;
      
      public static const FATAL:uint = 50;
      
      public static const VERSION:String = "0.1";
      
      public static const NAME:String = "raven-as3/" + VERSION;
       
      
      private var _config:RavenConfig;
      
      private var _sender:RavenMessageSender;
      
      private var _lastID:String;
      
      private var _tags:Object;
      
      private var _extras:Object;
      
      public function RavenClient(param1:String)
      {
         super();
         if(param1 == null || param1.length == 0)
         {
            throw new ArgumentError("You must provide a DSN to RavenClient");
         }
         this._config = new RavenConfig(param1);
         this._sender = new RavenMessageSender(this._config);
      }
      
      public function setTags(param1:Object = null) : void
      {
         this._tags = param1;
      }
      
      public function setExtras(param1:Object = null) : void
      {
         this._extras = param1;
      }
      
      public function captureMessage(param1:String, param2:String = "root", param3:int = 40, param4:String = null) : String
      {
         var _loc5_:Date = new Date();
         var _loc6_:String = this.buildMessage(param1,RavenUtils.formatTimestamp(_loc5_),param2,param3,param4,null);
         this._tags = {};
         this._sender.send(_loc6_,_loc5_.time,MD5.hash(param1));
         return this._lastID;
      }
      
      public function captureException(param1:Error, param2:String = null, param3:String = "root", param4:int = 40, param5:String = null) : String
      {
         var _loc7_:Date = null;
         var _loc8_:String = null;
         this._tags = {};
         var _loc6_:String = param1.getStackTrace();
         if(_loc6_ && StringUtil.trim(_loc6_).length > 0)
         {
            _loc7_ = new Date();
            _loc8_ = this.buildMessage(param2 || param1.message,RavenUtils.formatTimestamp(_loc7_),param3,param4,param5,param1);
            this._sender.send(_loc8_,_loc7_.time,MD5.hash(param1.message + _loc6_));
         }
         return this._lastID;
      }
      
      private function buildMessage(param1:String, param2:String, param3:String, param4:int, param5:String, param6:Error) : String
      {
         var _loc7_:String = this.buildJSON(param1,param2,param3,param4,param5,param6);
         var _loc8_:ByteArray = new ByteArray();
         _loc8_.writeMultiByte(_loc7_,"iso-8859-1");
         return RavenBase64.encode(_loc8_);
      }
      
      private function buildJSON(param1:String, param2:String, param3:String, param4:int, param5:String, param6:Error) : String
      {
         var _loc9_:* = null;
         this._lastID = RavenUtils.uuid4();
         var _loc7_:Object = new Object();
         _loc7_["message"] = param1;
         _loc7_["event_id"] = this._lastID;
         if(param6 == null)
         {
            _loc7_["culprit"] = param5;
         }
         else
         {
            _loc7_["culprit"] = this.determineCulprit(param6);
            _loc7_["sentry.interfaces.Exception"] = this.buildException(param6);
            _loc7_["sentry.interfaces.Stacktrace"] = this.buildStacktrace(param6);
         }
         _loc7_["timestamp"] = param2;
         _loc7_["project"] = this._config.projectID;
         _loc7_["level"] = param4;
         _loc7_["logger"] = param3;
         _loc7_["tags"] = this._tags;
         _loc7_["extra"] = {
            "loaderURL":Scratch.app.loaderInfo.loaderURL,
            "project":ScratchOnline.app.getProjectURL(),
            "allow_3D":true,
            "using_3D":Scratch.app.isIn3D,
            "swf_version":Scratch.versionString,
            "flash_version":Capabilities.version,
            "cpu":Capabilities.cpuArchitecture
         };
         if(Scratch.app.logger)
         {
            _loc7_["extra"]["eventLog"] = Scratch.app.logger.report();
         }
         if(this._extras)
         {
            for(_loc9_ in this._extras)
            {
               _loc7_["extra"]["ud_" + _loc9_] = this._extras[_loc9_];
            }
         }
         var _loc8_:JSONEncoder = new JSONEncoder(_loc7_);
         return _loc8_.getString();
      }
      
      private function buildException(param1:Error) : Object
      {
         var _loc2_:Object = new Object();
         _loc2_["type"] = RavenUtils.getClassName(param1);
         _loc2_["value"] = param1.message;
         _loc2_["module"] = RavenUtils.getModuleName(param1);
         return _loc2_;
      }
      
      private function buildStacktrace(param1:Error) : Object
      {
         var _loc2_:Object = new Object();
         _loc2_["frames"] = RavenUtils.parseStackTrace(param1);
         return _loc2_;
      }
      
      private function determineCulprit(param1:Error) : String
      {
         return param1.getStackTrace().split("\n")[0];
      }
   }
}
